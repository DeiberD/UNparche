import 'package:flutter/material.dart';
import '../../theme/campus_colors.dart';
import '../../widgets/events/event_helpers.dart';
import '../../models/event_summary.dart';

class EventOrganizerDetailScreen extends StatelessWidget {
  const EventOrganizerDetailScreen({super.key, required this.event});

  final EventSummary event;

  @override
  Widget build(BuildContext context) {
    final isGroup = event.belongsToGroup;
    return Scaffold(
      backgroundColor: campusBackground,
      appBar: AppBar(
        backgroundColor: campusBackground,
        foregroundColor: campusInk,
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
                color: campusSurface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: campusInk.withAlpha(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: eventColor(
                      event.eventTypeId,
                    ).withAlpha(36),
                    child: Icon(
                      isGroup ? Icons.groups_outlined : Icons.person_outline,
                      color: eventColor(event.eventTypeId),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    isGroup
                        ? event.groupName ?? 'Grupo sin nombre'
                        : event.organizerName ?? 'Usuario sin nombre publico',
                    style: const TextStyle(
                      color: campusInk,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isGroup ? groupSubtitle(event) : userSubtitle(event),
                    style: TextStyle(
                      color: campusInk.withAlpha(175),
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
                      color: campusInk.withAlpha(190),
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
                value: titleCaseOrFallback(
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
                value: titleCaseOrFallback(
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

class OrganizerCard extends StatelessWidget {
  const OrganizerCard({required this.event});

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
            border: Border.all(color: campusInk.withAlpha(18)),
          ),
          child: Row(
            children: [
              Icon(
                isGroup ? Icons.groups_outlined : Icons.person_outline,
                color: campusInk,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isGroup ? 'Grupo organizador' : 'Usuario organizador',
                      style: TextStyle(
                        color: campusInk.withAlpha(165),
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
                        color: campusInk,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: campusInk),
            ],
          ),
        ),
      ),
    );
  }
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
