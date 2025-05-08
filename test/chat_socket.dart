// chat_socket.dart
import 'package:socket_io_client/socket_io_client.dart' as IO;

class ChatSocket {
  late IO.Socket socket;

  ChatSocket() {
    // Connect to the server
    socket = IO.io('http://localhost:3000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    // Connect manually
    socket.connect();

    // Handle connection
    socket.onConnect((_) {
      print('Connected to chat server');
    });

    // Listen for incoming messages
    socket.on('chat message', (data) {
      print('Message received: $data');
      // You can add code here to update your UI or state management solution.
    });

    // Handle disconnects
    socket.onDisconnect((_) {
      print('Disconnected from chat server');
    });
  }

  // Method to send a chat message
  void sendMessage(String message) {
    socket.emit('chat message', message);
  }

  // Disconnect the socket when needed
  void disconnect() {
    socket.disconnect();
  }
}
