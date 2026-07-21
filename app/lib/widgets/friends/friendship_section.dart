import 'package:flutter/material.dart';

import '../../models/friend_api_exception.dart';
import '../../models/friend_request.dart';
import '../../models/user.dart';
import '../../services/friend_api_client.dart';
import '../../state/auth_state.dart';
import '../../theme/campus_colors.dart';
import 'friend_request_tile.dart';
import 'friend_tile.dart';
import '../../screens/profile/user_profile_screen.dart';

class FriendshipSection extends StatefulWidget {
  const FriendshipSection({super.key});

  @override
  State<FriendshipSection> createState() => _FriendshipSectionState();
}

class _FriendshipSectionState extends State<FriendshipSection> {
  final FriendApiClient _client = FriendApiClient();
  final Set<int> _processingRequestIds = {};
  final TextEditingController _searchController = TextEditingController();

  List<User> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  String? _searchError;

  Future<List<FriendRequest>>? _requests;
  Future<List<User>>? _friends;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final user = AuthProvider.of(context).value.currentUser;

    if (user == null) {
      return;
    }

    _requests ??= _client.fetchPendingRequests(userId: user.id);
    _friends ??= _client.fetchFriends(userId: user.id);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FriendshipSectionTitle(title: 'Buscar personas'),
        const SizedBox(height: 12),
        _buildUserSearch(),
        const SizedBox(height: 28),
        const _FriendshipSectionTitle(title: 'Solicitudes de amistad'),
        const SizedBox(height: 12),
        FutureBuilder<List<FriendRequest>>(
          future: _requests,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (snapshot.hasError) {
              return const _FriendshipMessage(
                message: 'No se pudieron cargar las solicitudes de amistad.',
              );
            }

            final requests = snapshot.data ?? const [];

            if (requests.isEmpty) {
              return const _FriendshipMessage(
                message: 'No tienes solicitudes de amistad pendientes.',
              );
            }

            return Container(
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(238),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: campusInk.withAlpha(20)),
              ),
              child: Column(
                children: requests
                    .map(
                      (request) => FriendRequestTile(
                        request: request,
                        onAccept: () {
                          _respondToRequest(request: request, accept: true);
                        },
                        onReject: () {
                          _respondToRequest(request: request, accept: false);
                        },
                        isProcessing: _processingRequestIds.contains(
                          request.friendshipId,
                        ),
                      ),
                    )
                    .toList(),
              ),
            );
          },
        ),
        const SizedBox(height: 28),
        const _FriendshipSectionTitle(title: 'Mis amigos'),
        const SizedBox(height: 12),
        FutureBuilder<List<User>>(
          future: _friends,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (snapshot.hasError) {
              return const _FriendshipMessage(
                message: 'No se pudieron cargar tus amigos.',
              );
            }

            final friends = snapshot.data ?? const [];

            if (friends.isEmpty) {
              return const _FriendshipMessage(
                message: 'Todavía no tienes amigos agregados.',
              );
            }

            return Container(
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(238),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: campusInk.withAlpha(20)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${friends.length} '
                        '${friends.length == 1 ? 'amigo' : 'amigos'}',
                        style: TextStyle(
                          color: campusInk.withAlpha(170),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: campusInk.withAlpha(15),
                  ),
                  ...friends.map(
                    (friend) => FriendTile(
                      friend: friend,
                      onTap: () {
                        _openUserProfile(friend.id);
                      },
                      onDelete: friend.friendshipId != null
                          ? () => _removeFriend(
                                friend.friendshipId!,
                                '${friend.nombre} ${friend.apellido}',
                              )
                          : null,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _removeFriend(int friendshipId, String friendName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar amigo'),
        content: Text('¿Estás seguro de que quieres eliminar a $friendName de tus amigos?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) {
      return;
    }

    try {
      await _client.removeFriend(friendshipId: friendshipId);

      if (!mounted) return;

      final currentUser = AuthProvider.of(context).value.currentUser;
      if (currentUser != null) {
        setState(() {
          _friends = _client.fetchFriends(userId: currentUser.id);
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Amistad eliminada correctamente.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  Widget _buildUserSearch() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) {
            _searchUsers();
          },
          decoration: InputDecoration(
            hintText: 'Buscar por nombre, apellido o correo',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              onPressed: _isSearching ? null : _searchUsers,
              icon: const Icon(Icons.arrow_forward),
            ),
            filled: true,
            fillColor: Colors.white.withAlpha(238),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: campusInk.withAlpha(20)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: campusInk.withAlpha(20)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_isSearching)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_searchError != null)
          _FriendshipMessage(message: _searchError!)
        else if (_hasSearched && _searchResults.isEmpty)
          const _FriendshipMessage(message: 'No se encontraron usuarios.')
        else if (_searchResults.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(238),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: campusInk.withAlpha(20)),
            ),
            child: Column(
              children: _searchResults
                  .map(
                    (user) => ListTile(
                      leading: _buildSearchAvatar(user),
                      title: Text(
                        '${user.nombre} ${user.apellido}',
                        style: const TextStyle(
                          color: campusInk,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      subtitle: Text(
                        _buildSearchSubtitle(user),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        _openUserProfile(user.id);
                      },
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildSearchAvatar(User user) {
    final photo = user.fotoPerfil?.trim();
    final hasPhoto = photo != null && photo.isNotEmpty;

    return CircleAvatar(
      backgroundImage: hasPhoto ? NetworkImage(photo) : null,
      child: hasPhoto
          ? null
          : Text(user.nombre.isNotEmpty ? user.nombre[0].toUpperCase() : '?'),
    );
  }

  String _buildSearchSubtitle(User user) {
    final values = <String>[];

    final nickname = user.nickname?.trim();
    final career = user.carrera?.trim();

    if (nickname != null && nickname.isNotEmpty) {
      values.add('@$nickname');
    }

    if (career != null && career.isNotEmpty) {
      values.add(career);
    }

    if (values.isEmpty) {
      return user.correoInstitucional;
    }

    return values.join(' · ');
  }

  Future<void> _searchUsers() async {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
        _searchError = null;
      });
      return;
    }

    final authState = AuthProvider.of(context).value;
    final token = authState.token;

    if (token == null) {
      setState(() {
        _searchError = 'No se pudo identificar la sesión actual.';
        _hasSearched = true;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _hasSearched = true;
      _searchError = null;
    });

    try {
      final users = await _client.searchUsers(query: query, token: token);

      if (!mounted) {
        return;
      }

      setState(() {
        _searchResults = users;
        _isSearching = false;
      });
    } on FriendApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _searchResults = [];
        _searchError = error.message;
        _isSearching = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _searchResults = [];
        _searchError = 'No se pudieron buscar usuarios.';
        _isSearching = false;
      });
    }
  }

  Future<void> _openUserProfile(int userId) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => UserProfileScreen(userId: userId),
      ),
    );

    if (!mounted) {
      return;
    }

    final currentUser = AuthProvider.of(context).value.currentUser;

    if (currentUser == null) {
      return;
    }

    setState(() {
      _friends = _client.fetchFriends(userId: currentUser.id);
      _requests = _client.fetchPendingRequests(userId: currentUser.id);
    });
  }

  Future<void> _respondToRequest({
    required FriendRequest request,
    required bool accept,
  }) async {
    if (_processingRequestIds.contains(request.friendshipId)) {
      return;
    }

    setState(() {
      _processingRequestIds.add(request.friendshipId);
    });

    try {
      await _client.respondFriendRequest(
        friendshipId: request.friendshipId,
        accept: accept,
      );

      if (!mounted) {
        return;
      }

      final user = AuthProvider.of(context).value.currentUser;

      if (user == null) {
        return;
      }

      setState(() {
        _requests = _client.fetchPendingRequests(userId: user.id);
        _friends = _client.fetchFriends(userId: user.id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            accept
                ? 'Solicitud de amistad aceptada.'
                : 'Solicitud de amistad rechazada.',
          ),
        ),
      );
    } on FriendApiException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo responder la solicitud de amistad.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _processingRequestIds.remove(request.friendshipId);
        });
      }
    }
  }
}

class _FriendshipSectionTitle extends StatelessWidget {
  const _FriendshipSectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: campusInk,
        fontSize: 22,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _FriendshipMessage extends StatelessWidget {
  const _FriendshipMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(238),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: campusInk.withAlpha(20)),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: campusInk.withAlpha(170),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
