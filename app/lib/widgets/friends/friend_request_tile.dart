import 'package:flutter/material.dart';
import '../../models/friend_request.dart';

class FriendRequestTile extends StatelessWidget {
  const FriendRequestTile({
    super.key,
    required this.request,
    required this.onAccept,
    required this.onReject,
    this.isProcessing = false,
  });

  final FriendRequest request;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final bool isProcessing;

  @override
  Widget build(BuildContext context) {
    final photoUrl = request.requesterPhoto?.trim();

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        backgroundImage: photoUrl != null && photoUrl.isNotEmpty
            ? NetworkImage(photoUrl)
            : null,
        child: photoUrl == null || photoUrl.isEmpty
            ? Text(_initials(request.requesterName))
            : null,
      ),
      title: Text(
        request.requesterName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: _buildSubtitle(),
      trailing: isProcessing
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Rechazar solicitud',
                  onPressed: onReject,
                  icon: const Icon(Icons.close),
                ),
                IconButton(
                  tooltip: 'Aceptar solicitud',
                  onPressed: onAccept,
                  icon: const Icon(Icons.check),
                ),
              ],
            ),
    );
  }

  Widget _buildSubtitle() {
    final career = request.requesterCareer?.trim();

    if (career != null && career.isNotEmpty) {
      return Text(career, maxLines: 1, overflow: TextOverflow.ellipsis);
    }

    return Text(
      request.requesterEmail,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  String _initials(String fullName) {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return '?';
    }

    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
