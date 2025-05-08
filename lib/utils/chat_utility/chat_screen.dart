// chat_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'chat_socket.dart';

class ChatScreen extends StatefulWidget {
  final ChatSocket chatSocket;
  final String chatId;
  final Map<String, dynamic> otherUser;

  const ChatScreen({
    super.key,
    required this.chatSocket,
    required this.chatId,
    required this.otherUser,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _initPreferences();
    _setupSocket();
    _loadMessages();
    _updatePresence();
  }

  Future<void> _initPreferences() async {
    _prefs = await SharedPreferences.getInstance();
  }

  void _setupSocket() {
    widget.chatSocket.socket.emit('join_chat', widget.chatId);
    widget.chatSocket.socket.on('${widget.chatId}_message', (data) {
      setState(() => _messages.add(Map<String, dynamic>.from(data)));
      _updateChatLastMessage(data['text']);
    });
  }

  Future<void> _loadMessages() async {
    final messages = await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .get();

    setState(() => _messages.addAll(messages.docs.map((doc) => doc.data())));
  }

  void _updatePresence() async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_prefs.getString('phone'))
        .update({'lastActive': FieldValue.serverTimestamp()});
  }

  void _sendMessage() async {
    if (_messageController.text.isEmpty) return;

    // Create basic message object
    final message = {
      'sender': _prefs.getString('phone')!,
      'text': _messageController.text,
      'timestamp':
          DateTime.now().toUtc().toIso8601String(), // Convert to string
    };

    // Save to Firestore with server timestamp
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .add({
      ...message,
      'timestamp': FieldValue.serverTimestamp(), // Use FieldValue only here
    });

    // Send via socket with string timestamp
    widget.chatSocket.sendMessage({
      ...message,
      'chatId': widget.chatId,
    });

    _messageController.clear();
    _updateChatLastMessage(message['text']!);
  }

  Future<void> _updateChatLastMessage(String text) async {
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .update({
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.otherUser['name']),
            StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.otherUser['phone'])
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Container();
                final lastActive = snapshot.data!['lastActive']?.toDate();
                return Text(
                  lastActive != null
                      ? DateFormat('hh:mm a').format(lastActive)
                      : 'Offline',
                  style: const TextStyle(fontSize: 12),
                );
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages.reversed.toList()[index];
                return _ChatBubble(
                  message: message,
                  isMe: message['sender'] == _prefs.getString('phone'),
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isMe;

  const _ChatBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final timestamp = message['timestamp'] is Timestamp
        ? message['timestamp'].toDate()
        : DateTime.parse(message['timestamp']);

    final time = DateFormat('HH:mm').format(timestamp);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue.shade100 : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(message['text']),
            Text(time,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                )),
          ],
        ),
      ),
    );
  }
}
