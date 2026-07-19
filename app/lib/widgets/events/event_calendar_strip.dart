import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/event_api_client.dart';
import '../../models/event_summary.dart';
import '../../models/event_api_exception.dart';
import '../../state/auth_state.dart';
import '../../flutter_chat/chat_message.dart';
import '../../flutter_chat/chat_socket_client.dart';
// TODO: clean up imports
abstract class _CalendarSelectionStrategy {
  const _CalendarSelectionStrategy();

  factory _CalendarSelectionStrategy.forScope(EventTimeScope scope) {
    return switch (scope) {
      EventTimeScope.future => const _FutureCalendarSelectionStrategy(),
      EventTimeScope.past => const _PastCalendarSelectionStrategy(),
    };
  }

  bool get showsMonthControls;

  String title(DateTime visibleMonth);

  Widget buildDateSelector({
    required List<EventSummary> events,
    required DateTime? selectedDate,
    required DateTime visibleMonth,
    required ValueChanged<DateTime?> onDateSelected,
  });
}

class _FutureCalendarSelectionStrategy extends _CalendarSelectionStrategy {
  const _FutureCalendarSelectionStrategy();

  @override
  bool get showsMonthControls => false;

  @override
  String title(DateTime visibleMonth) => 'Proximos 7 dias';

  @override
  Widget buildDateSelector({
    required List<EventSummary> events,
    required DateTime? selectedDate,
    required DateTime visibleMonth,
    required ValueChanged<DateTime?> onDateSelected,
  }) {
    final today = DateUtils.dateOnly(DateTime.now());
    final days = List.generate(8, (index) {
      final day = DateUtils.dateOnly(today.add(Duration(days: index)));
      return _CalendarDateOption(
        date: day,
        eventCount: _eventCountForDay(events, day),
        isSelected:
            selectedDate != null && DateUtils.isSameDay(selectedDate, day),
        isToday: DateUtils.isSameDay(day, today),
        isEnabled: true,
      );
    });

    return _FutureDaysStrip(days: days, onDateSelected: onDateSelected);
  }
}

class _PastCalendarSelectionStrategy extends _CalendarSelectionStrategy {
  const _PastCalendarSelectionStrategy();

  @override
  bool get showsMonthControls => true;

  @override
  String title(DateTime visibleMonth) => _calendarTitle(visibleMonth);

  @override
  Widget buildDateSelector({
    required List<EventSummary> events,
    required DateTime? selectedDate,
    required DateTime visibleMonth,
    required ValueChanged<DateTime?> onDateSelected,
  }) {
    final today = DateUtils.dateOnly(DateTime.now());
    final days = _monthCells(visibleMonth).map((day) {
      if (day == null) {
        return null;
      }

      final dayOnly = DateUtils.dateOnly(day);
      return _CalendarDateOption(
        date: day,
        eventCount: _eventCountForDay(events, day),
        isSelected:
            selectedDate != null && DateUtils.isSameDay(selectedDate, day),
        isToday: false,
        isEnabled: dayOnly.isBefore(today),
      );
    }).toList();

    return _PastMonthCalendar(days: days, onDateSelected: onDateSelected);
  }

  static List<DateTime?> _monthCells(DateTime month) {
    final firstDay = DateTime(month.year, month.month);
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final leadingBlanks = firstDay.weekday - DateTime.monday;
    final cells = <DateTime?>[
      for (var index = 0; index < leadingBlanks; index++) null,
      for (var day = 1; day <= daysInMonth; day++)
        DateTime(month.year, month.month, day),
    ];

    while (cells.length % 7 != 0) {
      cells.add(null);
    }

    return cells;
  }
}

class _CalendarDateOption {
  const _CalendarDateOption({
    required this.date,
    required this.eventCount,
    required this.isSelected,
    required this.isToday,
    required this.isEnabled,
  });

  final DateTime date;
  final int eventCount;
  final bool isSelected;
  final bool isToday;
  final bool isEnabled;
}

