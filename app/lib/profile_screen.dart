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
/// - Logout button
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadUserData());
  }

  /// Load user's events and groups from API
  Future<void> _loadUserData() async {
    if (!mounted) return;
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

      // TODO: Implement /usuarios/:id/grupos endpoint in backend
      final groups = <Group>[];

      if (!mounted) return;
      setState(() {
        _userEvents = upcomingEvents.take(5).toList();
        _userGroups = groups;
        _isLoadingData = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoadingData = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error al cargar datos del perfil';
        _isLoadingData = false;
      });
    }
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ProfileScreen._surface,
        title: const Text(
          'Cerrar sesión',
          style: TextStyle(
            color: ProfileScreen._ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          '¿Estás seguro de que deseas cerrar sesión?',
          style: TextStyle(
            color: ProfileScreen._ink.withAlpha(180),
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: ProfileScreen._ink.withAlpha(160),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: ProfileScreen._ink,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Cerrar sesión',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<AuthService>().signOut();
      // Clear cached data
      setState(() {
        _userEvents = null;
        _userGroups = null;
        _errorMessage = null;
      });
    }
  }

  void _openEditProfile() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(builder: (_) => const _EditProfileScreen()),
        )
        .then((_) => _loadUserData());
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
        actions: [
          // Logout button in AppBar
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Cerrar sesión',
            onPressed: _confirmSignOut,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadUserData,
          color: ProfileScreen._ink,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
            children: [
              // Profile section
              _ProfileHeader(),
              const SizedBox(height: 20),

              // Action buttons row: Edit profile
              _EditProfileButton(onPressed: _openEditProfile),
              const SizedBox(height: 12),

              // Logout button
              _SignOutButton(onPressed: _confirmSignOut),
              const SizedBox(height: 32),

              // Groups section
              const _SectionTitle(title: 'Mis grupos'),
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
              const _SectionTitle(title: 'Próximos eventos'),
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

// ---------------------------------------------------------------------------
// Edit Profile Screen
// ---------------------------------------------------------------------------

class _EditProfileScreen extends StatefulWidget {
  const _EditProfileScreen();

  @override
  State<_EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<_EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _lastNameController;
  late TextEditingController _careerController;
  late TextEditingController _bioController;

  bool _isSaving = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthService>().currentUser;
    _nameController = TextEditingController(text: user?.name ?? '');
    _lastNameController = TextEditingController(text: user?.lastName ?? '');
    _careerController = TextEditingController(text: user?.career ?? '');
    _bioController = TextEditingController(text: user?.personalInfo ?? '');

    // Listen for changes
    for (final ctrl in [
      _nameController,
      _lastNameController,
      _careerController,
      _bioController,
    ]) {
      ctrl.addListener(_onFieldChanged);
    }
  }

  void _onFieldChanged() {
    if (!_hasChanges && mounted) setState(() => _hasChanges = true);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _careerController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false) || _isSaving) return;

    setState(() => _isSaving = true);

    try {
      // Simulate brief network delay (remove when backend endpoint is ready)
      await Future.delayed(const Duration(milliseconds: 600));

      if (!mounted) return;

      // Update local user through AuthService
      context.read<AuthService>().updateUser(
            name: _nameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            career: _careerController.text.trim(),
            personalInfo: _bioController.text.trim(),
          );

      setState(() {
        _isSaving = false;
        _hasChanges = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil actualizado correctamente'),
            backgroundColor: Color(0xFF263020),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ProfileScreen._surface,
        title: const Text(
          'Cambios sin guardar',
          style: TextStyle(
            color: ProfileScreen._ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          'Tienes cambios sin guardar. ¿Deseas salir de todos modos?',
          style: TextStyle(
            color: ProfileScreen._ink.withAlpha(180),
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Quedarme',
              style: TextStyle(
                color: ProfileScreen._ink.withAlpha(160),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: ProfileScreen._ink,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Salir',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          final shouldPop = await _onWillPop();
          if (shouldPop && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: ProfileScreen._background,
        appBar: AppBar(
          backgroundColor: ProfileScreen._background,
          foregroundColor: ProfileScreen._ink,
          title: const Text(
            'Editar perfil',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          actions: [
            if (_hasChanges)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: TextButton(
                  onPressed: _isSaving ? null : _save,
                  child: Text(
                    'Guardar',
                    style: TextStyle(
                      color: ProfileScreen._ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 40),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar section
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: ProfileScreen._surface,
                            border: Border.all(
                              color: ProfileScreen._ink.withAlpha(30),
                              width: 2,
                            ),
                          ),
                          child: const ClipOval(
                            child: Icon(
                              Icons.person,
                              size: 56,
                              color: ProfileScreen._ink,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: ProfileScreen._ink,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: ProfileScreen._background,
                                width: 3,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Personal information ──
                  const _FormSectionLabel(label: 'Información personal'),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _ProfileTextField(
                          controller: _nameController,
                          label: 'Nombre',
                          icon: Icons.person_outline,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Campo requerido'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ProfileTextField(
                          controller: _lastNameController,
                          label: 'Apellido',
                          icon: Icons.person_outline,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Campo requerido'
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  _ProfileTextField(
                    controller: _careerController,
                    label: 'Carrera',
                    icon: Icons.school_outlined,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Campo requerido'
                        : null,
                  ),
                  const SizedBox(height: 14),

                  // Email (read-only)
                  _ReadOnlyField(
                    label: 'Correo institucional',
                    value: context.read<AuthService>().currentUser?.email ?? '',
                    icon: Icons.email_outlined,
                  ),
                  const SizedBox(height: 28),

                  // ── Bio ──
                  const _FormSectionLabel(label: 'Sobre mí'),
                  const SizedBox(height: 12),

                  _ProfileTextField(
                    controller: _bioController,
                    label: 'Información personal',
                    icon: Icons.info_outline,
                    maxLines: 4,
                    hintText:
                        'Cuéntale a la comunidad un poco sobre ti...',
                    validator: null,
                  ),
                  const SizedBox(height: 32),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      onPressed: _isSaving ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: ProfileScreen._ink,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            ProfileScreen._ink.withAlpha(80),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Guardar cambios',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable form components
// ---------------------------------------------------------------------------

class _FormSectionLabel extends StatelessWidget {
  const _FormSectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: ProfileScreen._ink,
        fontSize: 13,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _ProfileTextField extends StatelessWidget {
  const _ProfileTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.maxLines = 1,
    this.hintText,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int maxLines;
  final String? hintText;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(
        color: ProfileScreen._ink,
        fontWeight: FontWeight.w600,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon, color: ProfileScreen._ink.withAlpha(160), size: 20),
        labelStyle: TextStyle(
          color: ProfileScreen._ink.withAlpha(160),
          fontWeight: FontWeight.w700,
        ),
        hintStyle: TextStyle(
          color: ProfileScreen._ink.withAlpha(100),
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: Colors.white.withAlpha(230),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: ProfileScreen._ink.withAlpha(30)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: ProfileScreen._ink, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFB3261E)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFB3261E), width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: ProfileScreen._surface.withAlpha(200),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ProfileScreen._ink.withAlpha(20)),
      ),
      child: Row(
        children: [
          Icon(icon, color: ProfileScreen._ink.withAlpha(120), size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: ProfileScreen._ink.withAlpha(140),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: ProfileScreen._ink.withAlpha(180),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Spacer(),
          Icon(Icons.lock_outline, size: 14, color: ProfileScreen._ink.withAlpha(100)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Profile screen components
// ---------------------------------------------------------------------------

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
  // ignore: prefer_const_constructors_in_immutables
  _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final user = authService.currentUser;

    return Column(
      children: [
        // Profile photo
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
          child: user?.photoUrl != null
              ? ClipOval(
                  child: Image.network(
                    user!.photoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => const Icon(
                      Icons.person,
                      size: 60,
                      color: ProfileScreen._ink,
                    ),
                  ),
                )
              : const ClipOval(
                  child: Icon(
                    Icons.person,
                    size: 60,
                    color: ProfileScreen._ink,
                  ),
                ),
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
        const SizedBox(height: 4),

        // Career / role badge
        if (user?.career != null && user!.career.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: ProfileScreen._accent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              user.career,
              style: const TextStyle(
                color: ProfileScreen._ink,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        const SizedBox(height: 10),

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
                    textStyle:
                        const TextStyle(fontWeight: FontWeight.w800),
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
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.edit_outlined, size: 18),
        label: const Text(
          'Editar perfil',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        ),
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
      ),
    );
  }
}

/// Sign out button
class _SignOutButton extends StatelessWidget {
  const _SignOutButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: const Text(
          'Cerrar sesión',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFB3261E),
          side: const BorderSide(
            color: Color(0xFFB3261E),
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
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
        fontSize: 20,
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
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: ProfileScreen._ink.withAlpha(15),
          ),
          ...groups.map((group) => _GroupTile(group: group)),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Abriendo ${group.name}')),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
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

  String _formatDate() {
    final date = event.startDate;
    if (date == null) return 'Fecha por confirmar';

    const months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
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
