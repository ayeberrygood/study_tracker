//responsible for keeping track of all separate trackers
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_android/shared_preferences_android.dart';

class TrackerWindow extends StatefulWidget {
  const TrackerWindow({super.key});

  @override
  State<StatefulWidget> createState() => TrackerWindowState();
}

class TrackerWindowState extends State<TrackerWindow> {
  late final SharedPreferencesAsync _prefs = SharedPreferencesAsync();
  final SharedPreferencesAsyncAndroidOptions options =
      const SharedPreferencesAsyncAndroidOptions();

  static const String _counterKey = 'counter';
  static final String _currentTrackerName = 'name';
  static final int _currentCounterDuration = 30;

  dynamic IndividualTracker({required int duration, required String name}) {
    String name;
    int duration;

    IndividualTracker(duration: 30, name: '');

    // factory IndividualTracker.fromJson(Map<String, dynamic> json) {
    //   return IndividualTracker(
    //     name: json['name'],
    //     duration: json['30'],
    //   );
    // }

    name = stdin.readLineSync()!; //get user input for name
    duration = int.parse(stdin.readLineSync()!); //get user input for duration

    Map<String, dynamic> toJson() {
      return {'name': name, 'duration': duration};
    }
  }

  Future<void> saveTrackerList(List<TrackerWindow> trackers) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> jsonStringList = trackers
        .map((person) => jsonEncode(person.toJson()))
        .toList();
    await prefs.setStringList('tracker_list', jsonStringList);
  }

  int _counter = 0;
  final int _maxCounters = 8; //maybe make unlimited idk yet

  //implement menu pop-up to input info like [subject], [duration]
  void addTracker() {
    setState(() {
      if (_counter < _maxCounters) {
        _counter++;
        _prefs.setInt(_counterKey, _counter);
        _prefs.setString(_currentTrackerName, IndividualTracker.name);
      }
    });
  }

  void removeTracker() {
    setState(() {
      if (_counter > 0) {
        _counter--;
        _prefs.setInt(_counterKey, _counter);
      }
    });
  }

  void openTracker() {}

  @override
  void initState() {
    super.initState();

    _prefs.getInt(_counterKey).then((value) {
      setState(() {
        _counter = value!;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 0,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('You currently have $_counter trackers'),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12.0),
            gridDelegate: CustomGridDelegate(dimension: 200.0),
            itemCount: _counter,
            itemBuilder: (BuildContext context, int index) {
              final math.Random random = math.Random(index);
              return GridTile(
                header: GridTileBar(
                  title: Text(
                    _currentCounterName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.all(20.0),
                  decoration: ShapeDecoration(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9.0),
                    ),
                    color: Color(0x323B2C7E),
                  ),
                  child: TextButton(
                    onPressed: openTracker,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: null,
                        border: Border.all(color: Colors.white, width: 10),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(onPressed: addTracker, child: Text("Add")),
            TextButton(onPressed: removeTracker, child: Text("Remove")),
          ],
        ),
      ],
    );
  }
}

class CustomGridDelegate extends SliverGridDelegate {
  CustomGridDelegate({required this.dimension});

  final double dimension;

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    int count = constraints.crossAxisExtent ~/ dimension;
    count = 2; //two trackers per row

    final double squareDimension = constraints.crossAxisExtent / count;
    return CustomGridLayout(
      crossAxisCount: count,
      fullRowPeriod: 2,
      dimension: squareDimension,
    );
  }

  @override
  bool shouldRelayout(CustomGridDelegate oldDelegate) {
    return dimension != oldDelegate.dimension;
  }
}

class CustomGridLayout extends SliverGridLayout {
  const CustomGridLayout({
    required this.crossAxisCount,
    required this.dimension,
    required this.fullRowPeriod,
  }) : assert(crossAxisCount > 0),
       assert(fullRowPeriod > 1),
       loopLength = crossAxisCount * fullRowPeriod,
       loopHeight = fullRowPeriod * dimension;

  final int crossAxisCount;
  final double dimension;
  final int fullRowPeriod;

  // Computed values.
  final int loopLength;
  final double loopHeight;

  @override
  double computeMaxScrollOffset(int childCount) {
    if (childCount == 0 || dimension == 0) {
      return 0;
    }
    return (childCount ~/ loopLength) * loopHeight +
        ((childCount % loopLength) ~/ crossAxisCount) * dimension;
  }

  @override
  SliverGridGeometry getGeometryForChildIndex(int index) {
    final int loop = index ~/ loopLength;
    final int loopIndex = index % loopLength;
    if (loopIndex == loopLength - 1) {}
    final int rowIndex = loopIndex ~/ crossAxisCount;
    final int columnIndex = loopIndex % crossAxisCount;
    return SliverGridGeometry(
      scrollOffset: (loop * loopHeight) + (rowIndex * dimension), // "y"
      crossAxisOffset: columnIndex * dimension, // "x"
      mainAxisExtent: dimension,
      crossAxisExtent: dimension,
    );
  }

  @override
  int getMinChildIndexForScrollOffset(double scrollOffset) {
    final int rows = scrollOffset ~/ dimension;
    final int loops = rows ~/ fullRowPeriod;
    final int extra = rows % fullRowPeriod;
    return loops * loopLength + extra * crossAxisCount;
  }

  @override
  int getMaxChildIndexForScrollOffset(double scrollOffset) {
    final int rows = scrollOffset ~/ dimension;
    final int loops = rows ~/ fullRowPeriod;
    final int extra = rows % fullRowPeriod;
    final int count = loops * loopLength + extra * crossAxisCount;
    if (extra == fullRowPeriod - 1) {
      return count;
    }
    return count + crossAxisCount - 1;
  }
}

// class IndividualTracker {
//   String name;
//   int duration;
//
//   IndividualTracker({required this.name, required this.duration});
//
//   factory IndividualTracker.fromJson(Map<String, dynamic> json) {
//     return IndividualTracker(
//       name: json['name'],
//       duration: json['30'],
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'name': name,
//       'duration': duration,
//     };
//   }
//
//   Future<void> saveTrackerList(List<IndividualTracker> trackers) async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     List<String> jsonStringList = trackers.map((person) => jsonEncode(person.toJson())).toList();
//     await prefs.setStringList('tracker_list', jsonStringList);
//   }
// }
