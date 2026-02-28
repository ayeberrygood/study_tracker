import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_tracker/timer_menu.dart';

class CountdownModeScreen extends StatefulWidget {
  const CountdownModeScreen({super.key});

  @override
  State<CountdownModeScreen> createState() => CountdownScreenState();
}

class CountdownScreenState extends State<CountdownModeScreen> {
  List<TrackerItem> _trackers = [];
  TrackerItem? _selectedTracker;
  bool _isLoading = true;
  late final SharedPreferencesAsync _prefs = SharedPreferencesAsync();
  Timer? _timer;
  bool _isRunning = false;
  double _sliderValue = 1;

  static const Duration defaultDuration = Duration(minutes: 1, seconds: 0);

  Duration _initDuration = defaultDuration;

  final ValueNotifier<Duration> _durationNotifier = ValueNotifier<Duration>(
    defaultDuration,
  );

  @override
  void initState() {
    super.initState();

    _prefs.getString('tracker_list').then((value) {
      setState(() {
        if (value != null) {
          final List decoded = jsonDecode(value);
          _trackers = decoded.map((e) => TrackerItem.fromJson(e)).toList();
        }
        _isLoading = false;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _durationNotifier.dispose();
    super.dispose();
  }

  void startCountdown() {
    if (_isRunning) return;
    _initDuration = Duration(minutes: _sliderValue.toInt());
    _durationNotifier.value = _initDuration;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_durationNotifier.value.inSeconds <= 0) {
        _timer?.cancel();
        countdownComplete();
      } else {
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
      _sliderValue = 1;
      _initDuration = Duration(minutes: _sliderValue.toInt());
      _durationNotifier.value = _initDuration;
    });
  }

  void stopCountdown() {
    pauseCountdown();
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text("Are you sure you want to lose progress?"),
            content: Row(
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    resetCountdown();
                  },
                  child: const Text("Yes"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    startCountdown();
                  },
                  child: const Text("No"),
                ),
              ],
            ),
          ),
    );
  }

  String formatCountdown(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours.remainder(60));
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  void trackTime() async {
    if (_isLoading) return;
    if (_selectedTracker == null) return;

    final index = _trackers.indexOf(_selectedTracker!);
    if (index == -1) return;

    setState(() {
      _trackers[index] = TrackerItem(
        name: _trackers[index].name,
        duration: _trackers[index].duration - _initDuration.inMinutes,
      );
      _selectedTracker = null;
    });

    final String encoded = jsonEncode(_trackers.map((t) => t.toJson()).toList());
    await _prefs.setString('tracker_list', encoded);
  }

  void countdownComplete() {
    pauseCountdown();
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text("Session complete!"),
            content: Row(
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    trackTime();
                  },
                  child: const Text("Track"),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Close"),
                ),
              ],
            ),
          ),
    );
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
              children: [Visibility(
                visible: !_isRunning,
                child:
                DropdownButton<TrackerItem>(
                padding: const EdgeInsets.symmetric(vertical: 10),
                value: _selectedTracker,
                hint: const Text("Select a tracker", textAlign: TextAlign.center,),
                items: _trackers.map((tracker) {
                  return DropdownMenuItem<TrackerItem>(
                    value: tracker,
                    child: Text(tracker.name),
                  );
                }).toList(),
                onChanged: (TrackerItem? selected) {
                  setState(() {
                    _selectedTracker = selected;
                  });
                },
              ),),
                Visibility(
                  visible: !_isRunning,
                  child: Slider(
                    value: _sliderValue,
                    min: 1,
                    max: 3,
                    divisions: 2,
                    label: '${_sliderValue.toInt()} min',
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
                  onPressed: _isLoading
                      ? null
                      : _isRunning
                      ? stopCountdown
                      : startCountdown,
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

class CountdownPainter extends CustomPainter {
  final double progress;

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

    canvas.drawCircle(center, radius, backgroundPaint);

    final sweepAngle = 2 * 3.141592653589793 * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.141592653589793 / 2,
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
