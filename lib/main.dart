import 'package:flutter/material.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Fitzy's Timer",
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  //static const int minToMs = 60000;
  final int _audioLengthMS = (5 * 60) * 1000;
  int initialTime = 5 * 60 * 1000; // 5 minutes in ms
  int _remainingTime = 0; // ms remaining
  DateTime? _endTime;
  Timer? _timer;
  final int _updateInterval = 100; //ms
  bool _isRunning = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final int _lag = 1000; // audio lag in ms

  @override
  void initState() {
    super.initState();
    _remainingTime = initialTime;
    _audioPlayer.setSourceAsset('sounds/_5mincountdown.m4a');
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  bool _paused = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // The app is in the background or the screen is locked
      if (_isRunning) {
        _timer?.cancel();
      }
      if (_paused == false) {
        _endTime = DateTime.now().add(Duration(milliseconds: _remainingTime));
        _paused = true;
      }
    } else if (state == AppLifecycleState.resumed) {
      // The app is in the foreground
      if (_endTime != null) {
        _remainingTime = _endTime!.difference(DateTime.now()).inMilliseconds;
      }
      if (_isRunning) {
        _startTimer();
      }
      _paused = false;
    }
  }

  void _toggleTimer() {
    if (_isRunning) {
      _stopTimer();
    } else {
      _startTimer();
    }
  }

  void _startTimer() async {
    _endTime = DateTime.now().add(Duration(milliseconds: _remainingTime));
    _timer?.cancel();
    _timer = Timer.periodic(Duration(milliseconds: _updateInterval), (timer) {
      setState(() {
        _remainingTime = _endTime!.difference(DateTime.now()).inMilliseconds;
      });
      if (_remainingTime <= 0) {
        _stopTimer();
        setState(() {
          _remainingTime = 0;
        });
      }
    });
    setState(() {
      _isRunning = true;
    });
    _remainingTime = _endTime!.difference(DateTime.now()).inMilliseconds;
    await setAudioPos(_remainingTime);
    await _audioPlayer.play(AssetSource('sounds/_5mincountdown.m4a'));
  }

  void _stopTimer() async {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _endTime = null;
    });
    if (_remainingTime > 0) {
      await _audioPlayer.pause();
    }
  }

  void _resetTimer() async {
    _stopTimer();
    setState(() {
      _remainingTime = initialTime;
      _endTime = null;
    });
    await setAudioPos(_remainingTime);
    await _audioPlayer.pause();
  }

  void _syncTimer() async {
    DateTime now = DateTime.now();
    _endTime ??= now.add(Duration(milliseconds: _remainingTime));
    setState(() {
      _remainingTime = _endTime!.difference(now).inMilliseconds;
      _remainingTime = ((_remainingTime - _updateInterval) ~/ 60000) * 60000;
      _endTime = now.add(Duration(milliseconds: _remainingTime));
    });
    await setAudioPos(_remainingTime);
  }

  void _plusOneMinute() async {
    setState(() {
      _remainingTime = _remainingTime + 60000;
      DateTime now = DateTime.now();
      _endTime = now.add(Duration(milliseconds: _remainingTime));
    });
    await setAudioPos(_remainingTime);
  }

  Future<void> setAudioPos(int timeRemaining) async {
    int seekPos = _audioLengthMS - timeRemaining + _lag;
    seekPos = seekPos <= 0 ? 0 : seekPos;
    await _audioPlayer.seek(Duration(milliseconds: seekPos));
  }

  String get _formattedTime {
    DateTime now = DateTime.now();
    if (_endTime != null) {
      _remainingTime = _endTime!.difference(now).inMilliseconds;
    }
    int minutes = (_remainingTime) ~/ 60000;
    int seconds = ((_remainingTime) % 60000) ~/ 1000;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Fitzy's Timer"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              _formattedTime,
              style: const TextStyle(fontSize: 124),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton(
                    key: const Key('toggle_button'),
                    onPressed: _toggleTimer,
                    child: Text(_isRunning ? 'Stop' : 'Start'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton(
                    key: const Key('reset_button'),
                    onPressed: _isRunning ? null : _resetTimer,
                    child: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    key: const Key('sync_button'),
                    onPressed: _syncTimer,
                    child: const Text('Sync'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    key: const Key('sync_up_button'),
                    onPressed: _plusOneMinute,
                    child: const Text('+1 Min'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
