import 'dart:async';
import 'package:flutter/material.dart';

class CountdownModeScreen extends StatefulWidget {
  const CountdownModeScreen({super.key});

  @override
  State<CountdownModeScreen> createState() => CountdownScreenState();
}

class CountdownScreenState extends State<CountdownModeScreen> {
  Timer? _timer;
  bool _isRunning = false;
  bool _completed = false;
  double _sliderValue = 1;

  static const Duration defaultDuration = Duration(
    minutes: 1,
    seconds: 0,
  );

  Duration _initDuration = defaultDuration;

  final ValueNotifier<Duration> _durationNotifier = ValueNotifier<Duration>(
    defaultDuration,
  );

  //countdown logic
  @override
  void dispose() {
    _timer?.cancel();
    _durationNotifier.dispose();
    super.dispose();
  }

  void startCountdown() {
    if (_isRunning) return;

    if (_durationNotifier.value == _sliderValue.toInt()) {
      _initDuration = Duration(minutes: _sliderValue.toInt());
      _durationNotifier.value = _initDuration;
    }
    else {
      _initDuration = _durationNotifier.value;
      _initDuration = Duration(minutes: _sliderValue.toInt());
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_durationNotifier.value.inSeconds <= 0) {
        _timer?.cancel();
        countdownComplete();
      }
      else {
        _durationNotifier.value -= const Duration(seconds: 1);
      }
    });

    setState(() {
      _isRunning = true;
    });
  }

  void pauseCountdown() {
    _timer?.cancel();

    setState(() {
      _isRunning = false;
    });
  }

  void resetCountdown() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
    _sliderValue = 1;
    _initDuration = Duration(minutes: _sliderValue.toInt());
    _durationNotifier.value = _initDuration;

  }

  void stopCountdown() {
    {
      pauseCountdown();
      showDialog(
        context: context,
        builder: (context) => Visibility(
          visible: _isRunning ? false : true,
          child: AlertDialog(
            title: const Text("Are you sure you want to lose progress?"),
            content: Row(
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    resetCountdown();
                  },
                  child: Text("Yes"),
                ),
                TextButton(
                  onPressed: () {
                    startCountdown();
                    Navigator.of(context).pop();
                  },
                  child: Text("No"),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  void trackTime(){}

  void countdownComplete() {
    {
      pauseCountdown();
      showDialog(
        context: context,
        builder: (context) => Visibility(
          visible: _isRunning ? false : true,
          child: AlertDialog(
            title: const Text("Are you sure you want to lose progress?"),
            content: Row(
              children: [
                TextButton(onPressed: () {Navigator.of(context).pop(); trackTime();}, child: Text("Track"),), //tracked close
                TextButton(onPressed: Navigator.of(context).pop, child: Text("Close"),) //untracked close
                ],
            ),
          ),
        ),
      );
    }
  }

  String formatCountdown(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours.remainder(60));
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    return "$hours:$minutes:$seconds";
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
                final progress = _initDuration.inSeconds == 0
                    ? 0.0
                    : duration.inSeconds / _initDuration.inSeconds;
                return SizedBox(
                  width: 250,
                  height: 250,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(250, 250),
                        painter: CountdownPainter(
                          progress: progress.clamp(0.0, 1.0),
                        ),
                      ),
                      Text(
                        formatCountdown(duration),
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Visibility(
                  visible: !_isRunning,
                  child: Slider(
                    value: _sliderValue,
                    min: 1,
                    max: 3,
                    divisions: 2,
                    label: _sliderValue.toString(),
                    onChanged: (double value) {
                      setState(() {
                        _sliderValue = value;
                        _durationNotifier.value = Duration(
                          minutes: _sliderValue.toInt(),
                        );
                      });
                    },
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isRunning ? stopCountdown : startCountdown,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                  label: Text(_isRunning ? "Cancel" : "Start"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

//for countdown animation from https://apparencekit.dev/flutter-tips/draw-flutter-timer/ (kinda syza)
class CountdownPainter extends CustomPainter {
  final double progress; // 0.0 → 1.0

  CountdownPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 10.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - strokeWidth;

    final backgroundPaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final progressPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Background circle
    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc
    final sweepAngle = 2 * 3.141592653589793 * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.141592653589793 / 2, // start at top
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CountdownPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
