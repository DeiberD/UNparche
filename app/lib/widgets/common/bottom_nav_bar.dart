import 'package:flutter/material.dart';

import '../../theme/campus_colors.dart';

enum HomeTab { map, events, groups, friends }

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({
    super.key,
    required this.selectedTab,
    required this.onTabSelected,
  });

  final HomeTab selectedTab;
  final ValueChanged<HomeTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: campusSurface.withAlpha(246),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: campusInk.withAlpha(20),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          BottomNavItem(
            icon: Icons.map_outlined,
            label: 'Mapa',
            selected: selectedTab == HomeTab.map,
            onPressed: () => onTabSelected(HomeTab.map),
          ),
          BottomNavItem(
            icon: Icons.event_outlined,
            label: 'Eventos',
            selected: selectedTab == HomeTab.events,
            onPressed: () => onTabSelected(HomeTab.events),
          ),
          BottomNavItem(
            icon: Icons.groups_outlined,
            label: 'Grupos',
            selected: selectedTab == HomeTab.groups,
            onPressed: () => onTabSelected(HomeTab.groups),
          ),
          BottomNavItem(
            icon: Icons.person_outline,
            label: 'Amigos',
            selected: selectedTab == HomeTab.friends,
            onPressed: () => onTabSelected(HomeTab.friends),
          ),
        ],
      ),
    );
  }
}

class BottomNavItem extends StatelessWidget {
  const BottomNavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected ? campusInk : campusInk.withAlpha(170);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onPressed,
      child: Container(
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: selected ? campusAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 21),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
