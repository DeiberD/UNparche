import 'dart:async';
import 'package:flutter/material.dart';

import 'event_api_client.dart';
import 'auth_state.dart';
import 'flutter_chat/chat_message.dart';
import 'flutter_chat/chat_socket_client.dart';

enum EventTimeScope { future, past }

enum EventAttendanceScope { all, confirmed, created }

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

class EventsListView extends StatelessWidget {
  const EventsListView({
    super.key,
    required this.events,
    required this.calendarEvents,
    required this.selectedDate,
    required this.timeScope,
    required this.isLoading,
    required this.errorMessage,
    required this.onRefresh,
    required this.onEventTap,
    required this.onDateSelected,
    required this.onTimeScopeChanged,
    required this.attendanceScope,
    required this.onAttendanceScopeChanged,
  });

  static const background = Color(0xFFFBF5F2);
  static const surface = Color(0xFFF3ECE8);
  static const ink = Color(0xFF263020);
  static const accent = Color(0xFFEEDDF0);

  final List<EventSummary> events;
  final List<EventSummary> calendarEvents;
  final DateTime? selectedDate;
  final EventTimeScope timeScope;
  final bool isLoading;
  final String? errorMessage;
  final Future<void> Function() onRefresh;
  final ValueChanged<EventSummary> onEventTap;
  final ValueChanged<DateTime?> onDateSelected;
  final ValueChanged<EventTimeScope> onTimeScopeChanged;
  final EventAttendanceScope attendanceScope;
  final ValueChanged<EventAttendanceScope> onAttendanceScopeChanged;

