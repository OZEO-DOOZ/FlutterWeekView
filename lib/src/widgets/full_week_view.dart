import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_week_view/src/controller/day_view.dart';
import 'package:flutter_week_view/src/week_event.dart';
import 'package:flutter_week_view/src/styles/day_bar.dart';
import 'package:flutter_week_view/src/styles/day_view.dart';
import 'package:flutter_week_view/src/styles/hours_column.dart';
import 'package:flutter_week_view/src/utils/builders.dart';
import 'package:flutter_week_view/src/utils/event_grid.dart';
import 'package:flutter_week_view/src/utils/hour_minute.dart';
import 'package:flutter_week_view/src/utils/scroll.dart';
import 'package:flutter_week_view/src/widgets/hours_column.dart';
import 'package:flutter_week_view/src/widgets/week_bar.dart';
import 'package:flutter_week_view/src/widgets/zoomable_header_widget.dart';

typedef EvenSelectCallback = Function(WeekEvent event);

class FullWeekView
    extends ZoomableHeadersWidget<DayViewStyle, DayViewController> {
  /// The events.
  final List<WeekEvent> events;

  /// The day view date.
  final DateTime date;

  /// The day bar style.
  final DayBarStyle dayBarStyle;

  /// Event's Colors
  final List<Color> eventColors;

  /// EvenSelectCallback
  final EvenSelectCallback onPressSelect;

  /// EvenSelectCallback
  final EvenSelectCallback onDragSelect;

  /// Creates a new day view instance.
  FullWeekView({
    List<WeekEvent> events,
    DateTime date,
    DayViewStyle style,
    HoursColumnStyle hoursColumnStyle,
    DayBarStyle dayBarStyle,
    List<Color> eventColors,
    DayViewController controller,
    bool inScrollableWidget,
    TimeOfDay minimumTime,
    TimeOfDay maximumTime,
    HourMinute initialTime,
    bool userZoomable,
    EvenSelectCallback onPressSelect,
    EvenSelectCallback onDragSelect,
  })  : date = DateTime.now(),
        events = events ?? [],
        dayBarStyle = dayBarStyle ?? DayBarStyle.fromDate(date: DateTime.now()),
        onPressSelect = onPressSelect,
        onDragSelect = onDragSelect,
        eventColors =
            eventColors ?? [const Color(0xffcdebef), const Color(0xff40798d)],
        super(
          style: style ?? DayViewStyle.fromDate(date: DateTime.now()),
          hoursColumnStyle: hoursColumnStyle ?? const HoursColumnStyle(),
          controller: controller ?? DayViewController(),
          inScrollableWidget: inScrollableWidget ?? true,
          minimumTime: HourMinute.fromTimeOfDay(
                timeOfDay: minimumTime ?? const TimeOfDay(hour: 6, minute: 0),
              ) ??
              HourMinute.MIN,
          maximumTime: HourMinute.fromTimeOfDay(
                timeOfDay: maximumTime ?? const TimeOfDay(hour: 23, minute: 59),
              ) ??
              HourMinute.MAX,
          initialTime: (initialTime ?? HourMinute.MIN).atDate(DateTime.now()),
          userZoomable: userZoomable ?? false,
          hoursColumnTimeBuilder: DefaultBuilders.defaultHoursColumnTimeBuilder,
          currentTimeIndicatorBuilder:
              DefaultBuilders.defaultCurrentTimeIndicatorBuilder,
        );

  @override
  State<StatefulWidget> createState() => _FullWeekViewState();
}

/// The day view state.
class _FullWeekViewState extends ZoomableHeadersWidgetState<FullWeekView> {
  double maxHeight;
  Offset selectionStart;
  Offset selectionUpdate;

