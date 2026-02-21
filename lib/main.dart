//responsible for keeping track of app layout
import 'package:flutter/material.dart';

import 'package:study_tracker/countdown_mode.dart';
import 'package:study_tracker/stopwatch_mode.dart';
import 'package:study_tracker/timer_menu.dart';

void main() {
  runApp(const StudyTrackerApp());
}

class StudyTrackerApp extends StatelessWidget {
  const StudyTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: (false),
      theme: ThemeData.dark(),
      home: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            bottom: const TabBar(
              tabs: [
                Tab(text: "Countdown"),
                Tab(text: "Stopwatch"),
                Tab(text: "Trackers"),
              ],
            ),
            title: Text("Study Tracker"),
          ),
          body: TabBarView(
            children: [
              CountdownModeScreen(),
              StopwatchModeScreen(),
              TrackerWindow(),
            ],
          ),
        ),
      ),
    );
  }
}
