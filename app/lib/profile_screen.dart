import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth_service.dart';
import 'login_screen.dart';
import 'models/event.dart';
import 'models/group.dart';
import 'services/api_client.dart';

/// User profile screen
///
/// Shows login prompt if user is not authenticated.
/// Displays user profile information when authenticated:
/// - Profile photo with edit option
/// - User name and biography
/// - Edit profile button
/// - User's groups list (from API)
/// - Upcoming events list (from API)
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
  final ApiClient _apiClient = ApiClient();
  List<Event>? _userEvents;
  List<Group>? _userGroups;
  bool _isLoadingData = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// Load user's events and groups from API
  Future<void> _loadUserData() async {
    final authService = context.read<AuthService>();
    if (!authService.isAuthenticated) return;

    setState(() {
      _isLoadingData = true;
      _errorMessage = null;
    });

    try {
      final userId = authService.currentUser!.id;

      // Load user events
      final eventsData = await _apiClient.getUserEvents(userId);
      final organizedEvents = eventsData['organized'] ?? <Event>[];
      final attendingEvents = eventsData['attending'] ?? <Event>[];
      
      final allEvents = [...organizedEvents, ...attendingEvents];

      // Filter upcoming events (not yet finished)
      final now = DateTime.now();
      final upcomingEvents = allEvents
          .where((event) =>
              event.endDate != null &&
              event.endDate!.isAfter(now) &&
              event.status == 'PROGRAMADO')
          .toList()
        ..sort((a, b) => (a.startDate ?? DateTime(9999))
            .compareTo(b.startDate ?? DateTime(9999)));

      // Load user groups (mock for now - needs backend endpoint)
      // TODO: Implement /usuarios/:id/grupos endpoint in backend
      final groups = <Group>[];

      setState(() {
        _userEvents = upcomingEvents.take(5).toList();
        _userGroups = groups;
        _isLoadingData = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar datos del perfil';
        _isLoadingData = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();

    // Show login prompt if not authenticated
    if (!authService.isAuthenticated) {
      return const _LoginPromptView();
    }

    // Show profile when authenticated
    return Scaffold(
      backgroundColor: ProfileScreen._background,
      appBar: AppBar(
        backgroundColor: ProfileScreen._background,
        foregroundColor: ProfileScreen._ink,
        title: const Text(
          'Perfil',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        // TODO: Implement search functionality
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.search),
        //     onPressed: () {},
        //     tooltip: 'Buscar',
        //   ),
        // ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadUserData,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
            children: [
              // Profile section
              const _ProfileHeader(),
              const SizedBox(height: 24),

              // Edit profile button
              _EditProfileButton(
                onPressed: () {
                  // TODO: Navigate to profile edit screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Edición de perfil próximamente'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),

              // Groups section
              const _SectionTitle(title: 'My Groups'),
              const SizedBox(height: 12),
              _isLoadingData
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : _GroupsList(groups: _userGroups ?? []),
              const SizedBox(height: 32),

              // Upcoming events section
              const _SectionTitle(title: 'Upcoming Events'),
              const SizedBox(height: 12),
              _isLoadingData
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : _errorMessage != null
                      ? _ErrorMessage(message: _errorMessage!)
                      : _UpcomingEventsList(events: _userEvents ?? []),
            ],
          ),
        ),
      ),
    );
  }
}

/// Error message widget
class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(238),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFB3261E).withAlpha(60),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: Color(0xFFB3261E),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: const Color(0xFF263020).withAlpha(180),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Profile header widget with photo, name and biography
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final user = authService.currentUser;

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
              child: const ClipOval(
                child: Icon(
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
                child: const Icon(
                  Icons.edit,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // User name
        Text(
          user?.fullName ?? 'Usuario',
          style: const TextStyle(
            color: ProfileScreen._ink,
            fontSize: 26,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),

        // User biography
        if (user?.bio != null && user!.bio.isNotEmpty)
          Text(
            user.bio,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ProfileScreen._ink.withAlpha(180),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
      ],
    );
  }
}

/// Login prompt view shown when user is not authenticated
class _LoginPromptView extends StatelessWidget {
  const _LoginPromptView();

  void _goToLogin(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
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
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: ProfileScreen._surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ProfileScreen._ink.withAlpha(30),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.person_outline,
                  size: 64,
                  color: ProfileScreen._ink,
                ),
              ),
              const SizedBox(height: 32),

              // Title
              const Text(
                'Inicia sesión para continuar',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ProfileScreen._ink,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                'Accede a tu perfil, grupos y eventos guardados.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ProfileScreen._ink.withAlpha(170),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 40),

              // Login button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: () => _goToLogin(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: ProfileScreen._ink,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontWeight: FontWeight.w800),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Iniciar Sesión'),
                ),
              ),
            ],
          ),
        ),
      ),
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
          side: BorderSide(
            color: ProfileScreen._ink.withAlpha(100),
            width: 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: const Text(
          'Edit Profile',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
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
  const _GroupsList({required this.groups});

  final List<Group> groups;

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(238),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: ProfileScreen._ink.withAlpha(20)),
        ),
        child: Column(
          children: [
            Icon(
              Icons.groups_outlined,
              size: 48,
              color: ProfileScreen._ink.withAlpha(140),
            ),
            const SizedBox(height: 12),
            Text(
              'No estás en ningún grupo',
              style: TextStyle(
                color: ProfileScreen._ink.withAlpha(170),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
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
          // Header with groups counter
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${groups.length} ${groups.length == 1 ? 'Grupo' : 'Grupos'}',
                  style: TextStyle(
                    color: ProfileScreen._ink.withAlpha(170),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
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
            (group) => _GroupTile(group: group),
          ),
        ],
      ),
    );
  }
}

