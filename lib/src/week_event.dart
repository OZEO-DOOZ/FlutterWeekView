import 'package:flutter/material.dart';

/// Represents a flutter week view event.
class WeekEvent extends Comparable<WeekEvent> {
  final String id;

  /// The event start date & time.
  final TimeOfDay start;

  /// The event end date & time.
  final TimeOfDay end;

  /// day of week
  ///
  /// (1 = Monday, 2 = Tuesday, 3 = Wednesday, 4 = Thursday, 5 = Friday, 6 = Saturday, 7 = Sunday)
  final List<int> day;

  /// Custom Widget inside event
  final Widget child;

  final Function onPress;

  final Function onLongPress;

  /// Creates a new flutter week view event instance.
  WeekEvent({
    this.id,
    @required this.start,
    @required this.end,
    @required this.day,
    this.child,
    this.onPress,
    this.onLongPress,
  })  : assert(start != null),
        assert(end != null),
        assert(day != null);

  @override
  int compareTo(WeekEvent other) {
    return 1;
  }

  @override
  String toString() {
    final timeStart = start.toString();
    final timeEnd = end.toString();
    final listDay = day.toString();
    return 'WeekEvent(id: @id - Start: $timeStart - End: $timeEnd - Day: $listDay)';
  }

  WeekEvent copyWith({
    TimeOfDay start,
    TimeOfDay end,
    List<int> day,
    Widget child,
    Function onPress,
    Function onLongPress,
  }) =>
      WeekEvent(
        start: start ?? this.start,
        end: end ?? this.end,
        day: day ?? this.day,
        child: child ?? this.child,
        onPress: onPress ?? this.onPress,
        onLongPress: onLongPress ?? this.onLongPress,
      );
}
