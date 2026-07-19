import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/event_api_client.dart';
import '../../models/event_summary.dart';
import '../../models/event_api_exception.dart';
import '../../state/auth_state.dart';
import '../../flutter_chat/chat_message.dart';
import '../../flutter_chat/chat_socket_client.dart';
// TODO: clean up imports
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

