import 'dart:async';
import 'package:flutter/material.dart';

class StopwatchModeScreen extends StatefulWidget {
  const StopwatchModeScreen({super.key});

  @override
  StopwatchModeScreenState createState() => StopwatchModeScreenState();
}

class StopwatchModeScreenState extends State<StopwatchModeScreen> {
  static const Duration defaultDuration = Duration(minutes: 0, seconds: 0);

  final ValueNotifier<Duration> _durationNotifier = ValueNotifier<Duration>(
    defaultDuration,
  );

  Timer? _timer;
  bool _isRunning = false;

  @override
  void dispose() {
    _timer?.cancel();
    _durationNotifier.dispose();
    super.dispose();
  }

  void startStopwatch() {
    if (_isRunning) return;
    _timer = Timer.periodic(const Duration(milliseconds: 1), (timer) {
      _durationNotifier.value =
          _durationNotifier.value + const Duration(milliseconds: 1);
    });

    setState(() {
      _isRunning = true;
    });
  }

  void pauseStopwatch() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  void resetStopwatch() {
    _timer?.cancel();
    _durationNotifier.value = defaultDuration;
    setState(() {
      _isRunning = false;
    });
  }

  void stopwatchComplete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Focus time logged."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              resetStopwatch();
            },
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  String formatCountdown(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours.remainder(60));
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    final milliseconds = twoDigits(
      duration.inMilliseconds.remainder(1000) ~/ 10,
    );
    return "${duration.inHours.remainder(60)>=1 ? "$hours:" : ""}$minutes:$seconds.$milliseconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ValueListenableBuilder<Duration>(
              valueListenable: _durationNotifier,
              builder: (context, duration, child) {
                return Container(
                  width: 300,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: null,
                    border: Border.all(color: Colors.white, width: 10),
                  ),
                  child: Center(
                    child: Text(
                      formatCountdown(duration),
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _isRunning ? pauseStopwatch : startStopwatch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                  label: Text(_isRunning ? "Pause" : "Start"),
                ),
                const SizedBox(width: 10),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}