  @override
  Widget build(BuildContext context) {
    final isHistory = timeScope == EventTimeScope.past;
    return Container(
      color: background,
      child: RefreshIndicator(
        onRefresh: onRefresh,
        color: ink,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 154, 16, 112),
          children: [
            Text(
              isHistory ? 'Historial de eventos' : 'Eventos disponibles',
              style: const TextStyle(
                color: ink,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isHistory
                  ? 'Actividades pasadas en las que confirmaste asistencia.'
                  : 'Actividades publicas ordenadas por fecha de inicio.',
              style: TextStyle(
                color: ink.withAlpha(180),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (!isHistory) ...[
              const SizedBox(height: 16),
              SegmentedButton<EventAttendanceScope>(
                segments: const [
                  ButtonSegment(
                    value: EventAttendanceScope.all,
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Todos', maxLines: 1, softWrap: false),
                    ),
                  ),
                  ButtonSegment(
                    value: EventAttendanceScope.confirmed,
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Confirmados', maxLines: 1, softWrap: false),
                    ),
                  ),
                  ButtonSegment(
                    value: EventAttendanceScope.created,
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Creados por mí',
                        maxLines: 1,
                        softWrap: false,
                      ),
                    ),
                  ),
                ],
                selected: {attendanceScope},
                onSelectionChanged: (selection) {
                  onAttendanceScopeChanged(selection.first);
                },
              ),
            ],
            const SizedBox(height: 16),
            _EventCalendarStrip(
              events: calendarEvents,
              selectedDate: selectedDate,
              timeScope: timeScope,
              onDateSelected: onDateSelected,
              onTimeScopeChanged: onTimeScopeChanged,
            ),
            const SizedBox(height: 16),
            if (errorMessage != null)
              _ListStateMessage(
                icon: Icons.error_outline,
                title: 'No se pudo cargar la lista',
                message: errorMessage!,
              )
            else if (!isLoading && events.isEmpty)
              _ListStateMessage(
                icon: Icons.event_busy_outlined,
                title: isHistory
                    ? 'No hay eventos en tu historial'
                    : selectedDate == null
                    ? 'No hay eventos disponibles'
                    : 'No hay eventos este dia',
                message: isHistory
                    ? 'Cuando asistas a un evento, podras recordarlo aqui.'
                    : selectedDate == null
                    ? 'Cuando existan eventos publicos, apareceran aqui.'
                    : 'Selecciona otro dia o limpia el filtro de fecha.',
              )
            else
              ...events.map(
                (event) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: EventListTile(
                    event: event,
                    onTap: () => onEventTap(event),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
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
                  label: 'Historial',
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

class EventListTile extends StatelessWidget {
  const EventListTile({super.key, required this.event, required this.onTap});

  final EventSummary event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = event.title.trim().isEmpty
        ? 'Evento sin titulo'
        : event.title;
    return Material(
      color: Colors.white.withAlpha(242),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: EventsListView.ink.withAlpha(20)),
            boxShadow: [
              BoxShadow(
                color: EventsListView.ink.withAlpha(12),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _eventColor(event.eventTypeId).withAlpha(36),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _eventIcon(event.eventTypeId),
                  color: _eventColor(event.eventTypeId),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: EventsListView.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${formatEventStart(event.start)} · ${event.eventTypeLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: EventsListView.ink.withAlpha(180),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      event.description.isEmpty
                          ? 'Sin descripcion'
                          : event.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: EventsListView.ink.withAlpha(160),
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right,
                color: EventsListView.ink,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({
    super.key,
    required this.event,
    required this.eventApiClient,
    required this.currentUserId,
    required this.onAttendanceChanged,
    required this.onDeleted,
  });

  final EventSummary event;
  final EventApiClient eventApiClient;
  final int currentUserId;
  final ValueChanged<EventSummary> onAttendanceChanged;
  final ValueChanged<int> onDeleted;

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  late EventSummary _event;
  bool _isUpdatingAttendance = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _event = widget.event;
  }

  @override
  Widget build(BuildContext context) {
    final event = _event;
    final title = event.title.trim().isEmpty
        ? 'Evento sin titulo'
        : event.title;
    return Scaffold(
      backgroundColor: EventsListView.background,
      appBar: AppBar(
        backgroundColor: EventsListView.background,
        foregroundColor: EventsListView.ink,
        title: const Text(
          'Detalle del evento',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 26),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: EventsListView.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: EventsListView.ink.withAlpha(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (event.isArchived) ...[
                    const _ArchivedEventNotice(),
                    const SizedBox(height: 14),
                  ],
                  if (!event.hasCompleteRequiredDetails) ...[
                    const _IncompleteEventNotice(),
                    const SizedBox(height: 14),
                  ],
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: _eventColor(
                          event.eventTypeId,
                        ).withAlpha(36),
                        child: Icon(
                          _eventIcon(event.eventTypeId),
                          color: _eventColor(event.eventTypeId),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          event.eventTypeLabel,
                          style: const TextStyle(
                            color: EventsListView.ink,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    title,
                    style: const TextStyle(
                      color: EventsListView.ink,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    event.description.isEmpty
                        ? 'Sin descripcion disponible.'
                        : event.description,
                    style: TextStyle(
                      color: EventsListView.ink.withAlpha(190),
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _DetailInfoRow(
              icon: Icons.category_outlined,
              title: 'Tipo',
              value: event.eventTypeLabel,
            ),
            _DetailInfoRow(
              icon: Icons.calendar_today_outlined,
              title: 'Fecha',
              value: formatEventDate(event.start),
            ),
            _DetailInfoRow(
              icon: Icons.schedule,
              title: 'Hora',
              value: formatEventTime(event.start),
            ),
            _DetailInfoRow(
              icon: Icons.timer_outlined,
              title: 'Duracion',
              value: event.durationMinutes == null
                  ? 'Por confirmar'
                  : '${event.durationMinutes} minutos',
            ),
            _DetailInfoRow(
              icon: Icons.place_outlined,
              title: 'Ubicacion',
              value: event.locationLabel,
            ),
            _DetailInfoRow(
              icon: Icons.group_outlined,
              title: 'Organizador',
              value: event.organizerLabel,
            ),
            const SizedBox(height: 12),
            _OrganizerCard(event: event),
            const SizedBox(height: 12),
            _AttendanceCard(
              event: event,
              isUpdating: _isUpdatingAttendance,
              onPressed: event.isActive && event.id != null
                  ? _toggleAttendance
                  : null,
            ),
            if (!event.isArchived &&
                event.organizerId == widget.currentUserId) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _isDeleting ? null : _confirmDelete,
                icon: _isDeleting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete_outline),
                label: Text(_isDeleting ? 'Eliminando...' : 'Eliminar evento'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                  side: BorderSide(color: Colors.red.shade300),
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              height: 54,
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: event.hasLocation && !event.isArchived
                          ? () => Navigator.of(context).pop(true)
                          : null,
                      icon: const Icon(Icons.map_outlined),
                      label: const Text('Ver ubicacion en mapa'),
                      style: FilledButton.styleFrom(
                        backgroundColor: EventsListView.ink,
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(fontWeight: FontWeight.w800),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  if (event.chatEnabled) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => EventChatScreen(event: event),
                          ),
                        ),
                        icon: const Icon(Icons.chat_bubble_outline),
                        label: const Text('Chat'),
                        style: FilledButton.styleFrom(
                          backgroundColor: EventsListView.accent,
                          foregroundColor: EventsListView.ink,
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w800,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleAttendance() async {
    if (_isUpdatingAttendance) {
      return;
    }

    final eventId = _event.id;
    if (eventId == null) {
      _showAttendanceMessage('Este evento no tiene identificador valido.');
      return;
    }

    setState(() => _isUpdatingAttendance = true);

    try {
      if (_event.hasConfirmedAttendance) {
        await widget.eventApiClient.cancelAttendance(
          eventId: eventId,
          userId: widget.currentUserId,
        );
        _updateAttendanceStatus('CANCELADA');
        _showAttendanceMessage('Asistencia cancelada.');
      } else {
        await widget.eventApiClient.confirmAttendance(
          eventId: eventId,
          userId: widget.currentUserId,
        );
        _updateAttendanceStatus('CONFIRMADA');
        _showAttendanceMessage('Asistencia confirmada.');
      }
    } on EventApiException catch (error) {
      _showAttendanceMessage(error.message);
    } catch (_) {
      _showAttendanceMessage('No se pudo actualizar la asistencia.');
    } finally {
      if (mounted) {
        setState(() => _isUpdatingAttendance = false);
      }
    }
  }

  Future<void> _confirmDelete() async {
    final eventId = _event.id;
    if (eventId == null || _isDeleting) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar evento'),
        content: Text(
          '¿Seguro que deseas eliminar “${_event.title}”? Esta acción lo quitará de los eventos disponibles.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      await widget.eventApiClient.deleteEvent(
        eventId: eventId,
        userId: widget.currentUserId,
      );
      widget.onDeleted(eventId);
      if (mounted) Navigator.of(context).pop();
    } on EventApiException catch (error) {
      _showAttendanceMessage(error.message);
    } catch (_) {
      _showAttendanceMessage('No se pudo eliminar el evento.');
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  void _updateAttendanceStatus(String status) {
    final updatedEvent = _event.copyWith(attendanceStatus: status);
    setState(() => _event = updatedEvent);
    widget.onAttendanceChanged(updatedEvent);
  }

  void _showAttendanceMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _AttendanceCard extends StatelessWidget {
  const _AttendanceCard({
    required this.event,
    required this.isUpdating,
    required this.onPressed,
  });

  final EventSummary event;
  final bool isUpdating;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final isConfirmed = event.hasConfirmedAttendance;
    final canInteract = onPressed != null;
    final statusText = isConfirmed
        ? 'Tu asistencia esta confirmada.'
        : canInteract
        ? 'Aun no has confirmado asistencia.'
        : 'Este evento no permite cambios de asistencia.';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(238),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EventsListView.ink.withAlpha(18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isConfirmed
                    ? Icons.check_circle_outline
                    : Icons.how_to_reg_outlined,
                color: EventsListView.ink,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Asistencia',
                  style: TextStyle(
                    color: EventsListView.ink.withAlpha(170),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            statusText,
            style: const TextStyle(
              color: EventsListView.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isUpdating ? null : onPressed,
              icon: isUpdating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      isConfirmed
                          ? Icons.event_busy_outlined
                          : Icons.event_available_outlined,
                    ),
              label: Text(
                isUpdating
                    ? 'Actualizando...'
                    : isConfirmed
                    ? 'Cancelar asistencia'
                    : 'Confirmar asistencia',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: isConfirmed
                    ? const Color(0xFF7A3525)
                    : EventsListView.ink,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EventChatScreen extends StatefulWidget {
  const EventChatScreen({super.key, required this.event});

  final EventSummary event;

  @override
  State<EventChatScreen> createState() => _EventChatScreenState();
}

class _EventChatScreenState extends State<EventChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  ChatSocketClient? _client;
  StreamSubscription<ChatMessage>? _messagesSubscription;
  StreamSubscription<void>? _joinedSubscription;
  String? _statusMessage = 'Conectando al chat...';
  bool _isJoined = false;
  String _correo = '';
  String _nickname = ' ';
  bool _didStartConnection = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didStartConnection) {
      return;
    }

    _didStartConnection = true;
    final user = AuthProvider.of(context).value.currentUser;
    _correo = user?.correoInstitucional ?? '';
    _nickname = user?.chatNickname ?? ' ';
    unawaited(_connectToChat());
  }

  Future<void> _connectToChat() async {
    final eventId = widget.event.id;
    if (eventId == null) {
      setState(() => _statusMessage = 'Este evento no tiene ID de chat.');
      return;
    }

    final client = ChatSocketClient(
      host: ChatSocketClient.defaultHost,
      port: ChatSocketClient.defaultPort,
    );

    _messagesSubscription = client.messages.listen(
      (message) {
        if (!mounted) {
          return;
        }
        setState(() => _messages.add(message));
        _scrollToBottom();
      },
      onError: (Object error) {
        if (!mounted) {
          return;
        }
        setState(() => _statusMessage = error.toString());
      },
    );

    _joinedSubscription = client.onJoined.listen((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isJoined = true;
        _statusMessage = null;
      });
    });

    try {
      await client.connectAndJoin(
        idEvento: eventId,
        correo: _correo,
        nickname: _nickname,
      );
      if (!mounted) {
        await client.dispose();
        return;
      }
      _client = client;
    } on ChatSocketException catch (error) {
      if (!mounted) {
        await client.dispose();
        return;
      }
      setState(() => _statusMessage = error.toString());
      await client.dispose();
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      return;
    }

    try {
      _client?.sendMessage(text);
      _messageController.clear();
    } on ChatSocketException catch (error) {
      setState(() => _statusMessage = error.toString());
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    unawaited(_messagesSubscription?.cancel());
    unawaited(_joinedSubscription?.cancel());
    unawaited(_client?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eventTitle = widget.event.title.trim().isEmpty
        ? 'Chat del evento'
        : widget.event.title.trim();

    return Scaffold(
      backgroundColor: EventsListView.background,
      appBar: AppBar(
        backgroundColor: EventsListView.background,
        foregroundColor: EventsListView.ink,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Chat', style: TextStyle(fontWeight: FontWeight.w900)),
            Text(
              eventTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: EventsListView.ink.withAlpha(170),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _messages.isEmpty
                  ? _EmptyChatMessage(statusMessage: _statusMessage)
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        return _ChatBubble(
                          message: message,
                          isMine: message.correo == _correo,
                        );
                      },
                    ),
            ),
            if (_statusMessage != null && _messages.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
                child: Text(
                  _statusMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: EventsListView.ink.withAlpha(150),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            _ChatInputBar(
              controller: _messageController,
              enabled: _isJoined,
              onSend: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyChatMessage extends StatelessWidget {
  const _EmptyChatMessage({required this.statusMessage});

  final String? statusMessage;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Text(
          statusMessage ??
              'Todavia no hay mensajes. Se el primero en escribir.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: EventsListView.ink.withAlpha(165),
            fontSize: 14,
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message, required this.isMine});

  final ChatMessage message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final alignment = isMine
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;
    final bubbleColor = isMine ? EventsListView.ink : Colors.white;
    final textColor = isMine ? Colors.white : EventsListView.ink;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              message.nickname,
              style: TextStyle(
                color: EventsListView.ink.withAlpha(150),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.74,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMine ? 18 : 5),
                  bottomRight: Radius.circular(isMine ? 5 : 18),
                ),
                border: isMine
                    ? null
                    : Border.all(color: EventsListView.ink.withAlpha(18)),
                boxShadow: [
                  BoxShadow(
                    color: EventsListView.ink.withAlpha(12),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Text(
                message.contenido,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatInputBar extends StatelessWidget {
  const _ChatInputBar({
    required this.controller,
    required this.enabled,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: EventsListView.ink.withAlpha(22)),
          boxShadow: [
            BoxShadow(
              color: EventsListView.ink.withAlpha(14),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: enabled ? (_) => onSend() : null,
                decoration: InputDecoration(
                  hintText: enabled ? 'Escribe un mensaje...' : 'Conectando...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    color: EventsListView.ink.withAlpha(115),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: const TextStyle(
                  color: EventsListView.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _SendButton(enabled: enabled, onPressed: onSend),
          ],
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: FilledButton(
        onPressed: enabled ? onPressed : null,
        style: FilledButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: EventsListView.ink,
          disabledBackgroundColor: EventsListView.ink.withAlpha(55),
          shape: const CircleBorder(),
        ),
        child: const _SendArrowIcon(),
      ),
    );
  }
}

class _SendArrowIcon extends StatelessWidget {
  const _SendArrowIcon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(21, 21), painter: _SendArrowPainter());
  }
}

class _SendArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final path = Path()
      ..moveTo(size.width * 0.11, size.height * 0.12)
      ..lineTo(size.width * 0.90, size.height * 0.50)
      ..lineTo(size.width * 0.11, size.height * 0.88)
      ..lineTo(size.width * 0.23, size.height * 0.57)
      ..lineTo(size.width * 0.55, size.height * 0.50)
      ..lineTo(size.width * 0.23, size.height * 0.43)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class EventOrganizerDetailScreen extends StatelessWidget {
  const EventOrganizerDetailScreen({super.key, required this.event});

  final EventSummary event;

  @override
  Widget build(BuildContext context) {
    final isGroup = event.belongsToGroup;
    return Scaffold(
      backgroundColor: EventsListView.background,
      appBar: AppBar(
        backgroundColor: EventsListView.background,
        foregroundColor: EventsListView.ink,
        title: Text(
          isGroup ? 'Informacion del grupo' : 'Informacion del usuario',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 26),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: EventsListView.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: EventsListView.ink.withAlpha(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: _eventColor(
                      event.eventTypeId,
                    ).withAlpha(36),
                    child: Icon(
                      isGroup ? Icons.groups_outlined : Icons.person_outline,
                      color: _eventColor(event.eventTypeId),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    isGroup
                        ? event.groupName ?? 'Grupo sin nombre'
                        : event.organizerName ?? 'Usuario sin nombre publico',
                    style: const TextStyle(
                      color: EventsListView.ink,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isGroup ? _groupSubtitle(event) : _userSubtitle(event),
                    style: TextStyle(
                      color: EventsListView.ink.withAlpha(175),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isGroup
                        ? event.groupDescription ??
                              'Este grupo no tiene descripcion disponible.'
                        : event.organizerInfo ??
                              'Este usuario no tiene informacion publica adicional.',
                    style: TextStyle(
                      color: EventsListView.ink.withAlpha(190),
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (isGroup) ...[
              _DetailInfoRow(
                icon: Icons.category_outlined,
                title: 'Categoria',
                value: _titleCaseOrFallback(
                  event.groupCategory,
                  'Sin categoria',
                ),
              ),
              _DetailInfoRow(
                icon: Icons.verified_outlined,
                title: 'Estado',
                value: event.groupIsOfficial == true ? 'Oficial' : 'No oficial',
              ),
              _DetailInfoRow(
                icon: Icons.fact_check_outlined,
                title: 'Verificacion',
                value: _titleCaseOrFallback(
                  event.groupVerificationStatus,
                  'Sin verificar',
                ),
              ),
            ] else ...[
              _DetailInfoRow(
                icon: Icons.badge_outlined,
                title: 'Nombre',
                value: event.organizerName ?? 'No disponible',
              ),
              _DetailInfoRow(
                icon: Icons.school_outlined,
                title: 'Carrera',
                value: event.organizerCareer ?? 'No disponible',
              ),
              _DetailInfoRow(
                icon: Icons.mail_outline,
                title: 'Correo',
                value: event.organizerEmail ?? 'No disponible',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OrganizerCard extends StatelessWidget {
  const _OrganizerCard({required this.event});

  final EventSummary event;

  @override
  Widget build(BuildContext context) {
    final isGroup = event.belongsToGroup;
    return Material(
      color: Colors.white.withAlpha(238),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => EventOrganizerDetailScreen(event: event),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: EventsListView.ink.withAlpha(18)),
          ),
          child: Row(
            children: [
              Icon(
                isGroup ? Icons.groups_outlined : Icons.person_outline,
                color: EventsListView.ink,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isGroup ? 'Grupo organizador' : 'Usuario organizador',
                      style: TextStyle(
                        color: EventsListView.ink.withAlpha(165),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.organizerLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: EventsListView.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: EventsListView.ink),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArchivedEventNotice extends StatelessWidget {
  const _ArchivedEventNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EventsListView.accent.withAlpha(150),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: EventsListView.ink.withAlpha(35)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.inventory_2_outlined, color: EventsListView.ink, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Este evento fue archivado por su ciclo de vida. Se conserva como parte de tu historial.',
              style: TextStyle(
                color: EventsListView.ink,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IncompleteEventNotice extends StatelessWidget {
  const _IncompleteEventNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4DD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFC27A00).withAlpha(80)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF7A4A00), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Este evento tiene informacion incompleta. Algunos campos pueden aparecer como no disponibles.',
              style: TextStyle(
                color: EventsListView.ink.withAlpha(205),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String formatEventStart(DateTime? start) {
  if (start == null) {
    return 'Fecha por confirmar';
  }

  final localStart = start.toLocal();
  final hour = localStart.hour.toString().padLeft(2, '0');
  final minute = localStart.minute.toString().padLeft(2, '0');
  return '${shortEventDate(localStart)}/${localStart.year} · $hour:$minute';
}

String formatEventDate(DateTime? start) {
  if (start == null) {
    return 'Fecha no disponible';
  }

  final localStart = start.toLocal();
  return '${shortEventDate(localStart)}/${localStart.year}';
}

String formatEventTime(DateTime? start) {
  if (start == null) {
    return 'Hora no disponible';
  }

  final localStart = start.toLocal();
  final hour = localStart.hour.toString().padLeft(2, '0');
  final minute = localStart.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _groupSubtitle(EventSummary event) {
  final parts = [
    _titleCaseOrFallback(event.groupCategory, 'Categoria no disponible'),
    event.groupIsOfficial == true ? 'Oficial' : 'No oficial',
  ];
  return parts.join(' · ');
}

String _userSubtitle(EventSummary event) {
  return event.organizerCareer ?? event.organizerEmail ?? 'Usuario comunitario';
}

String _titleCaseOrFallback(String? value, String fallback) {
  final text = value?.trim();
  if (text == null || text.isEmpty) {
    return fallback;
  }

  final lower = text.toLowerCase().replaceAll('_', ' ');
  return lower
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1))
      .join(' ');
}

String _calendarTitle(DateTime date) {
  return '${_monthLabel(date.month)} ${date.year}';
}

String _monthLabel(int month) {
  return switch (month) {
    1 => 'Enero',
    2 => 'Febrero',
    3 => 'Marzo',
    4 => 'Abril',
    5 => 'Mayo',
    6 => 'Junio',
    7 => 'Julio',
    8 => 'Agosto',
    9 => 'Septiembre',
    10 => 'Octubre',
    11 => 'Noviembre',
    12 => 'Diciembre',
    _ => '',
  };
}

String _weekdayLabel(DateTime date) {
  return switch (date.weekday) {
    DateTime.monday => 'Lun',
    DateTime.tuesday => 'Mar',
    DateTime.wednesday => 'Mie',
    DateTime.thursday => 'Jue',
    DateTime.friday => 'Vie',
    DateTime.saturday => 'Sab',
    DateTime.sunday => 'Dom',
    _ => '',
  };
}

String shortEventDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}';
}

IconData _eventIcon(int? eventTypeId) {
  return switch (eventTypeId) {
    1 => Icons.school_outlined,
    2 => Icons.palette_outlined,
    3 => Icons.sports_soccer_outlined,
    4 => Icons.celebration_outlined,
    5 => Icons.more_horiz,
    _ => Icons.event_outlined,
  };
}

Color _eventColor(int? eventTypeId) {
  return switch (eventTypeId) {
    1 => const Color(0xFF4267B2),
    2 => const Color(0xFF8B4C9D),
    3 => const Color(0xFF2E7D32),
    4 => const Color(0xFFC2410C),
    5 => EventsListView.ink,
    _ => EventsListView.ink,
  };
}

class _DetailInfoRow extends StatelessWidget {
  const _DetailInfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(238),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EventsListView.ink.withAlpha(18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: EventsListView.ink, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: EventsListView.ink.withAlpha(170),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: EventsListView.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ListStateMessage extends StatelessWidget {
  const _ListStateMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(238),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: EventsListView.ink.withAlpha(20)),
      ),
      child: Column(
        children: [
          Icon(icon, color: EventsListView.ink, size: 32),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: EventsListView.ink,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: EventsListView.ink.withAlpha(170),
              fontSize: 13,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
