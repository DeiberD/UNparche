import 'package:flutter/material.dart';

import 'group_api_client.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key, this.groupApiClient});

  static const background = Color(0xFFFBF5F2);
  static const surface = Color(0xFFF3ECE8);
  static const ink = Color(0xFF263020);
  static const accent = Color(0xFFEEDDF0);
  static const demoUserId = 1;
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

  @override
  void initState() {
    super.initState();
    _groupApiClient = widget.groupApiClient ?? GroupApiClient();
    _loadGroups();
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
      final results = await Future.wait([
        _groupApiClient.fetchGroups(),
        _groupApiClient.fetchInvitations(userId: GroupsScreen.demoUserId),
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

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key, this.groupApiClient});

  final GroupApiClient? groupApiClient;

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _category = groupCategories.first;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveGroup() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || _isSaving) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final client = widget.groupApiClient ?? GroupApiClient();
      final group = await client.createGroup(
        CreateGroupRequest(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _category,
          adminId: GroupsScreen.demoUserId,
        ),
      );

      if (mounted) {
        Navigator.of(context).pop(group);
      }
    } on GroupApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo conectar con la API.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GroupsScreen.background,
      appBar: AppBar(
        backgroundColor: GroupsScreen.background,
        foregroundColor: GroupsScreen.ink,
        title: const Text(
          'Nuevo grupo',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: GroupsScreen.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: GroupsScreen.ink.withAlpha(24)),
                ),
                child: const Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: GroupsScreen.accent,
                      child: Icon(Icons.groups_2_outlined),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Los grupos creados aqui son no oficiales y quedan sin sello de verificacion.',
                        style: TextStyle(
                          color: GroupsScreen.ink,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del grupo',
                  hintText: 'Ej. Club de lectura UNAL',
                ),
                maxLength: 80,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre es obligatorio.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripcion',
                  hintText: 'Cuenta que hace el colectivo',
                ),
                maxLength: 180,
                minLines: 4,
                maxLines: 5,
              ),
              const SizedBox(height: 16),
              const _SectionTitle('Categoria'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: groupCategories.map((category) {
                  final selected = _category == category;
                  return ChoiceChip(
                    label: Text(groupCategoryLabel(category)),
                    selected: selected,
                    selectedColor: GroupsScreen.ink,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : GroupsScreen.ink,
                      fontWeight: FontWeight.w700,
                    ),
                    onSelected: (_) => setState(() => _category = category),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 54,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _saveGroup,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Icon(Icons.add),
                  label: Text(_isSaving ? 'Creando...' : 'Crear grupo'),
                  style: FilledButton.styleFrom(
                    backgroundColor: GroupsScreen.ink,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontWeight: FontWeight.w800),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GroupListTile extends StatelessWidget {
  const GroupListTile({
    super.key,
    required this.group,
    required this.onJoinPressed,
  });

  final GroupSummary group;
  final VoidCallback onJoinPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withAlpha(242),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: GroupsScreen.ink.withAlpha(20)),
          boxShadow: [
            BoxShadow(
              color: GroupsScreen.ink.withAlpha(12),
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
                  backgroundColor: _categoryColor(group.category).withAlpha(38),
                  child: Icon(
                    _categoryIcon(group.category),
                    color: _categoryColor(group.category),
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
                                color: GroupsScreen.ink,
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
                          color: GroupsScreen.ink.withAlpha(180),
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
                color: GroupsScreen.ink.withAlpha(165),
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
                  color: GroupsScreen.ink.withAlpha(170),
                ),
                const SizedBox(width: 5),
                Text(
                  '${group.memberCount} integrantes',
                  style: TextStyle(
                    color: GroupsScreen.ink.withAlpha(170),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: onJoinPressed,
                  icon: const Icon(Icons.lock_outline, size: 16),
                  label: const Text('Por invitacion'),
                  style: TextButton.styleFrom(
                    foregroundColor: GroupsScreen.ink,
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
              icon: _categoryIcon(category),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: GroupsScreen.ink,
        fontWeight: FontWeight.w800,
        fontSize: 15,
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

IconData _categoryIcon(String category) {
  return switch (category) {
    'ACADEMICO' => Icons.school_outlined,
    'CULTURAL' => Icons.palette_outlined,
    'SOCIAL' => Icons.celebration_outlined,
    'DEPORTIVO' => Icons.sports_soccer_outlined,
    _ => Icons.more_horiz,
  };
}

Color _categoryColor(String category) {
  return switch (category) {
    'ACADEMICO' => const Color(0xFF4267B2),
    'CULTURAL' => const Color(0xFF8B4C9D),
    'SOCIAL' => const Color(0xFFC2410C),
    'DEPORTIVO' => const Color(0xFF2E7D32),
    _ => GroupsScreen.ink,
  };
}
