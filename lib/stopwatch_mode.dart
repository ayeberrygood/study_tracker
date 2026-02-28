import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_tracker/timer_menu.dart';

class StopwatchModeScreen extends StatefulWidget {
  const StopwatchModeScreen({super.key});

  @override
  StopwatchModeScreenState createState() => StopwatchModeScreenState();
}

class StopwatchModeScreenState extends State<StopwatchModeScreen> {
  List<TrackerItem> _trackers = [];
  TrackerItem? _selectedTracker;
  bool _isLoading = true;
  late final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

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
    return "${duration.inHours.remainder(60) >= 1 ? "$hours:" : ""}$minutes:$seconds.$milliseconds";
  }

  void trackTime() async {
    if (_isLoading) return;
    if (_selectedTracker == null) return;

    final index = _trackers.indexOf(_selectedTracker!);
    if (index == -1) return;

    setState(() {
      _trackers[index] = TrackerItem(
        name: _trackers[index].name,
        duration: _trackers[index].duration - _durationNotifier.value.inMinutes,
      );
      _selectedTracker = null;
    });

    final String encoded = jsonEncode(
      _trackers.map((t) => t.toJson()).toList(),
    );
    await _prefs.setString('tracker_list', encoded);
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
            Column(
              // mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Visibility(
                  visible: !_isRunning,
                  child: DropdownButton<TrackerItem>(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    value: _selectedTracker,
                    hint: const Text(
                      "Select a tracker",
                      textAlign: TextAlign.center,
                    ),
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
                  ),
                ),
                SizedBox(height: 5),
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
                    SizedBox(width: 8),
                    Visibility(
                      visible: !_isRunning,
                      child: ElevatedButton(
                        onPressed: trackTime,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                        ),
                        child: Text("Track"),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Visibility(
                  visible: !_isRunning,
                  child: ElevatedButton(
                    onPressed: resetStopwatch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                    child: Text("Reset"),
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
