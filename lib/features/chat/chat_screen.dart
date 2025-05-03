import 'package:flutter/material.dart';
import '../../service/socket_service.dart';

enum ChatMode { global, group, private }

class ChatScreen extends StatefulWidget {
  final ChatMode mode;
  final String name;
  final String? roomId;
  final String? targetSocketId;
  final SocketService socketService;

  const ChatScreen({
    super.key,
    required this.mode,
    required this.name,
    this.roomId,
    this.targetSocketId,
    required this.socketService,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <Map<String, String>>[];

  late final ChatMode _chatMode;
  late final String _name;
  late String _roomId;
  late String _targetUserId;

  @override
  void initState() {
    super.initState();

    _chatMode = widget.mode;
    _name = widget.name;
    _roomId = widget.roomId ?? 'group-room-1';
    _targetUserId = widget.targetSocketId ?? '';

    if (_chatMode == ChatMode.group) {
      widget.socketService.joinRoom(_roomId);
    }

    widget.socketService.socket.on('receiveData', (data) {
      if (data != null) {
        _addMessage(data['name'] ?? 'Unknown', data['message'] ?? '');
      }
    });

    widget.socketService.socket.on('receive-group-message', (data) {
      if (data != null) {
        _addMessage(data['name'] ?? 'Unknown', data['message'] ?? '');
      }
    });

    widget.socketService.socket.on('receive-private-message', (data) {
      if (data != null) {
        _addMessage(data['name'] ?? 'Unknown', data['message'] ?? '');
      }
    });
  }

  void _addMessage(String sender, String text) {
    if (!mounted) return;

    setState(() {
      _messages.add({'sender': sender, 'text': text});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send() {
    final msg = _controller.text.trim();
    if (msg.isEmpty) return;

    switch (_chatMode) {
      case ChatMode.global:
        widget.socketService.sendGlobalMessage(_name, msg);
        break;
      case ChatMode.group:
        widget.socketService.sendGroupMessage(_roomId, _name, msg);
        break;
      case ChatMode.private:
        if (_targetUserId.isNotEmpty) {
          widget.socketService.sendPrivateMessage(_targetUserId, _name, msg);
        } else {
          _addMessage("⚠️ System", "No target user ID provided.");
          return;
        }
        break;
    }

    _controller.clear();
    ChatMode.private == widget.mode?_addMessage(_name, msg): print('not private mode'); // Show own message immediately
  }

  @override
  void dispose() {
    widget.socketService.socket.off('receiveData');
    widget.socketService.socket.off('receive-group-message');
    widget.socketService.socket.off('receive-private-message');

    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = widget.socketService.socket.connected;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Chithi - ${_chatMode.name.toUpperCase()} Chat'),
        backgroundColor: Colors.indigo,
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_chatMode == ChatMode.group) _chatInfo('Group Room ID', _roomId),
            if (_chatMode == ChatMode.private)
              _chatInfo('Private Chat with User ID', _targetUserId),
            widget.socketService.mySocketId != null
                ? _chatInfo('My Socket ID', widget.socketService.mySocketId!)
                : Text('Not connected'),
            if (widget.socketService.mySocketId != null)
              _chatInfo('Is connected', isConnected.toString()),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _messages.length,
                itemBuilder: (_, index) {
                  final msg = _messages[index];
                  final isMe = msg['sender'] == _name;
            
                  return Align(
                    alignment:
                        isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 10,
                      ),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isMe ? Colors.indigo[100] : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            blurRadius: 3,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment:
                            isMe
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                        children: [
                          if (!isMe)
                            Text(
                              msg['sender']!,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          Text(
                            msg['text']!,
                            style: const TextStyle(fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Type message...',
                        fillColor: Colors.grey[200],
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Colors.indigo,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _send,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chatInfo(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: Colors.grey[200],
      width: double.infinity,
      child: Text('$label: $value', style: const TextStyle(fontSize: 13)),
    );
  }
}
