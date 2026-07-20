class FriendRequest {
  const FriendRequest({
    required this.friendshipId,
    required this.status,
    required this.requestedAt,
    required this.requesterId,
    required this.requesterName,
    required this.requesterEmail,
    this.respondedAt,
    this.requesterCareer,
    this.requesterInformation,
    this.requesterPhoto,
  });

  final int friendshipId;
  final String status;
  final String requestedAt;
  final String? respondedAt;

  final int requesterId;
  final String requesterName;
  final String requesterEmail;
  final String? requesterCareer;
  final String? requesterInformation;
  final String? requesterPhoto;

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      friendshipId: json['id_amistad'] as int,
      status: json['estado'] as String,
      requestedAt: json['fecha_solicitud'] as String,
      respondedAt: json['fecha_respuesta'] as String?,
      requesterId: json['id_solicitante'] as int,
      requesterName: json['solicitante_nombre'] as String,
      requesterEmail: json['solicitante_correo'] as String,
      requesterCareer: json['solicitante_carrera'] as String?,
      requesterInformation: json['solicitante_informacion'] as String?,
      requesterPhoto: json['solicitante_foto'] as String?,
    );
  }
}