  @override
  void initState() {
    super.initState();
    scheduleScrollToInitialTime();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(createEventsDrawProperties);
      }
    });
  }

  @override
  void didUpdateWidget(FullWeekView oldWidget) {
    super.didUpdateWidget(oldWidget);
    createEventsDrawProperties();
  }

  void updateMinZoom(double minZoom) {
    widget.controller.minZoom = minZoom;
  }

  /// update HourRowHeigh by maxHeight of FullWeekView (make time fixed with height)
  void updateHourRowHeight(double maxHeight) {
    final distance =
        (widget.maximumTime.hour + widget.maximumTime.minute / 60) -
            (widget.minimumTime.hour + widget.minimumTime.minute / 60);
    final newHourRowHeight = maxHeight / distance;
    if (hourRowHeight > newHourRowHeight) {
      hourRowHeight = newHourRowHeight;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget mainWidget = createMainWidget();
    if (widget.style.headerSize > 0 || widget.hoursColumnStyle.width > 0) {
      mainWidget = Stack(
        children: [
          mainWidget,
          Positioned(
            top: 0,
            left: widget.hoursColumnStyle.width,
            right: 0,
            child: WeekBar.fromHeadersWidgetState(
              parent: widget,
              style: widget.dayBarStyle,
              width: double.infinity,
            ),
          ),
          Container(
            height: widget.style.headerSize,
            width: widget.hoursColumnStyle.width,
            color: widget.dayBarStyle.color,
          ),
        ],
      );
    }

    if (!isZoomable) {
      return LayoutBuilder(
        builder: (context, constraints) {
          maxHeight ??= constraints.maxHeight - widget.style.headerSize;
          updateHourRowHeight(maxHeight);
          return mainWidget;
        },
      );
    }
    return GestureDetector(
      onScaleStart: (_) => widget.controller.scaleStart(),
      onScaleUpdate: (detail) {
        widget.controller.scaleUpdate(detail);
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          maxHeight ??= constraints.maxHeight - widget.style.headerSize;
          if (calculateHeight() <= maxHeight) {
            updateMinZoom(widget.controller.zoomFactor);
          }
          return mainWidget;
        },
      ),
    );
  }

  @override
  void onZoomFactorChanged(
      DayViewController controller, ScaleUpdateDetails details) {
    super.onZoomFactorChanged(controller, details);

    if (mounted) {
      setState(createEventsDrawProperties);
    }
  }

  @override
  DayViewStyle get currentDayViewStyle =>
      widget.style.copyWith(hourRowHeight: hourRowHeight);

  /// Creates all event wiget, indicator Box and action drag selection
  Widget weekBuilder() {
    final dragWidth =
        MediaQuery.of(context).size.width - widget.hoursColumnStyle.width;
    final eventWidth = dragWidth / 7;
    widget.events.sort((a, b) => a.start.hour > b.start.hour ? 1 : 0);
    final children = widget.events
        .map((entry) {
          final timeStartObj = HourMinute.fromTimeOfDay(timeOfDay: entry.start);
          final timeEndObj = HourMinute.fromTimeOfDay(timeOfDay: entry.end);
          return entry.day
              .map((e) => Positioned(
                    top: calculateTopOffset(timeStartObj),
                    left: (e - 1) * eventWidth,
                    child: InkWell(
                      onTap: () =>
                          entry.onPress != null ? entry.onPress(entry) : null,
                      onLongPress: () => entry.onLongPress != null
                          ? entry.onLongPress(entry)
                          : null,
                      child: Container(
                        width: eventWidth,
                        height: calculateTopOffset(timeEndObj) -
                            calculateTopOffset(timeStartObj),
                        child: entry.child,
                        decoration: BoxDecoration(
                            gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: widget.eventColors),
                            border: Border.all(
                                color: const Color(0xffd8eaf3), width: 0.5)),
                      ),
                    ),
                  ))
              .toList();
        })
        .toList()
        .expand((element) => element)
        .toList();

    final curMaxHeight = maxHeight ?? MediaQuery.of(context).size.height;
    final isMinScale = calculateHeight() <= curMaxHeight;

    if (selectionStart != null) {
      children.add(indicatorBuilder(eventWidth));
    }

    return GestureDetector(
      onTapUp: (details) {
        final startTime = calculateTimeOfDay(details.localPosition.dy);
        final endTime = startTime.replacing(hour: startTime.hour + 1);
        final listDay = calculateDay(details.localPosition.dx, eventWidth);
        widget.onPressSelect(
          WeekEvent(start: startTime, end: endTime, day: listDay),
        );
      },
      onPanStart: isMinScale
          ? (details) => setState(() {
                selectionStart = details.localPosition;
                selectionUpdate = details.localPosition;
              })
          : null,
      onPanUpdate: isMinScale
          ? (details) => setState(() {
                selectionUpdate = Offset(
                  max(details.localPosition.dx, 0),
                  max(details.localPosition.dy, 0),
                );
              })
          : null,
      onPanEnd: isMinScale
          ? (details) {
              final startTime = calculateTimeOfDay(
                  min(selectionStart.dy, selectionUpdate.dy));
              final endTime = calculateTimeOfDay(
                  max(selectionStart.dy, selectionUpdate.dy));
              widget.onDragSelect(WeekEvent(
                start: startTime,
                end: endTime,
                day: _getListDay(eventWidth),
              ));
              setState(() {
                selectionStart = null;
              });
            }
          : null,
      child: Container(
          width: double.infinity,
          color: widget.style.backgroundColor,
          child: Stack(children: children)),
    );
  }

  /// Creates the main widget, with a hours column and an events column.
  Widget createMainWidget() {
    List<Widget> children = [];

    children.add(Padding(
      padding: EdgeInsets.only(left: widget.hoursColumnStyle.width),
      child: weekBuilder(),
    ));

    if (widget.hoursColumnStyle.width > 0) {
      children.add(Positioned(
        top: 0,
        left: 0,
        child: HoursColumn.fromHeadersWidgetState(parent: this),
      ));
    }

    Widget mainWidget = SizedBox(
      height: calculateHeight(),
      child: Stack(children: children),
    );

    if (verticalScrollController != null) {
      mainWidget = NoGlowBehavior.noGlow(
        child: SingleChildScrollView(
          controller: verticalScrollController,
          child: mainWidget,
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(top: widget.style.headerSize),
      child: mainWidget,
    );
  }

  /// Create indicator box wiget
  Widget indicatorBuilder(double eventWidth) {
    final left =
        (min(selectionUpdate.dx, selectionStart.dx) / eventWidth).floor() *
            eventWidth;
    final width =
        (max(selectionUpdate.dx, selectionStart.dx) / eventWidth).floor() *
            eventWidth;
    return Positioned(
      top: min(selectionStart.dy, selectionUpdate.dy),
      left: left,
      child: Container(
        width: (width - left).abs() + eventWidth,
        height: ((selectionUpdate.dy ?? selectionStart.dy) - selectionStart.dy)
            .abs(),
        decoration: BoxDecoration(
            color: const Color(0x33cdebef),
            border: Border.all(color: const Color(0xff40798d), width: 0.5)),
      ),
    );
  }

  /// Creates the events draw properties and add them to the current list.
  void createEventsDrawProperties() {
    EventGrid eventsGrid = EventGrid();

    if (eventsGrid.drawPropertiesList.isNotEmpty) {
      double eventsColumnWidth =
          (context.findRenderObject() as RenderBox).size.width -
              widget.hoursColumnStyle.width;
      eventsGrid.processEvents(
          widget.hoursColumnStyle.width, eventsColumnWidth);
    }
  }

  /// Get list Day of week
  List<int> _getListDay(double eventWidth) {
    List<int> list = [];
    int start =
        (min(selectionStart.dx, selectionUpdate.dx) / eventWidth).floor();
    int end = (max(selectionStart.dx, selectionUpdate.dx) / eventWidth).floor();
    while (start <= end) {
      list.add(start + 1);
      start += 1;
    }
    return list;
  }
}
