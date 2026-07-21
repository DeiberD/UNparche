import 'package:flutter/material.dart';

import '../../models/friend_api_exception.dart';
import '../../models/user.dart';
import '../../services/friend_api_client.dart';
import '../../state/auth_state.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key, required this.userId});

  final int userId;

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final FriendApiClient _friendApiClient = FriendApiClient();

  User? _user;
  String _friendshipStatus = 'NINGUNA';
  bool _isLoading = true;
  bool _isSendingRequest = false;
  String? _errorMessage;

  bool _hasLoadedProfile = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_hasLoadedProfile) {
      return;
    }

    _hasLoadedProfile = true;
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final token = AuthProvider.of(context).value.token;

    if (token == null) {
      setState(() {
        _errorMessage = 'No se pudo identificar la sesión actual.';
        _isLoading = false;
      });
      return;
    }

    try {
      final result = await _friendApiClient.fetchUserProfile(
        userId: widget.userId,
        token: token,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _user = result['usuario'] as User;
        _friendshipStatus = result['estadoAmistad'] as String;
        _isLoading = false;
      });
    } on FriendApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'No se pudo cargar el perfil del usuario.';
        _isLoading = false;
      });
    }
  }

  Future<void> _sendFriendRequest() async {
    final authState = AuthProvider.of(context).value;
    final currentUserId = authState.currentUser?.id;

    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo identificar al usuario autenticado.'),
        ),
      );
      return;
    }

    if (currentUserId == widget.userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No puedes enviarte una solicitud a ti mismo.'),
        ),
      );
      return;
    }

    setState(() {
      _isSendingRequest = true;
    });

    try {
      await _friendApiClient.sendFriendRequest(
        requesterId: currentUserId,
        receiverId: widget.userId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _friendshipStatus = 'PENDIENTE_ENVIADA';
        _isSendingRequest = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitud de amistad enviada.')),
      );
    } on FriendApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSendingRequest = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSendingRequest = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo enviar la solicitud de amistad.'),
        ),
      );
    }
  }

  String _formatDate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Fecha no disponible';
    }

    final normalizedValue = value.replaceFirst(' ', 'T');
    final date = DateTime.tryParse(normalizedValue);

    if (date == null) {
      return value;
    }

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  String _displayValue(String? value, String fallback) {
    final normalizedValue = value?.trim();

    if (normalizedValue == null || normalizedValue.isEmpty) {
      return fallback;
    }

    return normalizedValue;
  }

  String get _friendshipButtonText {
    switch (_friendshipStatus) {
      case 'AMIGOS':
        return 'Ya son amigos';
      case 'PENDIENTE_ENVIADA':
        return 'Solicitud enviada';
      case 'PENDIENTE_RECIBIDA':
        return 'Solicitud recibida';
      default:
        return 'Agregar amigo';
    }
  }

  IconData get _friendshipButtonIcon {
    switch (_friendshipStatus) {
      case 'AMIGOS':
        return Icons.people_alt_outlined;
      case 'PENDIENTE_ENVIADA':
        return Icons.schedule;
      case 'PENDIENTE_RECIBIDA':
        return Icons.mark_email_unread_outlined;
      default:
        return Icons.person_add_alt_1;
    }
  }

  bool get _canSendFriendRequest {
    return _friendshipStatus == 'NINGUNA' && !_isSendingRequest;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loadUserProfile,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final user = _user;

    if (user == null) {
      return const Center(child: Text('No se encontró el usuario.'));
    }

    return RefreshIndicator(
      onRefresh: _loadUserProfile,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          _ProfileAvatar(photoUrl: user.fotoPerfil, name: user.nombre),
          const SizedBox(height: 20),
          Text(
            user.nombreCompleto,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          if (user.nickname?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 6),
            Text(
              '@${user.nickname!.trim()}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
            ),
          ],
          const SizedBox(height: 24),
          _ProfileInformationCard(
            icon: Icons.school_outlined,
            title: 'Carrera',
            value: _displayValue(user.carrera, 'Carrera no especificada'),
          ),
          const SizedBox(height: 12),
          _ProfileInformationCard(
            icon: Icons.info_outline,
            title: 'Información personal',
            value: _displayValue(
              user.informacionPersonal,
              'El usuario no ha agregado información personal.',
            ),
          ),
          const SizedBox(height: 12),
          _ProfileInformationCard(
            icon: Icons.alternate_email,
            title: 'Correo institucional',
            value: user.correoInstitucional,
          ),
          const SizedBox(height: 12),
          _ProfileInformationCard(
            icon: Icons.badge_outlined,
            title: 'Rol',
            value: _displayValue(user.rol, 'No especificado'),
          ),
          const SizedBox(height: 12),
          _ProfileInformationCard(
            icon: Icons.calendar_month_outlined,
            title: 'Miembro desde',
            value: _formatDate(user.fechaCreacion),
          ),
          const SizedBox(height: 28),
          if (_friendshipStatus != 'PROPIO')
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _canSendFriendRequest ? _sendFriendRequest : null,
                icon: _isSendingRequest
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(_friendshipButtonIcon),
                label: Text(
                  _isSendingRequest ? 'Enviando...' : _friendshipButtonText,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.photoUrl, required this.name});

  final String? photoUrl;
  final String name;

  @override
  Widget build(BuildContext context) {
    final normalizedPhotoUrl = photoUrl?.trim();
    final hasPhoto =
        normalizedPhotoUrl != null && normalizedPhotoUrl.isNotEmpty;

    return Center(
      child: CircleAvatar(
        radius: 58,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        backgroundImage: hasPhoto ? NetworkImage(normalizedPhotoUrl) : null,
        child: hasPhoto
            ? null
            : Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}

class _ProfileInformationCard extends StatelessWidget {
  const _ProfileInformationCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(value, style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
