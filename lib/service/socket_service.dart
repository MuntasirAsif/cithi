import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class SocketService {
  late io.Socket socket;
  String? mySocketId;

  void connect({required String userId}) {
    try {
      debugPrint('Connecting.........');
      socket = io.io(
        'https://9461-137-59-180-113.ngrok-free.app/',
        io.OptionBuilder()
            .setTransports(['websocket'])
            .enableReconnection()
            .build(),
      );
    } catch (e) {
      debugPrint('Error connecting to server: $e');
    }

    /// Only emit after connected
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

  /// WebRTC Signaling Methods

  void sendOffer(String targetId, Map<String, dynamic> offer) {
    socket.emit('offer', {"targetId": targetId, "offer": offer});
  }

  void sendAnswer(String targetId, Map<String, dynamic> answer) {
    socket.emit('answer', {"targetId": targetId, "answer": answer});
  }

  void sendIceCandidate(String targetId, Map<String, dynamic> candidate) {
    socket.emit('ice-candidate', {
      "targetId": targetId,
      "candidate": candidate,
    });
  }

  void onOffer(Function(Map<String, dynamic>) handler) {
    socket.on('offer', (data) => handler(Map<String, dynamic>.from(data)));
  }

  void onAnswer(Function(Map<String, dynamic>) handler) {
    socket.on('answer', (data) => handler(Map<String, dynamic>.from(data)));
  }

  void onIceCandidate(Function(Map<String, dynamic>) handler) {
    socket.on(
      'ice-candidate',
      (data) => handler(Map<String, dynamic>.from(data)),
    );
  }
}
