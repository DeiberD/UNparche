import 'package:flutter/material.dart';
import '../../models/event_summary.dart';
import '../../theme/campus_colors.dart';
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

