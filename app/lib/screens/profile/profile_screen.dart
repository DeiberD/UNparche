import 'package:flutter/material.dart';
import '../../state/auth_state.dart';

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
                Navigator.of(context).popUntil((route) => route.isFirst);
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
          ],
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
class _GroupsList extends StatelessWidget {
  const _GroupsList();

  @override
  Widget build(BuildContext context) {
    // Sample groups data
    final groups = [
      _GroupData(
        name: 'GFAs',
        subtitle: 'Next meeting: Tomorrow',
        icon: 'A',
        memberCount: 12,
        isActive: true,
      ),
      _GroupData(
        name: 'Compe',
        subtitle: 'Upsolving',
        icon: 'C',
        memberCount: 8,
        isActive: false,
      ),
    ];

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
                  '${groups.where((g) => g.isActive).length} Active',
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
          ...groups.map((group) => _GroupTile(group: group)),
        ],
      ),
    );
  }
}

/// Data model for a group
class _GroupData {
  const _GroupData({
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.memberCount,
    required this.isActive,
  });

  final String name;
  final String subtitle;
  final String icon;
  final int memberCount;
  final bool isActive;
}

/// Individual group tile
class _GroupTile extends StatelessWidget {
  const _GroupTile({required this.group});

  final _GroupData group;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // TODO: Navigate to group details
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Abriendo ${group.name}')));
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Group icon
              CircleAvatar(
                radius: 24,
                backgroundColor: ProfileScreen._accent,
                child: Text(
                  group.icon,
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
                      group.subtitle,
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
class _UpcomingEventsList extends StatelessWidget {
  const _UpcomingEventsList();

  @override
  Widget build(BuildContext context) {
    // Sample events data
    final events = [
      _EventData(
        title: 'Maratón Interna UNAL',
        date: 'June 10, 2:00 PM',
        location: '401 Julio Gar. Arm. - 103',
        imageIcon: Icons.directions_run,
      ),
      _EventData(
        title: 'Torneo De Fútbol PMP',
        date: 'June 20, 9:00 AM',
        location: 'Canchas microfútbol UNAL',
        imageIcon: Icons.sports_soccer,
      ),
    ];

    return Column(
      children: events.map((event) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _EventTile(event: event),
        );
      }).toList(),
    );
  }
}

/// Data model for an event
class _EventData {
  const _EventData({
    required this.title,
    required this.date,
    required this.location,
    required this.imageIcon,
  });

  final String title;
  final String date;
  final String location;
  final IconData imageIcon;
}

/// Individual event tile
class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});

  final _EventData event;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withAlpha(242),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          // TODO: Navigate to event details
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Abriendo ${event.title}')));
        },
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
                child: Icon(
                  event.imageIcon,
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
                            event.date,
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
                            event.location,
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
