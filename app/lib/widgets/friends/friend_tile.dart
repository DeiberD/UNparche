import 'package:flutter/material.dart';
import '../../models/user.dart';

class FriendTile extends StatelessWidget {
  const FriendTile({
    super.key,
    required this.friend,
    this.onTap,
    this.onDelete,
  });

  final User friend;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final fullName = '${friend.nombre} ${friend.apellido}'.trim();
    final photoUrl = friend.fotoPerfil?.trim();

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        backgroundImage: photoUrl != null && photoUrl.isNotEmpty
            ? NetworkImage(photoUrl)
            : null,
        child: photoUrl == null || photoUrl.isEmpty
            ? Text(_initials(friend.nombre, friend.apellido))
            : null,
      ),
      title: Text(fullName, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: _buildSubtitle(),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.person_remove, color: Colors.red),
              onPressed: onDelete,
              tooltip: 'Eliminar amigo',
            ),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget? _buildSubtitle() {
    final career = friend.carrera?.trim();

    if (career != null && career.isNotEmpty) {
      return Text(career, maxLines: 1, overflow: TextOverflow.ellipsis);
    }

    if (friend.correoInstitucional.isNotEmpty) {
      return Text(
        friend.correoInstitucional,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    return null;
  }

  String _initials(String firstName, String lastName) {
    final firstInitial = firstName.trim().isNotEmpty ? firstName.trim()[0] : '';

    final lastInitial = lastName.trim().isNotEmpty ? lastName.trim()[0] : '';

    final initials = '$firstInitial$lastInitial'.toUpperCase();

    return initials.isEmpty ? '?' : initials;
  }
}
