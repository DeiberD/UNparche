import 'dart:async';
import 'package:flutter/material.dart';
import '../../state/auth_state.dart';
import '../../models/event_summary.dart';
import '../../flutter_chat/chat_message.dart';
import '../../flutter_chat/chat_socket_client.dart';
import '../../theme/campus_colors.dart';
class EventChatScreen extends StatefulWidget {
  const EventChatScreen({super.key, required this.event});

  final EventSummary event;

  @override
  State<EventChatScreen> createState() => _EventChatScreenState();
}

class _EventChatScreenState extends State<EventChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  ChatSocketClient? _client;
  StreamSubscription<ChatMessage>? _messagesSubscription;
  StreamSubscription<void>? _joinedSubscription;
  String? _statusMessage = 'Conectando al chat...';
  bool _isJoined = false;
  String _correo = '';
  String _nickname = ' ';
  bool _didStartConnection = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didStartConnection) {
      return;
    }

    _didStartConnection = true;
    final user = AuthProvider.of(context).value.currentUser;
    _correo = user?.correoInstitucional ?? '';
    _nickname = user?.chatNickname ?? ' ';
    unawaited(_connectToChat());
  }

  Future<void> _connectToChat() async {
    final eventId = widget.event.id;
    if (eventId == null) {
      setState(() => _statusMessage = 'Este evento no tiene ID de chat.');
      return;
    }

    final client = ChatSocketClient(
      host: ChatSocketClient.defaultHost,
      port: ChatSocketClient.defaultPort,
    );

    _messagesSubscription = client.messages.listen(
      (message) {
        if (!mounted) {
          return;
        }
        setState(() => _messages.add(message));
        _scrollToBottom();
      },
      onError: (Object error) {
        if (!mounted) {
          return;
        }
        setState(() => _statusMessage = error.toString());
      },
    );

    _joinedSubscription = client.onJoined.listen((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isJoined = true;
        _statusMessage = null;
      });
    });

    try {
      await client.connectAndJoin(
        idEvento: eventId,
        correo: _correo,
        nickname: _nickname,
      );
      if (!mounted) {
        await client.dispose();
        return;
      }
      _client = client;
    } on ChatSocketException catch (error) {
      if (!mounted) {
        await client.dispose();
        return;
      }
      setState(() => _statusMessage = error.toString());
      await client.dispose();
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      return;
    }

    try {
      _client?.sendMessage(text);
      _messageController.clear();
    } on ChatSocketException catch (error) {
      setState(() => _statusMessage = error.toString());
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    unawaited(_messagesSubscription?.cancel());
    unawaited(_joinedSubscription?.cancel());
    unawaited(_client?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eventTitle = widget.event.title.trim().isEmpty
        ? 'Chat del evento'
        : widget.event.title.trim();

    return Scaffold(
      backgroundColor: campusBackground,
      appBar: AppBar(
        backgroundColor: campusBackground,
        foregroundColor: campusInk,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Chat', style: TextStyle(fontWeight: FontWeight.w900)),
            Text(
              eventTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: campusInk.withAlpha(170),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _messages.isEmpty
                  ? _EmptyChatMessage(statusMessage: _statusMessage)
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        return _ChatBubble(
                          message: message,
                          isMine: message.correo == _correo,
                        );
                      },
                    ),
            ),
            if (_statusMessage != null && _messages.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
                child: Text(
                  _statusMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: campusInk.withAlpha(150),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            _ChatInputBar(
              controller: _messageController,
              enabled: _isJoined,
              onSend: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyChatMessage extends StatelessWidget {
  const _EmptyChatMessage({required this.statusMessage});

  final String? statusMessage;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Text(
          statusMessage ??
              'Todavia no hay mensajes. Se el primero en escribir.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: campusInk.withAlpha(165),
            fontSize: 14,
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message, required this.isMine});

  final ChatMessage message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final alignment = isMine
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;
    final bubbleColor = isMine ? campusInk : Colors.white;
    final textColor = isMine ? Colors.white : campusInk;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              message.nickname,
              style: TextStyle(
                color: campusInk.withAlpha(150),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.74,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMine ? 18 : 5),
                  bottomRight: Radius.circular(isMine ? 5 : 18),
                ),
                border: isMine
                    ? null
                    : Border.all(color: campusInk.withAlpha(18)),
                boxShadow: [
                  BoxShadow(
                    color: campusInk.withAlpha(12),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Text(
                message.contenido,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatInputBar extends StatelessWidget {
  const _ChatInputBar({
    required this.controller,
    required this.enabled,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: campusInk.withAlpha(22)),
          boxShadow: [
            BoxShadow(
              color: campusInk.withAlpha(14),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: enabled ? (_) => onSend() : null,
                decoration: InputDecoration(
                  hintText: enabled ? 'Escribe un mensaje...' : 'Conectando...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    color: campusInk.withAlpha(115),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: const TextStyle(
                  color: campusInk,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _SendButton(enabled: enabled, onPressed: onSend),
          ],
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: FilledButton(
        onPressed: enabled ? onPressed : null,
        style: FilledButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: campusInk,
          disabledBackgroundColor: campusInk.withAlpha(55),
          shape: const CircleBorder(),
        ),
        child: const _SendArrowIcon(),
      ),
    );
  }
}

class _SendArrowIcon extends StatelessWidget {
  const _SendArrowIcon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(21, 21), painter: _SendArrowPainter());
  }
}

class _SendArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final path = Path()
      ..moveTo(size.width * 0.11, size.height * 0.12)
      ..lineTo(size.width * 0.90, size.height * 0.50)
      ..lineTo(size.width * 0.11, size.height * 0.88)
      ..lineTo(size.width * 0.23, size.height * 0.57)
      ..lineTo(size.width * 0.55, size.height * 0.50)
      ..lineTo(size.width * 0.23, size.height * 0.43)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

