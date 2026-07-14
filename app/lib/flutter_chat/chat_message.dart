/// Modelo de un mensaje de chat tal como lo entrega el chat server en C++
/// (protocolo JSON por linea sobre TCP) o el historial de la API TS.
class ChatMessage {
  const ChatMessage({
    required this.idEvento,
    required this.correo,
    required this.nickname,
    required this.contenido,
    required this.timestamp,
  });

  final int idEvento;
  final String correo;
  final String nickname;
  final String contenido;
  final DateTime timestamp;

  /// Construye un ChatMessage a partir de una linea JSON recibida por el
  /// socket TCP del chat server (type == "message").
  factory ChatMessage.fromSocketJson(Map<String, dynamic> json) {
    final timestampMs = json['timestamp_ms'] as int?;
    return ChatMessage(
      idEvento: json['id_evento'] as int,
      correo: json['correo'] as String,
      nickname: json['nickname'] as String,
      contenido: json['contenido'] as String,
      timestamp: timestampMs != null
          ? DateTime.fromMillisecondsSinceEpoch(timestampMs)
          : DateTime.now(),
    );
  }

  /// Construye un ChatMessage a partir de una fila del historial que
  /// devuelve la API TS (GET /eventos/:id/mensajes).
  factory ChatMessage.fromApiJson(Map<String, dynamic> json, int idEvento) {
    return ChatMessage(
      idEvento: idEvento,
      correo: json['correo'] as String? ?? '',
      nickname: json['nickname'] as String,
      contenido: json['contenido'] as String,
      timestamp: DateTime.parse(json['fecha_envio'] as String),
    );
  }
}
