import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'chat_message.dart';

const _configuredChatServerHost = String.fromEnvironment('CHAT_SERVER_HOST');
const _configuredChatServerPort = int.fromEnvironment(
  'CHAT_SERVER_PORT',
  defaultValue: 5000,
);

/// Excepcion lanzada cuando la conexion al chat server falla o se cae.
class ChatSocketException implements Exception {
  ChatSocketException(this.message);
  final String message;

  @override
  String toString() => 'ChatSocketException: $message';
}

/// Cliente TCP crudo del chat en tiempo real. Habla el mismo protocolo que
/// espera el chat server en C++ (boost::asio): JSON por linea, delimitado
/// por '\n'.
///
/// La "sesion" del usuario en el chat es la vida de este socket: no hay
/// login. Al conectar se manda un mensaje "join" con id_evento + correo
/// institucional + nickname;
/// el server responde con un ack "joined" y de ahi en adelante retransmite
/// cualquier mensaje ("type": "message") que llegue a esa sala.
///
/// Uso tipico:
/// ```dart
/// final client = ChatSocketClient(host: '1.2.3.4', port: 5000);
/// await client.connectAndJoin(
///   idEvento: 42,
///   correo: 'pquintero@unal.edu.co',
///   nickname: 'Pedro',
/// );
/// client.messages.listen((msg) => print('${msg.nickname}: ${msg.contenido}'));
/// client.sendMessage('Hola a todos');
/// ...
/// await client.disconnect();
/// ```
class ChatSocketClient {
  ChatSocketClient({required this.host, required this.port});

  static String get defaultHost {
    if (_configuredChatServerHost.isNotEmpty) {
      return _configuredChatServerHost;
    }

    return '186.31.2.212'; // IP publica del server de chat.
  }

  static int get defaultPort => _configuredChatServerPort;

  /// Abre una conexion corta para avisarle al chat server que existe un
  /// nuevo evento con chat habilitado. El server espera:
  /// {"type":"new_event","contenido":idEvento}
  static Future<void> announceNewEvent({
    required int idEvento,
    String? host,
    int? port,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    Socket? socket;
    try {
      socket = await Socket.connect(
        host ?? defaultHost,
        port ?? defaultPort,
        timeout: timeout,
      );
      socket.write(
        '${jsonEncode({'type': 'new_event', 'contenido': idEvento})}\n',
      );
      await socket.flush();
    } on SocketException catch (e) {
      throw ChatSocketException(
        'No se pudo avisar al chat server del nuevo evento: ${e.message}',
      );
    } finally {
      await socket?.close();
    }
  }

  final String host;
  final int port;

  Socket? _socket;
  StreamSubscription<String>? _lineSubscription;
  final StreamController<ChatMessage> _messagesController =
      StreamController<ChatMessage>.broadcast();
  final StreamController<void> _joinedController =
      StreamController<void>.broadcast();

  int? _idEvento;
  bool _joined = false;

  /// Stream de mensajes nuevos que llegan a la sala a la que se hizo join
  /// (incluye los que el propio usuario envio, con el timestamp oficial
  /// del server).
  Stream<ChatMessage> get messages => _messagesController.stream;

  /// Emite un evento cuando el server confirma el join ("type": "joined").
  Stream<void> get onJoined => _joinedController.stream;

  bool get isConnected => _socket != null;

  /// id_evento de la sala a la que se hizo join, o null si aun no se ha
  /// conectado.
  int? get idEvento => _idEvento;

  /// Abre la conexion TCP y manda el mensaje de join. Lanza
  /// [ChatSocketException] si no logra conectar.
  Future<void> connectAndJoin({
    required int idEvento,
    required String correo,
    required String nickname,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    if (correo.trim().isEmpty) {
      throw ChatSocketException('El correo no puede estar vacio.');
    }
    if (nickname.isEmpty) {
      throw ChatSocketException('El nickname no puede estar vacio.');
    }

    try {
      final socket = await Socket.connect(host, port, timeout: timeout);
      _socket = socket;
      _idEvento = idEvento;

      _lineSubscription = socket
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            _handleLine,
            onError: (Object error) {
              _messagesController.addError(
                ChatSocketException('Error en la conexion: $error'),
              );
            },
            onDone: () {
              _joined = false;
              _socket = null;
            },
            cancelOnError: false,
          );

      _writeJson({
        'type': 'join',
        'id_evento': idEvento,
        'correo': correo.trim(),
        'nickname': nickname,
      });
    } on SocketException catch (e) {
      throw ChatSocketException('No se pudo conectar al chat: ${e.message}');
    }
  }

  /// Envia un mensaje de texto a la sala actual. No hace nada si aun no se
  /// ha completado el join o si el socket no esta conectado.
  void sendMessage(String contenido) {
    final texto = contenido.trim();
    if (texto.isEmpty) {
      return;
    }
    if (!_joined || _socket == null) {
      throw ChatSocketException(
        'No se puede enviar el mensaje: el chat aun no esta conectado.',
      );
    }

    _writeJson({'type': 'message', 'contenido': texto});
  }

  void _handleLine(String line) {
    if (line.trim().isEmpty) {
      return;
    }

    late final Map<String, dynamic> json;
    try {
      json = jsonDecode(line) as Map<String, dynamic>;
    } catch (_) {
      // Linea corrupta o parcial: se ignora, no debe tumbar la conexion.
      return;
    }

    final type = json['type'] as String?;

    switch (type) {
      case 'joined':
        _joined = true;
        _joinedController.add(null);
        break;
      case 'message':
        try {
          _messagesController.add(ChatMessage.fromSocketJson(json));
        } catch (_) {
          // Mensaje con formato inesperado: se ignora individualmente.
        }
        break;
      default:
        // Tipos futuros/desconocidos se ignoran para no romper el cliente.
        break;
    }
  }

  void _writeJson(Map<String, dynamic> payload) {
    final socket = _socket;
    if (socket == null) {
      throw ChatSocketException('El socket no esta conectado.');
    }
    socket.write('${jsonEncode(payload)}\n');
  }

  /// Cierra la conexion. Seguro de llamar varias veces.
  Future<void> disconnect() async {
    await _lineSubscription?.cancel();
    _lineSubscription = null;
    await _socket?.close();
    _socket = null;
    _joined = false;
  }

  /// Libera los StreamControllers. Llamar solo cuando el cliente ya no se
  /// va a volver a usar (por ejemplo, en dispose() de un State).
  Future<void> dispose() async {
    await disconnect();
    await _messagesController.close();
    await _joinedController.close();
  }
}
