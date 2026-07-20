import 'package:flutter/material.dart';

import '../../models/event_summary.dart';
import '../../services/event_api_client.dart';
import '../../theme/campus_colors.dart';
import '../../widgets/events/event_list_tile.dart';
import 'event_detail_screen.dart';

typedef AttendanceHistoryLoader = Future<List<EventSummary>> Function(
  int userId,
);

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({
    super.key,
    required this.currentUserId,
    this.eventApiClient,
    this.historyLoader,
  });

  final int currentUserId;
  final EventApiClient? eventApiClient;
  final AttendanceHistoryLoader? historyLoader;

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  late final EventApiClient _eventApiClient;
  late Future<List<EventSummary>> _history;

  @override
  void initState() {
    super.initState();
    _eventApiClient = widget.eventApiClient ?? EventApiClient();
    _history = _loadHistory();
  }

  Future<List<EventSummary>> _loadHistory() {
    final loader = widget.historyLoader;
    if (loader != null) {
      return loader(widget.currentUserId);
    }
    return _eventApiClient.fetchAttendanceHistory(
      userId: widget.currentUserId,
    );
  }

  Future<void> _refresh() async {
    final nextHistory = _loadHistory();
    setState(() => _history = nextHistory);
    await nextHistory;
  }

  Future<void> _openDetails(EventSummary event) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => EventDetailScreen(
          event: event,
          eventApiClient: _eventApiClient,
          currentUserId: widget.currentUserId,
          onAttendanceChanged: (_) {},
          onDeleted: (_) {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: campusBackground,
      appBar: AppBar(
        backgroundColor: campusBackground,
        foregroundColor: campusInk,
        title: const Text(
          'Historial de eventos',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: FutureBuilder<List<EventSummary>>(
        future: _history,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _HistoryState(
              icon: Icons.error_outline,
              title: 'No se pudo cargar el historial',
              message: 'Revisa tu conexion e intenta nuevamente.',
              onRetry: _refresh,
            );
          }

          final events = snapshot.data ?? const [];
          if (events.isEmpty) {
            return const _HistoryState(
              icon: Icons.history,
              title: 'No hay eventos en tu historial',
              message:
                  'Los eventos pasados a los que hayas asistido apareceran aqui.',
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            color: campusInk,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              itemCount: events.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Text(
                    '${events.length} ${events.length == 1 ? 'evento recordado' : 'eventos recordados'}',
                    style: TextStyle(
                      color: campusInk.withAlpha(175),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  );
                }

                final event = events[index - 1];
                return EventListTile(
                  event: event,
                  onTap: () => _openDetails(event),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _HistoryState extends StatelessWidget {
  const _HistoryState({
    required this.icon,
    required this.title,
    required this.message,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String message;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: campusInk, size: 42),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: campusInk,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: campusInk.withAlpha(170), height: 1.35),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
