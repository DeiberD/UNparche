import 'package:flutter/material.dart';

import 'group_api_client.dart';

class GroupMembersScreen extends StatefulWidget {
  const GroupMembersScreen({
    super.key,
    required this.group,
    required this.groupApiClient,
  });

  final GroupSummary group;
  final GroupApiClient groupApiClient;

  @override
  State<GroupMembersScreen> createState() => _GroupMembersScreenState();
}

class _GroupMembersScreenState extends State<GroupMembersScreen> {
  late Future<List<GroupMember>> _members;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _members = widget.groupApiClient.fetchGroupMembers(
      groupId: widget.group.id!,
    );
  }

  Future<void> _refresh() async {
    setState(_load);
    await _members;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF5F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF5F2),
        foregroundColor: const Color(0xFF263020),
        title: Text(
          widget.group.name,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: FutureBuilder<List<GroupMember>>(
        future: _members,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _MembersMessage(
              icon: Icons.error_outline,
              message: snapshot.error is GroupApiException
                  ? (snapshot.error! as GroupApiException).message
                  : 'No se pudieron cargar los integrantes.',
              onRetry: () => setState(_load),
            );
          }
          final members = snapshot.data ?? const [];
          if (members.isEmpty) {
            return const _MembersMessage(
              icon: Icons.group_off_outlined,
              message: 'Este grupo no tiene integrantes activos.',
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
              itemCount: members.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '${members.length} ${members.length == 1 ? 'integrante' : 'integrantes'}',
                      style: const TextStyle(
                        color: Color(0xFF263020),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  );
                }
                return _MemberTile(member: members[index - 1]);
              },
            ),
          );
        },
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member});
  final GroupMember member;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFF3ECE8),
          child: const Icon(Icons.person, color: Color(0xFF263020)),
        ),
        title: Text(
          member.name,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(member.email),
        trailing: member.isAdministrator
            ? const Chip(
                avatar: Icon(Icons.admin_panel_settings_outlined, size: 16),
                label: Text('Administrador'),
              )
            : const Chip(label: Text('Miembro')),
      ),
    );
  }
}

class _MembersMessage extends StatelessWidget {
  const _MembersMessage({
    required this.icon,
    required this.message,
    this.onRetry,
  });
  final IconData icon;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: const Color(0xFF263020)),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: onRetry,
                child: const Text('Reintentar'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
