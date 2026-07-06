import 'group.dart';

/// Group invitation model
class GroupInvitation {
  const GroupInvitation({
    required this.id,
    required this.status,
    required this.sentAt,
    this.respondedAt,
    required this.groupId,
    required this.invitedUserId,
    required this.inviterUserId,
    this.inviterName,
    this.group,
  });

  final int id;
  final String status; // PENDIENTE, ACEPTADA, RECHAZADA
  final DateTime sentAt;
  final DateTime? respondedAt;
  final int groupId;
  final int invitedUserId;
  final int inviterUserId;
  final String? inviterName;
  final Group? group;

  /// Whether the invitation is still pending
  bool get isPending => status == 'PENDIENTE';

  /// Create GroupInvitation from JSON
  factory GroupInvitation.fromJson(Map<String, dynamic> json) {
    return GroupInvitation(
      id: json['id_invitacion_grupo'] as int,
      status: json['estado'] as String,
      sentAt: DateTime.parse(json['fecha_envio'] as String),
      respondedAt: json['fecha_respuesta'] != null
          ? DateTime.parse(json['fecha_respuesta'] as String)
          : null,
      groupId: json['id_grupo'] as int,
      invitedUserId: json['id_invitado'] as int,
      inviterUserId: json['id_invitador'] as int,
      inviterName: json['nombre_invitador'] as String?,
      group: json['nombre'] != null
          ? Group.fromJson({
              'id_grupo': json['id_grupo'],
              'nombre': json['nombre'],
              'descripcion': json['descripcion'],
              'categoria': json['categoria'],
              'es_oficial': json['es_oficial'],
              'estado_verificacion': json['estado_verificacion'],
              'fecha_creacion': json['fecha_creacion'],
              'id_administrador': json['id_administrador'],
              'cantidad_integrantes': json['cantidad_integrantes'] ?? json['total_miembros'],
            })
          : null,
    );
  }

  /// Convert GroupInvitation to JSON
  Map<String, dynamic> toJson() {
    return {
      'id_invitacion_grupo': id,
      'estado': status,
      'fecha_envio': sentAt.toIso8601String(),
      if (respondedAt != null) 'fecha_respuesta': respondedAt!.toIso8601String(),
      'id_grupo': groupId,
      'id_invitado': invitedUserId,
      'id_invitador': inviterUserId,
      if (inviterName != null) 'nombre_invitador': inviterName,
      if (group != null) ...group!.toJson(),
    };
  }
}
