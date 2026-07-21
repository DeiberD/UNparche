import 'package:flutter/material.dart';
import '../../state/auth_state.dart';
import '../../main.dart';
import '../../services/group_api_client.dart';
import '../../services/event_api_client.dart';
import '../../models/group_summary.dart';
import '../../models/event_summary.dart';
import '../events/attendance_history_screen.dart';
import '../groups/group_members_screen.dart';
import '../events/event_detail_screen.dart';

/// User profile screen
///
/// Displays user profile information including:
/// - Profile photo with edit option
/// - User name and biography
/// - Edit profile button
/// - User's groups list
/// - Upcoming events list
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  // Colors consistent with the rest of the application
  static const _background = Color(0xFFFBF5F2);
  static const _surface = Color(0xFFF3ECE8);
  static const _ink = Color(0xFF263020);
  static const _accent = Color(0xFFEEDDF0);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  /// Muestra un diálogo para editar nombre, apellido, carrera e información personal.
  /// Patrón: Dialog + async mutation a través del estado global (AuthNotifier).
  void _showEditProfileDialog(BuildContext context) {
    final authNotifier = AuthProvider.of(context);
    final user = authNotifier.value.currentUser;

    final nameCtrl = TextEditingController(text: user?.nombre ?? '');
    final lastNameCtrl = TextEditingController(text: user?.apellido ?? '');
    final nicknameCtrl = TextEditingController(text: user?.nickname ?? '');
    final carreraCtrl = TextEditingController(text: user?.carrera ?? '');
    final infoCtrl = TextEditingController(
      text: user?.informacionPersonal ?? '',
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Editar Perfil'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: lastNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Apellido',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nicknameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nickname',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: carreraCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Carrera',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: infoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Información personal',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ProfileScreen._ink,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(dialogCtx);
              try {
                await authNotifier.updateProfile({
                  'nombre': nameCtrl.text.trim(),
                  'apellido': lastNameCtrl.text.trim(),
                  'nickname': nicknameCtrl.text.trim().isEmpty
                      ? null
                      : nicknameCtrl.text.trim(),
                  'carrera': carreraCtrl.text.trim(),
                  'informacion_personal': infoCtrl.text.trim(),
                });
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Perfil actualizado.')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Error: ${e.toString().replaceAll("Exception: ", "")}',
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProfileScreen._background,
      appBar: AppBar(
        backgroundColor: ProfileScreen._background,
        foregroundColor: ProfileScreen._ink,
        title: const Text(
          'Perfil',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthProvider.of(context).logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AuthGate()),
                  (route) => false,
                );
              }
            },
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          children: [
            // Profile section
            const _ProfileHeader(),
            const SizedBox(height: 24),

            // Edit profile button
            _EditProfileButton(
              onPressed: () => _showEditProfileDialog(context),
            ),
            const SizedBox(height: 32),

            // Groups section
            const _SectionTitle(title: 'Mis Grupos'),
            const SizedBox(height: 12),
            const _GroupsList(),
            const SizedBox(height: 32),

            // Upcoming events section
            const _SectionTitle(title: 'Próximos Eventos'),
            const SizedBox(height: 12),
            const _UpcomingEventsList(),
            const SizedBox(height: 32),

            const _SectionTitle(title: 'Historial'),
            const SizedBox(height: 12),
            _HistoryEntry(
              onPressed: () {
                final user = AuthProvider.of(context).value.currentUser;
                if (user == null) return;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AttendanceHistoryScreen(
                      currentUserId: user.id,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryEntry extends StatelessWidget {
  const _HistoryEntry({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withAlpha(242),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: const Row(
            children: [
              Icon(Icons.history, color: ProfileScreen._ink),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Eventos asistidos',
                      style: TextStyle(
                        color: ProfileScreen._ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Consulta las actividades pasadas que confirmaste.',
                      style: TextStyle(
                        color: ProfileScreen._ink,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: ProfileScreen._ink),
            ],
          ),
        ),
      ),
    );
  }
}

/// Profile header widget with photo, name and biography
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    final authState = AuthProvider.of(context).value;
    final user = authState.currentUser;
    final fullName = user != null
        ? '${user.nombre} ${user.apellido}'
        : 'Cargando...';
    final nickname = user?.nickname;
    final email = user?.correoInstitucional ?? '';
    final carrera = user?.carrera ?? '';
    final info = user?.informacionPersonal ?? 'Agrega información personal.';

    return Column(
      children: [
        // Profile photo with edit button
        Stack(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ProfileScreen._surface,
                border: Border.all(
                  color: ProfileScreen._ink.withAlpha(30),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: ProfileScreen._ink.withAlpha(15),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipOval(
                child: user?.fotoPerfil != null
                    ? Image.network(user!.fotoPerfil!, fit: BoxFit.cover)
                    : const Icon(
                        Icons.person,
                        size: 60,
                        color: ProfileScreen._ink,
                      ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: ProfileScreen._ink,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ProfileScreen._background,
                    width: 3,
                  ),
                ),
                child: const Icon(Icons.edit, size: 18, color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // User name
        Text(
          fullName,
          style: const TextStyle(
            color: ProfileScreen._ink,
            fontSize: 26,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),

        if (nickname != null && nickname.trim().isNotEmpty) ...[
          Text(
            '@${nickname.trim()}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: ProfileScreen._ink,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
        ],

        // User biography
        Text(
          email,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: ProfileScreen._ink.withAlpha(180),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          carrera.isNotEmpty ? carrera : 'Carrera no especificada',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: ProfileScreen._ink.withAlpha(150),
            fontSize: 13,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          info,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: ProfileScreen._ink.withAlpha(150),
            fontSize: 13,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

/// Button to edit profile
class _EditProfileButton extends StatelessWidget {
  const _EditProfileButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: ProfileScreen._ink,
          side: BorderSide(color: ProfileScreen._ink.withAlpha(100), width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: const Text(
          'Edit Profile',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
      ),
    );
  }
}

/// Section title widget
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: ProfileScreen._ink,
        fontSize: 22,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

/// User's groups list
class _GroupsList extends StatefulWidget {
  const _GroupsList();

  @override
  State<_GroupsList> createState() => _GroupsListState();
}

class _GroupsListState extends State<_GroupsList> {
  final _client = GroupApiClient();
  Future<List<GroupSummary>>? _groups;

  void _refresh() {
    setState(() {
      _groups = _client
        .fetchGroups(userId: AuthProvider.of(context).value.currentUser!.id)
        .then(
          (groups) => groups
              .where((group) => group.isMember || group.isCreator)
              .toList(),
        );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _groups ??= _client
        .fetchGroups(userId: AuthProvider.of(context).value.currentUser!.id)
        .then(
          (groups) => groups
              .where((group) => group.isMember || group.isCreator)
              .toList(),
        );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<GroupSummary>>(
      future: _groups,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final groups = snapshot.data ?? const [];
        if (snapshot.hasError || groups.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(238),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              snapshot.hasError
                  ? 'No se pudieron cargar tus grupos.'
                  : 'Todavia no perteneces a ningun grupo.',
            ),
          );
        }
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(238),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: ProfileScreen._ink.withAlpha(20)),
            boxShadow: [
              BoxShadow(
                color: ProfileScreen._ink.withAlpha(12),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header with active groups counter
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${groups.length} ${groups.length == 1 ? 'grupo' : 'grupos'}',
                      style: TextStyle(
                        color: ProfileScreen._ink.withAlpha(170),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: ProfileScreen._ink,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.mail_outline,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              Divider(
                height: 1,
                thickness: 1,
                color: ProfileScreen._ink.withAlpha(15),
              ),

              // Groups list
              ...groups.map(
                (group) => _ProfileGroupTile(
                  group: group,
                  onTap: () async {
                    final didLeave = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => GroupMembersScreen(
                          group: group,
                          groupApiClient: _client,
                        ),
                      ),
                    );
                    if (didLeave == true && mounted) {
                      _refresh();
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileGroupTile extends StatelessWidget {
  const _ProfileGroupTile({required this.group, this.onTap});

  final GroupSummary group;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Group icon
              CircleAvatar(
                radius: 24,
                backgroundColor: ProfileScreen._accent,
                child: Text(
                  group.name.isEmpty ? 'G' : group.name[0].toUpperCase(),
                  style: const TextStyle(
                    color: ProfileScreen._ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Group information
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: const TextStyle(
                        color: ProfileScreen._ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      group.isCreator
                          ? 'Administrador · ${group.memberCount} integrantes'
                          : 'Miembro · ${group.memberCount} integrantes',
                      style: TextStyle(
                        color: ProfileScreen._ink.withAlpha(160),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Activity indicator or navigation
              const Icon(
                Icons.chevron_right,
                color: ProfileScreen._ink,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Upcoming events list
class _UpcomingEventsList extends StatefulWidget {
  const _UpcomingEventsList();

  @override
  State<_UpcomingEventsList> createState() => _UpcomingEventsListState();
}

class _UpcomingEventsListState extends State<_UpcomingEventsList> {
  final _client = EventApiClient();
  Future<List<EventSummary>>? _events;

  void _refresh() {
    setState(() {
      _events = _client.fetchUserUpcomingEvents(
        AuthProvider.of(context).value.currentUser!.id,
      ).then((events) {
        final now = DateTime.now();
        return events.where((e) => e.start != null && e.start!.isAfter(now)).toList();
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _events ??= _client.fetchUserUpcomingEvents(
      AuthProvider.of(context).value.currentUser!.id,
    ).then((events) {
      final now = DateTime.now();
      return events.where((e) => e.start != null && e.start!.isAfter(now)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = AuthProvider.of(context).value.currentUser!.id;
    return FutureBuilder<List<EventSummary>>(
      future: _events,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final events = snapshot.data ?? const [];
        if (snapshot.hasError || events.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(238),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              snapshot.hasError
                  ? 'No se pudieron cargar los eventos.'
                  : 'No tienes próximos eventos.',
            ),
          );
        }

        return Column(
          children: events.map((event) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _EventTile(
                event: event,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EventDetailScreen(
                        event: event,
                        eventApiClient: _client,
                        currentUserId: currentUserId,
                        onAttendanceChanged: (_) {
                          _refresh();
                        },
                        onDeleted: (_) {
                          _refresh();
                        },
                      ),
                    ),
                  );
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

String _formatDate(DateTime date) {
  final months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
  final month = months[date.month - 1];
  final day = date.day;
  final hour = date.hour;
  final minute = date.minute.toString().padLeft(2, '0');
  final amPm = hour >= 12 ? 'PM' : 'AM';
  final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
  return '$day $month, $hour12:$minute $amPm';
}

/// Individual event tile
class _EventTile extends StatelessWidget {
  const _EventTile({required this.event, this.onTap});

  final EventSummary event;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
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
            border: Border.all(color: ProfileScreen._ink.withAlpha(20)),
            boxShadow: [
              BoxShadow(
                color: ProfileScreen._ink.withAlpha(12),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              // Event image
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: ProfileScreen._surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: ProfileScreen._ink.withAlpha(20)),
                ),
                child: const Icon(
                  Icons.event,
                  size: 32,
                  color: ProfileScreen._ink,
                ),
              ),
              const SizedBox(width: 14),

              // Event information
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ProfileScreen._ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 12,
                          color: ProfileScreen._ink.withAlpha(160),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.start != null ? _formatDate(event.start!) : 'Fecha no disponible',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: ProfileScreen._ink.withAlpha(160),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 12,
                          color: ProfileScreen._ink.withAlpha(160),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.locationLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: ProfileScreen._ink.withAlpha(160),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
