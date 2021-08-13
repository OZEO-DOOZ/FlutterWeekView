import 'package:flutter/material.dart';
import 'package:flutter_week_view/flutter_week_view.dart';

/// First plugin test method.
void main() => runApp(
      MaterialApp(
        home: _FlutterWeekViewDemoApp(),
      ),
    );

/// The demo material app.
class _FlutterWeekViewDemoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demo'),
      ),
      body: FullWeekView(
        minimumTime: const TimeOfDay(hour: 0, minute: 0),
        events: [
          WeekEvent(
              start: const TimeOfDay(hour: 12, minute: 0),
              end: const TimeOfDay(hour: 15, minute: 30),
              day: [1, 2, 3, 4],
              onPress: (event) => print(event),
              onLongPress: (event) => print('onLongPress: $event'),
              child: LayoutBuilder(
                builder: (context, constraints) => Icon(
                  Icons.ac_unit,
                  size: constraints.maxHeight < 30 ? constraints.maxHeight : 30,
                  color: Colors.white,
                ),
              )),
          WeekEvent(
              start: const TimeOfDay(hour: 8, minute: 0),
              end: const TimeOfDay(hour: 15, minute: 30),
              day: [1, 3],
              onPress: (event) => print(event),
              onLongPress: (event) => print('onLongPress: $event'),
              child: LayoutBuilder(
                builder: (context, constraints) => Icon(
                  Icons.ac_unit,
                  size: constraints.maxHeight < 30 ? constraints.maxHeight : 30,
                  color: Colors.white,
                ),
              )),
        ],
        onPressSelect: (event) => print(event.toString()),
        onDragSelect: (event) => print('onDragSelect:   $event'),
      ),
    );
  }
}
