import 'package:flutter/material.dart';
import '../../models/group_summary.dart';

class GroupListTile extends StatelessWidget {
  const GroupListTile({
    super.key,
    required this.group,
    required this.onJoinPressed,
  });

  final GroupSummary group;
  final VoidCallback onJoinPressed;

  static const ink = Color(0xFF263020);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withAlpha(242),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: ink.withAlpha(20)),
          boxShadow: [
            BoxShadow(
              color: ink.withAlpha(12),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: getGroupCategoryColor(group.category).withAlpha(38),
                  child: Icon(
                    getGroupCategoryIcon(group.category),
                    color: getGroupCategoryColor(group.category),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              group.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: ink,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (group.isOfficial) ...[
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.verified,
                              color: Color(0xFF4267B2),
                              size: 18,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${group.categoryLabel} · ${group.isOfficial ? 'Oficial' : 'No oficial'}',
                        style: TextStyle(
                          color: ink.withAlpha(180),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              group.description.isEmpty
                  ? 'Este grupo aun no tiene descripcion.'
                  : group.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: ink.withAlpha(165),
                fontSize: 12,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.people_alt_outlined,
                  size: 16,
                  color: ink.withAlpha(170),
                ),
                const SizedBox(width: 5),
                Text(
                  '${group.memberCount} integrantes',
                  style: TextStyle(
                    color: ink.withAlpha(170),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (group.isCreator)
                  const Chip(
                    avatar: Icon(Icons.admin_panel_settings_outlined, size: 16),
                    label: Text('Creado por ti'),
                  )
                else if (group.isMember)
                  const Chip(
                    avatar: Icon(Icons.check_circle_outline, size: 16),
                    label: Text('Eres miembro'),
                  )
                else
                  TextButton.icon(
                    onPressed: onJoinPressed,
                    icon: const Icon(Icons.lock_outline, size: 16),
                    label: const Text('Por invitacion'),
                    style: TextButton.styleFrom(
                      foregroundColor: ink,
                      textStyle: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

IconData getGroupCategoryIcon(String category) {
  return switch (category) {
    'ACADEMICO' => Icons.school_outlined,
    'CULTURAL' => Icons.palette_outlined,
    'SOCIAL' => Icons.celebration_outlined,
    'DEPORTIVO' => Icons.sports_soccer_outlined,
    _ => Icons.more_horiz,
  };
}

Color getGroupCategoryColor(String category) {
  return switch (category) {
    'ACADEMICO' => const Color(0xFF4267B2),
    'CULTURAL' => const Color(0xFF8B4C9D),
    'SOCIAL' => const Color(0xFFC2410C),
    'DEPORTIVO' => const Color(0xFF2E7D32),
    _ => const Color(0xFF263020),
  };
}
