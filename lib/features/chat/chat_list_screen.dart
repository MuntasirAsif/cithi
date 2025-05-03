import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart';
import '../../service/socket_service.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key, required this.name, required this.id});

  final String name;
  final String id;

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final socketService = SocketService();
  String? _mySocketId;

  @override
  void initState() {
    super.initState();
    print(widget.id);
    socketService.connect(userId: widget.id);

    // Listen for connection and set socket ID
    Future.delayed(const Duration(milliseconds: 300), () {
      socketService.socket.onConnect((_) {
        setState(() {
          _mySocketId = socketService.socket.id;
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final TextEditingController _groupController = TextEditingController();
    final TextEditingController _privateIdController = TextEditingController();
    return Scaffold(
      appBar: AppBar(title: const Text("Chithi - Chats")),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(8),
          children: [
            Row(
              children: [
                const Text(
                  "🔘 Global--",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  "My User ID: ${widget.id}",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            ListTile(
              title: const Text('Global Chat'),

              subtitle: Text('Broadcast to all users'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => ChatScreen(
                          mode: ChatMode.global,
                          name: widget.name,
                          socketService: socketService,
                        ),
                  ),
                );
              },
            ),
            const Divider(),

            const Text(
              "👥 Group",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: TextField(
                controller: _groupController,
                decoration: const InputDecoration(
                  labelText: 'Enter Room ID',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (_groupController.text.trim().isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => ChatScreen(
                            mode: ChatMode.group,
                            roomId: _groupController.text.trim(),
                            name: widget.name,
                            socketService: socketService,
                          ),
                    ),
                  );
                }
              },
              child: const Text("Join Group Chat"),
            ),
            const Divider(),

            const Text(
              "🔒 Private",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: TextField(
                controller: _privateIdController,
                decoration: const InputDecoration(
                  labelText: 'Target User ID',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (_privateIdController.text.trim().isNotEmpty) {
                  print(widget.name);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => ChatScreen(
                            mode: ChatMode.private,
                            targetSocketId: _privateIdController.text.toString(),
                            name: widget.name,
                            socketService: socketService,
                          ),
                    ),
                  );
                }
              },
              child: const Text("Start Private Chat"),
            ),
          ],
        ),
      ),
    );
  }
}