class _EventCalendarStrip extends StatefulWidget {
  const _EventCalendarStrip({
    required this.events,
    required this.selectedDate,
    required this.timeScope,
    required this.onDateSelected,
    required this.onTimeScopeChanged,
  });

  final List<EventSummary> events;
  final DateTime? selectedDate;
  final EventTimeScope timeScope;
  final ValueChanged<DateTime?> onDateSelected;
  final ValueChanged<EventTimeScope> onTimeScopeChanged;

  @override
  State<_EventCalendarStrip> createState() => _EventCalendarStripState();
}

class _EventCalendarStripState extends State<_EventCalendarStrip> {
  late DateTime _visibleMonth;

  @override
  void initState() {
    super.initState();
    final baseDate = widget.selectedDate ?? DateTime.now();
    _visibleMonth = DateTime(baseDate.year, baseDate.month);
  }

  @override
  void didUpdateWidget(covariant _EventCalendarStrip oldWidget) {
    super.didUpdateWidget(oldWidget);

    final selectedDate = widget.selectedDate;
    if (selectedDate != null && !_isSameMonth(selectedDate, _visibleMonth)) {
      _visibleMonth = DateTime(selectedDate.year, selectedDate.month);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strategy = _CalendarSelectionStrategy.forScope(widget.timeScope);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: EventsListView.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: EventsListView.ink.withAlpha(22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.calendar_month_outlined,
                color: EventsListView.ink,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  strategy.title(_visibleMonth),
                  style: const TextStyle(
                    color: EventsListView.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (strategy.showsMonthControls) ...[
                IconButton(
                  tooltip: 'Mes anterior',
                  onPressed: () => _changeMonth(-1),
                  icon: const Icon(Icons.chevron_left),
                  color: EventsListView.ink,
                ),
                IconButton(
                  tooltip: 'Mes siguiente',
                  onPressed: _canGoToNextPastMonth()
                      ? () => _changeMonth(1)
                      : null,
                  icon: const Icon(Icons.chevron_right),
                  color: EventsListView.ink,
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ScopeButton(
                  label: 'Futuros',
                  icon: Icons.upcoming_outlined,
                  selected: widget.timeScope == EventTimeScope.future,
                  onTap: () => widget.onTimeScopeChanged(EventTimeScope.future),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ScopeButton(
                  label: 'Pasados',
                  icon: Icons.history,
                  selected: widget.timeScope == EventTimeScope.past,
                  onTap: () => widget.onTimeScopeChanged(EventTimeScope.past),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: 'Limpiar fecha',
                onPressed: widget.selectedDate == null
                    ? null
                    : () => widget.onDateSelected(null),
                icon: const Icon(Icons.close),
                color: EventsListView.ink,
              ),
            ],
          ),
          const SizedBox(height: 14),
          strategy.buildDateSelector(
            events: widget.events,
            selectedDate: widget.selectedDate,
            visibleMonth: _visibleMonth,
            onDateSelected: widget.onDateSelected,
          ),
        ],
      ),
    );
  }

  void _changeMonth(int offset) {
    setState(() {
      _visibleMonth = DateTime(
        _visibleMonth.year,
        _visibleMonth.month + offset,
      );
    });
  }

  bool _canGoToNextPastMonth() {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final nextMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1);
    return nextMonth.isBefore(currentMonth) ||
        _isSameMonth(nextMonth, currentMonth);
  }

  static bool _isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }
}

class _FutureDaysStrip extends StatelessWidget {
  const _FutureDaysStrip({required this.days, required this.onDateSelected});

