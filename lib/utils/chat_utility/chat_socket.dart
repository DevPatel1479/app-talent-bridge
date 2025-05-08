// chat_socket.dart
import 'package:socket_io_client/socket_io_client.dart' as IO;

class ChatSocket {
  late IO.Socket socket;
  static const String serverUrl =
      'https://chatsocket-production.up.railway.app/'; // Replace with your server URL

  ChatSocket() {
    socket = IO.io(
      serverUrl,
      IO.OptionBuilder().setTransports(['websocket']).enableForceNew().build(),
    );

    socket.onConnect((_) => print('Connected to chat server'));
    socket.onDisconnect((_) => print('Disconnected from chat server'));
    socket.onError((error) => print('Socket error: $error'));
  }

  void sendMessage(Map<String, dynamic> message) {
    if (socket.connected) {
      socket.emit('chat_message', message);
    }
  }

  void disconnect() => socket.disconnect();
}
