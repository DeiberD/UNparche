import 'package:flutter/material.dart';

import '../../models/friend_api_exception.dart';
import '../../models/friend_request.dart';
import '../../models/user.dart';
import '../../services/friend_api_client.dart';
import '../../state/auth_state.dart';
import '../../theme/campus_colors.dart';
import 'friend_request_tile.dart';
import 'friend_tile.dart';

class FriendshipSection extends StatefulWidget {
  const FriendshipSection({super.key});

  @override
  State<FriendshipSection> createState() => _FriendshipSectionState();
}

class _FriendshipSectionState extends State<FriendshipSection> {
  final FriendApiClient _client = FriendApiClient();
  final Set<int> _processingRequestIds = {};

  Future<List<FriendRequest>>? _requests;
  Future<List<User>>? _friends;

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
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Perfil de ${friend.nombre} ${friend.apellido}',
                            ),
                          ),
                        );
                      },
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
