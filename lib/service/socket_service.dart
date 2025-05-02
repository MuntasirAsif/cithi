import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  late IO.Socket socket;
  String? mySocketId;

  void connect() {
    print('Connecting.........');
    socket = IO.io(
      'https://0d82-43-251-86-49.ngrok-free.app/',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableReconnection()
          .build(),
    );

    socket.connect();

    socket.onConnect((_) {
      if (kDebugMode) print('Connected to server');
    });

    socket.onDisconnect((_) {
      if (kDebugMode) print('Disconnected');
    });

    socket.onConnectError((err) {
      if (kDebugMode) print('Connect error: $err');
    });

    socket.on('user_id', (data) {
      mySocketId = data;
      if (kDebugMode) print("My Socket ID: $mySocketId");
    });
  }

  void joinRoom(String roomId) {
    socket.emit('join-room', roomId);
  }

  void sendGlobalMessage(String name, String message) {
    socket.emit('sendData', {"name": name, "message": message});
  }

  void sendGroupMessage(String roomId, String name, String message) {
    socket.emit('group-message', {"roomId": roomId, "name": name, "message": message});
  }

  void sendPrivateMessage(String toSocketId, String name, String message) {
    socket.emit('private-message', {
      "toSocketId": toSocketId,
      "name": name,
      "message": message
    });
  }
}
