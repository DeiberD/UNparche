import 'package:flutter/material.dart';
import '../../models/event_summary.dart';
import '../../models/event_scopes.dart';
import '../../widgets/events/event_calendar_strip.dart';
import '../../widgets/events/event_list_tile.dart';
import '../../theme/campus_colors.dart';
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
    return Container(
      color: background,
      child: RefreshIndicator(
        onRefresh: onRefresh,
        color: ink,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 154, 16, 112),
          children: [
            const Text(
              'Eventos disponibles',
              style: TextStyle(
                color: ink,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Actividades publicas ordenadas por fecha de inicio.',
              style: TextStyle(
                color: ink.withAlpha(180),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
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
                    child: Text('Creados por mí', maxLines: 1, softWrap: false),
                  ),
                ),
              ],
              selected: {attendanceScope},
              onSelectionChanged: (selection) {
                onAttendanceScopeChanged(selection.first);
              },
            ),
            const SizedBox(height: 16),
            EventCalendarStrip(
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
                title: selectedDate == null
                    ? 'No hay eventos disponibles'
                    : 'No hay eventos este dia',
                message: selectedDate == null
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
        border: Border.all(color: campusInk.withAlpha(20)),
      ),
      child: Column(
        children: [
          Icon(icon, color: campusInk, size: 32),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: campusInk,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: campusInk.withAlpha(170),
              fontSize: 13,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
