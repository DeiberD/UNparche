import 'package:flutter/material.dart';

import '../../models/event_announcement.dart';
import '../../models/event_api_exception.dart';
import '../../services/event_api_client.dart';
import '../../theme/campus_colors.dart';

typedef AnnouncementLoader = Future<List<EventAnnouncement>> Function();
typedef AnnouncementPublisher =
    Future<EventAnnouncement> Function(String content);

/// Presents the announcements for one event and exposes publishing only when
/// the current user is its organizer.
class EventAnnouncementsSection extends StatefulWidget {
  const EventAnnouncementsSection({
    super.key,
    required this.eventId,
    required this.currentUserId,
    required this.canPublish,
    required this.eventApiClient,
    this.loader,
    this.publisher,
  });

  final int eventId;
  final int currentUserId;
  final bool canPublish;
  final EventApiClient eventApiClient;
  final AnnouncementLoader? loader;
  final AnnouncementPublisher? publisher;

  @override
  State<EventAnnouncementsSection> createState() =>
      _EventAnnouncementsSectionState();
}

class _EventAnnouncementsSectionState extends State<EventAnnouncementsSection> {
  List<EventAnnouncement> _announcements = const [];
  bool _isLoading = true;
  bool _isPublishing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final announcements =
          await (widget.loader?.call() ??
              widget.eventApiClient.fetchAnnouncements(
                eventId: widget.eventId,
              ));
      if (!mounted) return;
      setState(() => _announcements = announcements);
    } on EventApiException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'No se pudieron cargar los anuncios.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openPublishDialog() async {
    var draft = '';
    final content = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Publicar anuncio'),
        content: TextField(
          autofocus: true,
          maxLength: 1000,
          minLines: 3,
          maxLines: 6,
          onChanged: (value) => draft = value,
          decoration: const InputDecoration(
            hintText: 'Escribe el cambio o novedad del evento',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final value = draft.trim();
              if (value.isNotEmpty) Navigator.of(dialogContext).pop(value);
            },
            child: const Text('Publicar'),
          ),
        ],
      ),
    );
    if (content == null || !mounted) return;

    setState(() => _isPublishing = true);
    try {
      final announcement =
          await (widget.publisher?.call(content) ??
              widget.eventApiClient.publishAnnouncement(
                eventId: widget.eventId,
                authorId: widget.currentUserId,
                content: content,
              ));
      if (!mounted) return;
      setState(() => _announcements = [announcement, ..._announcements]);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Anuncio publicado.')));
    } on EventApiException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('No se pudo publicar el anuncio.');
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.campaign_outlined, color: campusInk),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Anuncios',
                style: TextStyle(
                  color: campusInk,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (widget.canPublish)
              IconButton.filled(
                tooltip: 'Publicar anuncio',
                onPressed: _isPublishing ? null : _openPublishDialog,
                icon: _isPublishing
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_errorMessage != null)
          _AnnouncementMessage(
            icon: Icons.cloud_off_outlined,
            message: _errorMessage!,
            action: IconButton(
              tooltip: 'Reintentar',
              onPressed: _loadAnnouncements,
              icon: const Icon(Icons.refresh),
            ),
          )
        else if (_announcements.isEmpty)
          const _AnnouncementMessage(
            icon: Icons.notifications_none_outlined,
            message: 'Este evento aun no tiene anuncios.',
          )
        else
          ..._announcements.map(_AnnouncementCard.new),
      ],
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard(this.announcement);

  final EventAnnouncement announcement;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(238),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: campusInk.withAlpha(18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            announcement.content,
            style: const TextStyle(color: campusInk, height: 1.35),
          ),
          const SizedBox(height: 10),
          Text(
            '${announcement.authorLabel} | ${_formatPublishedAt(announcement.publishedAt)}',
            style: TextStyle(
              color: campusInk.withAlpha(150),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnnouncementMessage extends StatelessWidget {
  const _AnnouncementMessage({
    required this.icon,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: campusSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: campusInk.withAlpha(18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: campusInk.withAlpha(170)),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
          action ?? const SizedBox.shrink(),
        ],
      ),
    );
  }
}

String _formatPublishedAt(DateTime? date) {
  if (date == null) return 'Fecha no disponible';
  final local = date.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month/${local.year} $hour:$minute';
}