/// Individual group tile
class _GroupTile extends StatelessWidget {
  const _GroupTile({required this.group});

  final Group group;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // TODO: Navigate to group details
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Abriendo ${group.name}')),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Group icon with first letter
              CircleAvatar(
                radius: 24,
                backgroundColor: ProfileScreen._accent,
                child: Text(
                  group.name.isNotEmpty ? group.name[0].toUpperCase() : 'G',
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
                      '${group.memberCount} ${group.memberCount == 1 ? 'miembro' : 'miembros'} · ${group.categoryLabel}',
                      style: TextStyle(
                        color: ProfileScreen._ink.withAlpha(160),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Navigation indicator
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
  const _UpcomingEventsList({required this.events});

  final List<Event> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(238),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: ProfileScreen._ink.withAlpha(20)),
        ),
        child: Column(
          children: [
            Icon(
              Icons.event_outlined,
              size: 48,
              color: ProfileScreen._ink.withAlpha(140),
            ),
            const SizedBox(height: 12),
            Text(
              'No tienes eventos próximos',
              style: TextStyle(
                color: ProfileScreen._ink.withAlpha(170),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

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

/// Individual event tile
class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});

  final Event event;

  /// Get icon for event type
  IconData _getEventIcon() {
    switch (event.eventTypeId) {
      case 1:
        return Icons.school_outlined;
      case 2:
        return Icons.palette_outlined;
      case 3:
        return Icons.sports_soccer_outlined;
      case 4:
        return Icons.celebration_outlined;
      case 5:
        return Icons.more_horiz;
      default:
        return Icons.event_outlined;
    }
  }

  /// Format date for display
  String _formatDate() {
    final date = event.startDate;
    if (date == null) return 'Fecha por confirmar';

    final months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic'
    ];

    final month = months[date.month - 1];
    final day = date.day;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$month $day, $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withAlpha(242),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          // TODO: Navigate to event details
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Abriendo ${event.title}')),
          );
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
                  border: Border.all(
                    color: ProfileScreen._ink.withAlpha(20),
                  ),
                ),
                child: Icon(
                  _getEventIcon(),
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
                            _formatDate(),
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
                    if (event.hasLocation) ...[
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
                              event.typeLabel,
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
