import 'package:flutter/material.dart';

import '../../services/group_api_client.dart';
import '../../models/group_summary.dart';
import '../../models/group_invitation.dart';
import '../../models/group_api_exception.dart';
import '../../state/auth_state.dart';
import '../auth/login_screen.dart';
import 'create_group_screen.dart';
import '../../widgets/groups/group_list_tile.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key, this.groupApiClient});

  static const background = Color(0xFFFBF5F2);
  static const surface = Color(0xFFF3ECE8);
  static const ink = Color(0xFF263020);
  static const accent = Color(0xFFEEDDF0);
  static const allCategoriesFilter = '__ALL_CATEGORIES__';

  final GroupApiClient? groupApiClient;

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  late final GroupApiClient _groupApiClient;
  List<GroupSummary> _groups = const [];
  List<GroupInvitation> _invitations = const [];
  bool _isLoading = false;
  String? _errorMessage;
  String _query = '';
  GroupTypeFilter _typeFilter = GroupTypeFilter.all;
  String? _categoryFilter;
  bool _showOnlyMyGroups = true;

  @override
  void initState() {
    super.initState();
    _groupApiClient = widget.groupApiClient ?? GroupApiClient();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadGroups());
  }

  Future<void> _loadGroups() async {
    if (_isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = AuthProvider.of(context).value.currentUser?.id;
      if (userId == null) {
        throw const GroupApiException(
          'Inicia sesión para consultar tus grupos.',
        );
      }
      final results = await Future.wait([
        _groupApiClient.fetchGroups(userId: userId),
        _groupApiClient.fetchInvitations(userId: userId),
      ]);

      if (!mounted) {
        return;
      }

      final groups = results[0] as List<GroupSummary>;
      final invitations = results[1] as List<GroupInvitation>;
      setState(() {
        _groups = groups..sort((a, b) => a.name.compareTo(b.name));
        _invitations = invitations
            .where((invitation) => invitation.isPending)
            .toList();
      });
    } on GroupApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _errorMessage = error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(
        () => _errorMessage =
            'No se pudieron cargar los grupos. Revisa que el backend este corriendo.',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<GroupSummary> get _filteredGroups {
    return _groups
        .where(
          (group) => !_showOnlyMyGroups || group.isMember || group.isCreator,
        )
        .where(
          (group) => group.matches(
            query: _query,
            typeFilter: _typeFilter,
            categoryFilter: _categoryFilter,
          ),
        )
        .toList();
  }

  bool get _hasActiveFilters =>
      _query.trim().isNotEmpty ||
      _typeFilter != GroupTypeFilter.all ||
      _categoryFilter != null;

  Future<void> _openCreateGroup() async {
    final authState = AuthProvider.of(context).value;
    if (!authState.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Necesitas iniciar sesión para crear un grupo.'),
        ),
      );
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }

    final createdGroup = await Navigator.of(context).push<GroupSummary>(
      MaterialPageRoute(
        builder: (_) => CreateGroupScreen(groupApiClient: _groupApiClient),
      ),
    );

    if (createdGroup == null || !mounted) {
      return;
    }

    setState(() {
      _groups = [..._groups, createdGroup]
        ..sort((a, b) => a.name.compareTo(b.name));
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Grupo "${createdGroup.name}" creado.')),
    );
  }

  Future<void> _respondInvitation(
    GroupInvitation invitation,
    String status,
  ) async {
    final invitationId = invitation.id;
    if (invitationId == null) {
      return;
    }

    try {
      await _groupApiClient.respondInvitation(
        invitationId: invitationId,
        status: status,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _invitations = _invitations
            .where((item) => item.id != invitationId)
            .toList();
      });
      _loadGroups();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'ACEPTADA'
                ? 'Ahora perteneces a ${invitation.group.name}.'
                : 'Invitacion rechazada.',
          ),
        ),
      );
    } on GroupApiException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  void _clearFilters() {
    setState(() {
      _query = '';
      _typeFilter = GroupTypeFilter.all;
      _categoryFilter = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredGroups = _filteredGroups;

    return Container(
      color: GroupsScreen.background,
      child: RefreshIndicator(
        onRefresh: _loadGroups,
        color: GroupsScreen.ink,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 92, 16, 112),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Grupos',
                        style: TextStyle(
                          color: GroupsScreen.ink,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Colectivos oficiales y no oficiales del campus.',
                        style: TextStyle(
                          color: GroupsScreen.ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                FloatingActionButton.small(
                  heroTag: 'createGroup',
                  tooltip: 'Crear grupo',
                  backgroundColor: GroupsScreen.ink,
                  foregroundColor: Colors.white,
                  onPressed: _openCreateGroup,
                  child: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: true,
                  icon: Icon(Icons.person_outline),
                  label: Text('Mis grupos'),
                ),
                ButtonSegment(
                  value: false,
                  icon: Icon(Icons.explore_outlined),
                  label: Text('Explorar'),
                ),
              ],
              selected: {_showOnlyMyGroups},
              onSelectionChanged: (selection) {
                setState(() => _showOnlyMyGroups = selection.first);
              },
            ),
            const SizedBox(height: 12),
            _GroupSearchField(
              query: _query,
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 12),
            _GroupFiltersBar(
              typeFilter: _typeFilter,
              categoryFilter: _categoryFilter,
              hasActiveFilters: _hasActiveFilters,
              onTypeChanged: (value) => setState(() => _typeFilter = value),
              onCategoryChanged: (value) {
                setState(() => _categoryFilter = value);
              },
              onClear: _clearFilters,
            ),
            if (_invitations.isNotEmpty) ...[
              const SizedBox(height: 18),
              _InvitationsPanel(
                invitations: _invitations,
                onAccept: (invitation) {
                  _respondInvitation(invitation, 'ACEPTADA');
                },
                onReject: (invitation) {
                  _respondInvitation(invitation, 'RECHAZADA');
                },
              ),
            ],
            const SizedBox(height: 18),
            if (_errorMessage != null)
              _GroupStateMessage(
                icon: Icons.error_outline,
                title: 'No se pudo cargar grupos',
                message: _errorMessage!,
              )
            else if (!_isLoading && filteredGroups.isEmpty)
              const _GroupStateMessage(
                icon: Icons.groups_2_outlined,
                title: 'No hay grupos para mostrar',
                message: 'Prueba cambiar los filtros o crea un grupo nuevo.',
              )
            else
              ...filteredGroups.map(
                (group) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GroupListTile(
                    group: group,
                    onJoinPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Solo puedes unirte mediante invitacion de un miembro.',
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}



class _InvitationsPanel extends StatelessWidget {
  const _InvitationsPanel({
    required this.invitations,
    required this.onAccept,
    required this.onReject,
  });

  final List<GroupInvitation> invitations;
  final ValueChanged<GroupInvitation> onAccept;
  final ValueChanged<GroupInvitation> onReject;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GroupsScreen.accent.withAlpha(190),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: GroupsScreen.ink.withAlpha(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Invitaciones pendientes',
            style: TextStyle(
              color: GroupsScreen.ink,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          ...invitations.map(
            (invitation) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${invitation.inviterName} te invito a ${invitation.group.name}',
                      style: const TextStyle(
                        color: GroupsScreen.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Aceptar',
                    onPressed: () => onAccept(invitation),
                    icon: const Icon(Icons.check_circle_outline),
                  ),
                  IconButton(
                    tooltip: 'Rechazar',
                    onPressed: () => onReject(invitation),
                    icon: const Icon(Icons.cancel_outlined),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupSearchField extends StatelessWidget {
  const _GroupSearchField({required this.query, required this.onChanged});

  final String query;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: TextEditingController(text: query)
        ..selection = TextSelection.collapsed(offset: query.length),
      onChanged: onChanged,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withAlpha(238),
        prefixIcon: const Icon(Icons.search),
        hintText: 'Buscar por nombre o descripcion',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: GroupsScreen.ink.withAlpha(24)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: GroupsScreen.ink.withAlpha(24)),
        ),
      ),
    );
  }
}

class _GroupFiltersBar extends StatelessWidget {
  const _GroupFiltersBar({
    required this.typeFilter,
    required this.categoryFilter,
    required this.hasActiveFilters,
    required this.onTypeChanged,
    required this.onCategoryChanged,
    required this.onClear,
  });

  final GroupTypeFilter typeFilter;
  final String? categoryFilter;
  final bool hasActiveFilters;
  final ValueChanged<GroupTypeFilter> onTypeChanged;
  final ValueChanged<String?> onCategoryChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _GroupFilterChip(
            icon: Icons.verified_outlined,
            label: _typeLabel(typeFilter),
            selected: typeFilter != GroupTypeFilter.all,
            onPressed: () => _showTypeSheet(context),
          ),
          const SizedBox(width: 8),
          _GroupFilterChip(
            icon: Icons.category_outlined,
            label: categoryFilter == null
                ? 'Categoria'
                : groupCategoryLabel(categoryFilter!),
            selected: categoryFilter != null,
            onPressed: () => _showCategorySheet(context),
          ),
          if (hasActiveFilters) ...[
            const SizedBox(width: 8),
            _GroupFilterChip(
              icon: Icons.close,
              label: 'Limpiar',
              selected: true,
              onPressed: onClear,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showTypeSheet(BuildContext context) async {
    final selected = await showModalBottomSheet<GroupTypeFilter>(
      context: context,
      backgroundColor: GroupsScreen.background,
      builder: (_) => _FilterSheet(
        title: 'Tipo de grupo',
        children: [
          _FilterOption(
            icon: Icons.all_inclusive,
            label: 'Todos',
            onTap: () => Navigator.of(context).pop(GroupTypeFilter.all),
          ),
          _FilterOption(
            icon: Icons.verified_outlined,
            label: 'Oficiales',
            onTap: () => Navigator.of(context).pop(GroupTypeFilter.official),
          ),
          _FilterOption(
            icon: Icons.groups_2_outlined,
            label: 'No oficiales',
            onTap: () => Navigator.of(context).pop(GroupTypeFilter.unofficial),
          ),
        ],
      ),
    );

    if (selected != null) {
      onTypeChanged(selected);
    }
  }

  Future<void> _showCategorySheet(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: GroupsScreen.background,
      builder: (_) => _FilterSheet(
        title: 'Categoria',
        children: [
          _FilterOption(
            icon: Icons.clear,
            label: 'Todas',
            onTap: () =>
                Navigator.of(context).pop(GroupsScreen.allCategoriesFilter),
          ),
          ...groupCategories.map(
            (category) => _FilterOption(
              icon: getGroupCategoryIcon(category),
              label: groupCategoryLabel(category),
              onTap: () => Navigator.of(context).pop(category),
            ),
          ),
        ],
      ),
    );

    if (selected == null) {
      return;
    }

    onCategoryChanged(
      selected == GroupsScreen.allCategoriesFilter ? null : selected,
    );
  }
}

class _GroupFilterChip extends StatelessWidget {
  const _GroupFilterChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? GroupsScreen.ink : Colors.white.withAlpha(238),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? GroupsScreen.ink
                  : GroupsScreen.ink.withAlpha(24),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? Colors.white : GroupsScreen.ink,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : GroupsScreen.ink,
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

class _FilterSheet extends StatelessWidget {
  const _FilterSheet({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: GroupsScreen.ink,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _FilterOption extends StatelessWidget {
  const _FilterOption({
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
      leading: Icon(icon, color: GroupsScreen.ink),
      title: Text(
        label,
        style: const TextStyle(
          color: GroupsScreen.ink,
          fontWeight: FontWeight.w700,
        ),
      ),
      onTap: onTap,
    );
  }
}

class _GroupStateMessage extends StatelessWidget {
  const _GroupStateMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(238),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: GroupsScreen.ink.withAlpha(20)),
      ),
      child: Column(
        children: [
          Icon(icon, color: GroupsScreen.ink, size: 34),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: GroupsScreen.ink,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: GroupsScreen.ink.withAlpha(170),
              fontSize: 13,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}



String _typeLabel(GroupTypeFilter type) {
  return switch (type) {
    GroupTypeFilter.all => 'Tipo',
    GroupTypeFilter.official => 'Oficiales',
    GroupTypeFilter.unofficial => 'No oficiales',
  };
}


