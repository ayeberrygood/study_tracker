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
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int _bottomIndex = 0;

  final List<Widget> _bottomScreens = [
    const ModesScreen(),
    const Placeholder(), //Overview tab, implement later
    const TrackerWindow(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Study Tracker"),
      ),
      body: _bottomScreens[_bottomIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _bottomIndex,
        onDestinationSelected: (index) {
          setState(() {
            _bottomIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.timer), label: "Modes"),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: "Overview"),
          NavigationDestination(icon: Icon(Icons.list), label: "Trackers"),
        ],
      ),
    );
  }
}

class ModesScreen extends StatelessWidget {
  const ModesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.hourglass_bottom), text: "Countdown"),
              Tab(icon: Icon(Icons.timer), text: "Stopwatch"),
            ],
          ),
          const Expanded(
            child: TabBarView(
              children: [
                CountdownModeScreen(),
                StopwatchModeScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}