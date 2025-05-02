import 'package:flutter/material.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key, required this.name, required this.id});


  final String name;
  final String id;

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
            const Text("🔘 Global", style: TextStyle(fontWeight: FontWeight.bold)),
            ListTile(
              title: const Text('Global Chat'),
              subtitle: const Text('Broadcast to all users'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    mode: ChatMode.global,
                    name: name,
                  ),
                ));
              },
            ),
            const Divider(),

            const Text("👥 Group", style: TextStyle(fontWeight: FontWeight.bold)),
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
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      mode: ChatMode.group,
                      roomId: _groupController.text.trim(),
                      name: name,
                    ),
                  ));
                }
              },
              child: const Text("Join Group Chat"),
            ),
            const Divider(),

            const Text("🔒 Private", style: TextStyle(fontWeight: FontWeight.bold)),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: TextField(
                controller: _privateIdController,
                decoration: const InputDecoration(
                  labelText: 'Target Socket ID',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (_privateIdController.text.trim().isNotEmpty) {
                  print(name);
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      mode: ChatMode.private,
                      targetSocketId: _privateIdController.text.trim(),
                      name: name,
                    ),
                  ));
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
