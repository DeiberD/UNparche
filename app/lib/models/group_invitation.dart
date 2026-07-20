import 'group_summary.dart';

class GroupInvitation {
  const GroupInvitation({
    required this.id,
    required this.status,
    required this.group,
    required this.inviterName,
  });

  factory GroupInvitation.fromJson(Map<String, dynamic> json) {
    return GroupInvitation(
      id: _toInt(json['id_invitacion_grupo']),
      status: json['estado']?.toString() ?? 'PENDIENTE',
      group: GroupSummary.fromJson(json),
      inviterName: json['nombre_invitador']?.toString() ?? 'Un miembro',
    );
  }

  final int? id;
  final String status;
  final GroupSummary group;
  final String inviterName;

  bool get isPending => status == 'PENDIENTE';
}

int? _toInt(Object? value) {
  if (value is int) {
    return value;
  }

  if (value is double && value % 1 == 0) {
    return value.toInt();
  }

  return null;
}
