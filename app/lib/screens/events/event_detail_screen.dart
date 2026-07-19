import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/event_api_client.dart';
import '../../models/event_summary.dart';
import '../../models/event_api_exception.dart';
import '../../state/auth_state.dart';
import '../../flutter_chat/chat_message.dart';
import '../../flutter_chat/chat_socket_client.dart';
// TODO: clean up imports
import '../chat/event_chat_screen.dart';
import 'event_organizer_detail_screen.dart';
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
            if (event.organizerId == widget.currentUserId) ...[
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
                      onPressed: event.hasLocation
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