  final List<_CalendarDateOption> days;
  final ValueChanged<DateTime?> onDateSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: days.map((day) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _FutureDayButton(
              date: day.date,
              eventCount: day.eventCount,
              isSelected: day.isSelected,
              isToday: day.isToday,
              onTap: () => onDateSelected(day.date),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _PastMonthCalendar extends StatelessWidget {
  const _PastMonthCalendar({required this.days, required this.onDateSelected});

  final List<_CalendarDateOption?> days;
  final ValueChanged<DateTime?> onDateSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: const [
            _WeekdayHeader('L'),
            _WeekdayHeader('M'),
            _WeekdayHeader('M'),
            _WeekdayHeader('J'),
            _WeekdayHeader('V'),
            _WeekdayHeader('S'),
            _WeekdayHeader('D'),
          ],
        ),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: days.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 0.78,
          ),
          itemBuilder: (context, index) {
            final day = days[index];
            if (day == null) {
              return const SizedBox.shrink();
            }

            return _CalendarDayButton(
              date: day.date,
              eventCount: day.eventCount,
              isSelected: day.isSelected,
              isToday: day.isToday,
              isEnabled: day.isEnabled,
              onTap: day.isEnabled ? () => onDateSelected(day.date) : null,
            );
          },
        ),
      ],
    );
  }
}

int _eventCountForDay(List<EventSummary> events, DateTime day) {
  return events.where((event) {
    final start = event.start;
    return start != null && DateUtils.isSameDay(start.toLocal(), day);
  }).length;
}

class _ScopeButton extends StatelessWidget {
  const _ScopeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? EventsListView.ink : Colors.white.withAlpha(236),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? EventsListView.ink
                  : EventsListView.ink.withAlpha(22),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? Colors.white : EventsListView.ink,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? Colors.white : EventsListView.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: EventsListView.ink.withAlpha(150),
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _FutureDayButton extends StatelessWidget {
  const _FutureDayButton({
    required this.date,
    required this.eventCount,
    required this.isSelected,
    required this.isToday,
    required this.onTap,
  });

  final DateTime date;
  final int eventCount;
  final bool isSelected;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasEvents = eventCount > 0;
    return Material(
      color: isSelected ? EventsListView.ink : Colors.white.withAlpha(236),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: 66,
          height: 98,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? EventsListView.ink
                  : isToday
                  ? EventsListView.ink.withAlpha(80)
                  : EventsListView.ink.withAlpha(hasEvents ? 36 : 18),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _weekdayLabel(date),
                style: TextStyle(
                  color: isSelected
                      ? Colors.white.withAlpha(220)
                      : EventsListView.ink.withAlpha(150),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                date.day.toString(),
                style: TextStyle(
                  color: isSelected ? Colors.white : EventsListView.ink,
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Container(
                constraints: const BoxConstraints(minWidth: 24),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withAlpha(34)
                      : hasEvents
                      ? EventsListView.accent
                      : EventsListView.ink.withAlpha(10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$eventCount',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : EventsListView.ink,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalendarDayButton extends StatelessWidget {
  const _CalendarDayButton({
    required this.date,
    required this.eventCount,
    required this.isSelected,
    required this.isToday,
    required this.isEnabled,
    required this.onTap,
  });

  final DateTime date;
  final int eventCount;
  final bool isSelected;
  final bool isToday;
  final bool isEnabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasEvents = eventCount > 0;
    final ink = isEnabled
        ? EventsListView.ink
        : EventsListView.ink.withAlpha(86);
    return Material(
      color: isSelected
          ? EventsListView.ink
          : isEnabled
          ? Colors.white.withAlpha(236)
          : EventsListView.ink.withAlpha(10),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? EventsListView.ink
                  : isToday
                  ? EventsListView.ink.withAlpha(80)
                  : EventsListView.ink.withAlpha(hasEvents ? 36 : 18),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                date.day.toString(),
                style: TextStyle(
                  color: isSelected ? Colors.white : ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Container(
                constraints: const BoxConstraints(minWidth: 20),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withAlpha(34)
                      : hasEvents && isEnabled
                      ? EventsListView.accent
                      : EventsListView.ink.withAlpha(10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$eventCount',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : ink,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

