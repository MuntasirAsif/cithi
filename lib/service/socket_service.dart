import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class SocketService {
  late io.Socket socket;
  String? mySocketId;

  void connect({required String userId}) {
    debugPrint('Connecting.........');
    socket = io.io(
      'https://18a1-43-251-86-49.ngrok-free.app/',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableReconnection()
          .build(),
    );

    // Only emit after connected
    socket.connect();

    socket.onConnect((_) {
      debugPrint('Connected to server: $userId');

      // Emit custom user ID after successful connection
      socket.emit('set-user-id', userId);
    });

    socket.onDisconnect((_) {
      debugPrint('Disconnected');
    });

    socket.onConnectError((err) {
      debugPrint('Connect error: $err');
    });

    socket.on('socket_id', (data) {
      mySocketId = data;
      debugPrint("My Socket ID: $mySocketId");
    });
  }


  void joinRoom(String roomId) {
    socket.emit('join-room', roomId);
  }

  void sendGlobalMessage(String name, String message) {
    socket.emit('sendData', {"name": name, "message": message});
  }

  void sendGroupMessage(String roomId, String name, String message) {
    socket.emit('group-message', {
      "roomId": roomId,
      "name": name,
      "message": message,
    });
  }

  void sendPrivateMessage(String toUserId, String name, String message) {
    socket.emit('private-message', {
      "toUserId": toUserId,
      "name": name,
      "message": message,
    });
  }
}
