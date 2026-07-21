import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/event_api_client.dart';
import '../../models/event_summary.dart';
import '../../theme/campus_colors.dart';
import 'event_organizer_detail_screen.dart';
import '../../models/event_api_exception.dart';
import '../chat/event_chat_screen.dart';
import 'event_attendees_screen.dart';
import 'event_announcements_section.dart';

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
  bool _isUpdatingNotifications = false;
  bool _isCancelling = false;
  bool _isDeleting = false;

  bool get _canCancelEvent {
    final start = _event.start;
    return _event.id != null &&
        _event.organizerId == widget.currentUserId &&
        !_event.isArchived &&
        _event.status == 'PROGRAMADO' &&
        start != null &&
        start.isAfter(DateTime.now());
  }

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
      backgroundColor: campusBackground,
      appBar: AppBar(
        backgroundColor: campusBackground,
        foregroundColor: campusInk,
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
                color: campusSurface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: campusInk.withAlpha(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (event.isArchived) ...[
                    const _ArchivedEventNotice(),
                    const SizedBox(height: 14),
                  ],
                  if (event.isCancelled) ...[
                    const _CancelledEventNotice(),
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
                            color: campusInk,
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
                      color: campusInk,
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
                      color: campusInk.withAlpha(190),
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
            OrganizerCard(event: event),
            const SizedBox(height: 12),
            if (event.id != null) ...[
              EventAnnouncementsSection(
                eventId: event.id!,
                currentUserId: widget.currentUserId,
                canPublish:
                    event.isActive && event.organizerId == widget.currentUserId,
                eventApiClient: widget.eventApiClient,
              ),
              const SizedBox(height: 12),
            ],
            _AttendanceCard(
              event: event,
              isUpdating: _isUpdatingAttendance,
              isUpdatingNotifications: _isUpdatingNotifications,
              onPressed: event.isActive && event.id != null
                  ? _toggleAttendance
                  : null,
              onNotificationsChanged:
                  event.isActive && event.hasConfirmedAttendance
                  ? _toggleAnnouncementNotifications
                  : null,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: event.id == null || event.isArchived
                  ? null
                  : () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EventAttendeesScreen(
                          eventId: event.id!,
                          eventTitle: title,
                          eventApiClient: widget.eventApiClient,
                        ),
                      ),
                    ),
              icon: const Icon(Icons.groups_outlined),
              label: const Text('Ver asistentes confirmados'),
              style: OutlinedButton.styleFrom(
                foregroundColor: campusInk,
                minimumSize: const Size.fromHeight(50),
              ),
            ),
            if (!event.isArchived &&
                event.organizerId == widget.currentUserId) ...[
              const SizedBox(height: 12),
              if (_canCancelEvent)
                OutlinedButton.icon(
                  onPressed: _isCancelling ? null : _confirmCancellation,
                  icon: _isCancelling
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.event_busy_outlined),
                  label: Text(
                    _isCancelling ? 'Cancelando...' : 'Cancelar evento',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(color: Colors.red.shade300),
                    minimumSize: const Size.fromHeight(50),
                  ),
                )
              else if (!event.isCancelled)
                OutlinedButton.icon(
                  onPressed: _isDeleting ? null : _confirmDelete,
                  icon: _isDeleting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.delete_outline),
                  label: Text(
                    _isDeleting ? 'Eliminando...' : 'Eliminar evento',
                  ),
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
                      onPressed: event.hasLocation && event.isActive
                          ? () => Navigator.of(context).pop(true)
                          : null,
                      icon: const Icon(Icons.map_outlined),
                      label: const Text('Ver ubicacion en mapa'),
                      style: FilledButton.styleFrom(
                        backgroundColor: campusInk,
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(fontWeight: FontWeight.w800),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  if (event.chatEnabled && !event.isArchived) ...[
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
                          backgroundColor: campusAccent,
                          foregroundColor: campusInk,
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
        _updateAttendanceStatus('CANCELADA', notificationsEnabled: false);
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

  Future<void> _toggleAnnouncementNotifications(bool enabled) async {
    final eventId = _event.id;
    if (eventId == null || _isUpdatingNotifications) return;

    setState(() => _isUpdatingNotifications = true);
    try {
      final updated = await widget.eventApiClient
          .updateAnnouncementNotifications(
            eventId: eventId,
            userId: widget.currentUserId,
            enabled: enabled,
          );
      final updatedEvent = _event.copyWith(notificationsEnabled: updated);
      if (!mounted) return;
      setState(() => _event = updatedEvent);
      widget.onAttendanceChanged(updatedEvent);
      _showAttendanceMessage(
        updated ? 'Recibiras los anuncios del evento.' : 'Avisos desactivados.',
      );
    } on EventApiException catch (error) {
      _showAttendanceMessage(error.message);
    } catch (_) {
      _showAttendanceMessage('No se pudo actualizar la preferencia de avisos.');
    } finally {
      if (mounted) setState(() => _isUpdatingNotifications = false);
    }
  }

  Future<void> _confirmCancellation() async {
    final eventId = _event.id;
    if (eventId == null || _isCancelling || !_canCancelEvent) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancelar evento'),
        content: Text(
          '¿Seguro que deseas cancelar “${_event.title}”? Dejará de mostrarse como activo y su chat se cerrará.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isCancelling = true);
    try {
      await widget.eventApiClient.cancelEvent(
        eventId: eventId,
        organizerId: widget.currentUserId,
      );
      final updatedEvent = _event.copyWith(
        status: 'CANCELADO',
        chatEnabled: false,
      );
      if (!mounted) return;
      setState(() => _event = updatedEvent);
      widget.onAttendanceChanged(updatedEvent);
      _showAttendanceMessage('Evento cancelado correctamente.');
    } on EventApiException catch (error) {
      _showAttendanceMessage(error.message);
    } catch (_) {
      _showAttendanceMessage('No se pudo cancelar el evento.');
    } finally {
      if (mounted) setState(() => _isCancelling = false);
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

  void _updateAttendanceStatus(String status, {bool? notificationsEnabled}) {
    final updatedEvent = _event.copyWith(
      attendanceStatus: status,
      notificationsEnabled: notificationsEnabled,
    );
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
    required this.isUpdatingNotifications,
    required this.onPressed,
    required this.onNotificationsChanged,
  });

  final EventSummary event;
  final bool isUpdating;
  final bool isUpdatingNotifications;
  final VoidCallback? onPressed;
  final ValueChanged<bool>? onNotificationsChanged;

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
        border: Border.all(color: campusInk.withAlpha(18)),
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
                color: campusInk,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Asistencia',
                  style: TextStyle(
                    color: campusInk.withAlpha(170),
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
              color: campusInk,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (isConfirmed && onNotificationsChanged != null) ...[
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Recibir anuncios',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: const Text('Avisos cuando el organizador publique.'),
              value: event.notificationsEnabled,
              onChanged: isUpdatingNotifications
                  ? null
                  : onNotificationsChanged,
            ),
          ],
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
                    : campusInk,
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
                color: campusInk.withAlpha(205),
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

class _ArchivedEventNotice extends StatelessWidget {
  const _ArchivedEventNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: campusAccent.withAlpha(150),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: campusInk.withAlpha(35)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.inventory_2_outlined, color: campusInk, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Este evento fue archivado por su ciclo de vida. Su informacion se conserva en tu historial.',
              style: TextStyle(
                color: campusInk,
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

class _CancelledEventNotice extends StatelessWidget {
  const _CancelledEventNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE9E5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF9B3A2A).withAlpha(80)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.event_busy_outlined, color: Color(0xFF7A2E22), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Este evento fue cancelado por su organizador y ya no está disponible como actividad.',
              style: TextStyle(
                color: campusInk,
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
    5 => campusInk,
    _ => campusInk,
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
        border: Border.all(color: campusInk.withAlpha(18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: campusInk, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: campusInk.withAlpha(170),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: campusInk,
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
