import 'package:flutter/material.dart';

import 'event_api_client.dart';

class EventsListView extends StatelessWidget {
  const EventsListView({
    super.key,
    required this.events,
    required this.isLoading,
    required this.errorMessage,
    required this.onRefresh,
    required this.onEventTap,
  });

  static const background = Color(0xFFFBF5F2);
  static const surface = Color(0xFFF3ECE8);
  static const ink = Color(0xFF263020);

  final List<EventSummary> events;
  final bool isLoading;
  final String? errorMessage;
  final Future<void> Function() onRefresh;
  final ValueChanged<EventSummary> onEventTap;

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
            if (errorMessage != null)
              _ListStateMessage(
                icon: Icons.error_outline,
                title: 'No se pudo cargar la lista',
                message: errorMessage!,
              )
            else if (!isLoading && events.isEmpty)
              const _ListStateMessage(
                icon: Icons.event_busy_outlined,
                title: 'No hay eventos disponibles',
                message: 'Cuando existan eventos publicos, apareceran aqui.',
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

class EventListTile extends StatelessWidget {
  const EventListTile({super.key, required this.event, required this.onTap});

  final EventSummary event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
                      event.title,
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

class EventDetailScreen extends StatelessWidget {
  const EventDetailScreen({super.key, required this.event});

  final EventSummary event;

  @override
  Widget build(BuildContext context) {
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
                    event.title,
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
              icon: Icons.schedule,
              title: 'Inicio',
              value: formatEventStart(event.start),
            ),
            _DetailInfoRow(
              icon: Icons.timer_outlined,
              title: 'Duracion',
              value: event.durationMinutes == null
                  ? 'Por confirmar'
                  : '${event.durationMinutes} minutos',
            ),
            _DetailInfoRow(
              icon: Icons.group_outlined,
              title: 'Grupo organizador',
              value: event.groupId == null
                  ? 'Sin grupo'
                  : 'Grupo ${event.groupId}',
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 54,
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
          ],
        ),
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
            child: Text(
              title,
              style: TextStyle(
                color: EventsListView.ink.withAlpha(170),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: EventsListView.ink,
              fontWeight: FontWeight.w800,
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
