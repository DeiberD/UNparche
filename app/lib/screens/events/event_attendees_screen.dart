import 'package:flutter/material.dart';

import '../../services/event_api_client.dart';
import '../../models/confirmed_attendee.dart';
import '../../models/event_api_exception.dart';

class EventAttendeesScreen extends StatefulWidget {
  const EventAttendeesScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
    required this.eventApiClient,
  });

  final int eventId;
  final String eventTitle;
  final EventApiClient eventApiClient;

  @override
  State<EventAttendeesScreen> createState() => _EventAttendeesScreenState();
}

class _EventAttendeesScreenState extends State<EventAttendeesScreen> {
  late Future<List<ConfirmedAttendee>> _attendees;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    _attendees = widget.eventApiClient.fetchConfirmedAttendees(
      eventId: widget.eventId,
    );
  }

  Future<void> _reload() async {
    setState(_refresh);
    await _attendees;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF5F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF5F2),
        foregroundColor: const Color(0xFF263020),
        title: const Text(
          'Asistentes confirmados',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: FutureBuilder<List<ConfirmedAttendee>>(
        future: _attendees,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _MessageState(
              icon: Icons.error_outline,
              message: snapshot.error is EventApiException
                  ? (snapshot.error! as EventApiException).message
                  : 'No se pudieron cargar los asistentes.',
              actionLabel: 'Reintentar',
              onAction: () => setState(_refresh),
            );
          }
          final attendees = snapshot.data ?? const [];
          if (attendees.isEmpty) {
            return RefreshIndicator(
              onRefresh: _reload,
              child: const _MessageState(
                icon: Icons.group_off_outlined,
                message: 'No hay asistentes confirmados.',
                scrollable: true,
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
              itemCount: attendees.length + 1,
              separatorBuilder: (_, index) =>
                  SizedBox(height: index == 0 ? 14 : 8),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Text(
                    '${attendees.length} ${attendees.length == 1 ? 'persona confirmó' : 'personas confirmaron'} asistencia a ${widget.eventTitle}.',
                    style: const TextStyle(color: Color(0xFF263020)),
                  );
                }
                final attendee = attendees[index - 1];
                return Card(
                  child: ListTile(
                    leading: _Avatar(attendee: attendee, radius: 22),
                    title: Text(
                      attendee.name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      attendee.nickname == null
                          ? attendee.career ?? 'Perfil comunitario'
                          : '@${attendee.nickname}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            PublicAttendeeProfileScreen(attendee: attendee),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class PublicAttendeeProfileScreen extends StatelessWidget {
  const PublicAttendeeProfileScreen({super.key, required this.attendee});

  final ConfirmedAttendee attendee;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF5F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF5F2),
        foregroundColor: const Color(0xFF263020),
        title: const Text(
          'Perfil público',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(child: _Avatar(attendee: attendee, radius: 58)),
          const SizedBox(height: 18),
          Text(
            attendee.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Color(0xFF263020),
            ),
          ),
          if (attendee.nickname != null) ...[
            const SizedBox(height: 6),
            Text('@${attendee.nickname}', textAlign: TextAlign.center),
          ],
          const SizedBox(height: 24),
          _PublicField(
            icon: Icons.school_outlined,
            label: 'Carrera',
            value: attendee.career ?? 'No especificada',
          ),
          _PublicField(
            icon: Icons.info_outline,
            label: 'Información personal',
            value: attendee.personalInfo ?? 'Sin información pública.',
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.attendee, required this.radius});
  final ConfirmedAttendee attendee;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFF3ECE8),
      backgroundImage: attendee.profilePhoto == null
          ? null
          : NetworkImage(attendee.profilePhoto!),
      child: attendee.profilePhoto == null
          ? Icon(Icons.person, size: radius, color: const Color(0xFF263020))
          : null,
    );
  }
}

class _PublicField extends StatelessWidget {
  const _PublicField({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF263020)),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(value),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.scrollable = false,
  });
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final content = Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 52, color: const Color(0xFF263020)),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          if (onAction != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
    if (!scrollable) return content;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [SizedBox(height: 500, child: content)],
    );
  }
}
