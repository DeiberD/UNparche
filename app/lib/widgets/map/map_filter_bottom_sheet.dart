import 'package:flutter/material.dart';
import '../../models/event_filters.dart';
import '../events/event_helpers.dart';

import '../../theme/campus_colors.dart';

class EventTypeFilterSheet extends StatelessWidget {
  const EventTypeFilterSheet();

  static const _types = [
    (id: 1, label: 'Academico', icon: Icons.school_outlined),
    (id: 2, label: 'Cultural', icon: Icons.palette_outlined),
    (id: 3, label: 'Deportivo', icon: Icons.sports_soccer_outlined),
    (id: 4, label: 'Social', icon: Icons.celebration_outlined),
    (id: 5, label: 'Otro', icon: Icons.more_horiz),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filtrar por categoria',
              style: TextStyle(
                color: campusInk,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            _FilterSheetOption(
              icon: Icons.clear,
              label: 'Todas las categorias',
              onTap: () => Navigator.of(context).pop(null),
            ),
            ..._types.map(
              (type) => _FilterSheetOption(
                icon: type.icon,
                label: type.label,
                onTap: () => Navigator.of(context).pop(type.id),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GroupFilterSheet extends StatelessWidget {
  const GroupFilterSheet({required this.groupIds});

  final List<int> groupIds;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filtrar por grupo',
              style: TextStyle(
                color: campusInk,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            _FilterSheetOption(
              icon: Icons.clear,
              label: 'Todos los grupos',
              onTap: () => Navigator.of(context).pop(null),
            ),
            if (groupIds.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No hay grupos disponibles en los eventos actuales.',
                  style: TextStyle(
                    color: campusInk,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              ...groupIds.map(
                (groupId) => _FilterSheetOption(
                  icon: Icons.groups_outlined,
                  label: 'Grupo $groupId',
                  onTap: () => Navigator.of(context).pop(groupId),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FilterSheetOption extends StatelessWidget {
  const _FilterSheetOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: campusInk),
      title: Text(
        label,
        style: const TextStyle(color: campusInk, fontWeight: FontWeight.w700),
      ),
      onTap: onTap,
    );
  }
}

class EventFiltersBar extends StatelessWidget {
  const EventFiltersBar({
    super.key,
    required this.filters,
    required this.onDatePressed,
    required this.onTypePressed,
    required this.onGroupPressed,
    required this.onClearPressed,
  });

  final EventFilters filters;
  final VoidCallback onDatePressed;
  final VoidCallback onTypePressed;
  final VoidCallback onGroupPressed;
  final VoidCallback? onClearPressed;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          FilterChipMock(
            icon: Icons.tune,
            label: filters.eventTypeId == null
                ? 'Categoria'
                : eventTypeLabel(filters.eventTypeId),
            selected: filters.eventTypeId != null,
            onPressed: onTypePressed,
          ),
          const SizedBox(width: 8),
          FilterChipMock(
            icon: Icons.calendar_today,
            label: filters.date == null
                ? 'Fecha'
                : shortEventDate(filters.date!),
            selected: filters.date != null,
            onPressed: onDatePressed,
          ),
          const SizedBox(width: 8),
          FilterChipMock(
            icon: Icons.group,
            label: filters.groupId == null
                ? 'Grupo'
                : 'Grupo ${filters.groupId}',
            selected: filters.groupId != null,
            onPressed: onGroupPressed,
          ),
          if (onClearPressed != null) ...[
            const SizedBox(width: 8),
            FilterChipMock(
              icon: Icons.close,
              label: 'Limpiar',
              selected: true,
              onPressed: onClearPressed!,
            ),
          ],
        ],
      ),
    );
  }
}

class FilterChipMock extends StatelessWidget {
  const FilterChipMock({
    super.key,
    required this.icon,
    required this.label,
    this.selected = false,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? campusInk : Colors.white.withAlpha(238),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? campusInk : campusInk.withAlpha(24),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: selected ? Colors.white : campusInk),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : campusInk,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
