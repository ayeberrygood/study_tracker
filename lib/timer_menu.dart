//responsible for keeping track of all separate trackers
import 'dart:convert';

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

  int _counter = 0;
  final int _maxCounters = 8;

  List<TrackerItem> _trackers = [];

  bool _isLoading = true;

  Future<void> _saveData() async {
    final String encoded = jsonEncode(
      _trackers.map((t) => t.toJson()).toList(),
    );
    await _prefs.setString('tracker_list', encoded);
  }

  void addTracker() {
    if (_isLoading) return;
    setState(() {
      if (_trackers.length < _maxCounters) {
        _trackers.add(TrackerItem(name: "My Tracker", duration: 30));
        _counter = _trackers.length;
        _saveData();
      }
    });
  }

  void removeTracker() {
    if (_isLoading) return;
    setState(() {
      if (_trackers.isNotEmpty) {
        _trackers.removeLast();
        _counter = _trackers.length;
        _saveData();
      }
    });
  }

  void openTrackerDetail(int index) {
    final nameController =
    TextEditingController(text: _trackers[index].name);
    final durationController =
    TextEditingController(text: _trackers[index].duration.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Tracker'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: durationController,
              decoration: const InputDecoration(labelText: 'Duration (minutes)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          // Delete button on the left
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              setState(() {
                _trackers.removeAt(index);
                _counter = _trackers.length;
                _saveData();
              });
              Navigator.of(context).pop();
            },
            child: const Text('Delete'),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final newName = nameController.text.trim();
              final newDuration = int.tryParse(durationController.text.trim());
              if (newName.isEmpty || newDuration == null || newDuration <= 0) {
                return; // don't save invalid input
              }
              setState(() {
                _trackers[index] = TrackerItem(
                  name: newName,
                  duration: newDuration,
                );
                _saveData();
              });
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    _prefs.getString('tracker_list').then((value) {
      setState(() {
        if (value != null) {
          final List decoded = jsonDecode(value);
          _trackers = decoded.map((e) => TrackerItem.fromJson(e)).toList();
          _counter = _trackers.length;
        }
        _isLoading = false;
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
            itemCount: _trackers.length,
            itemBuilder: (BuildContext context, int index) {
              return GridTile(
                header: GridTileBar(
                  title: Text(
                    _trackers[index].name,
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
                    color: const Color(0x323B2C7E),
                  ),
                  child: TextButton(
                    onPressed: () => openTrackerDetail(index),
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
            TextButton(
              onPressed: _isLoading ? null : addTracker,
              child: const Text("Add"),
            ),
            TextButton(
              onPressed: _isLoading ? null : removeTracker,
              child: const Text("Remove"),
            ),
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
    count = 2;

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
    final int rowIndex = loopIndex ~/ crossAxisCount;
    final int columnIndex = loopIndex % crossAxisCount;
    return SliverGridGeometry(
      scrollOffset: (loop * loopHeight) + (rowIndex * dimension),
      crossAxisOffset: columnIndex * dimension,
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

class TrackerItem {
  late final String name;
  late final int duration;

  TrackerItem({required this.name, required this.duration});

  factory TrackerItem.fromJson(Map<String, dynamic> json) {
    return TrackerItem(
      name: json['name'] as String,
      duration: json['duration'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'duration': duration};
  }
}