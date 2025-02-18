import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatDetailScreen extends StatefulWidget {
  final String otherUserPhone;
  final String otherUserName;
  const ChatDetailScreen({
    Key? key,
    required this.otherUserPhone,
    required this.otherUserName,
  }) : super(key: key);

  @override
  _ChatDetailScreenState createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  String? currentUserPhone;
  String? currentUserName;
  final TextEditingController _messageController = TextEditingController();

  // We'll store messages in a subcollection of a chat document.
  final CollectionReference messagesCollection =
      FirebaseFirestore.instance.collection('messages');

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      currentUserPhone = prefs.getString('userPhone');
      currentUserName = prefs.getString('userName');
    });
  }

  void _sendMessage() async {
    String text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Create a chat ID based on both users' phone numbers sorted lexicographically.
    List<String> ids = [currentUserPhone!, widget.otherUserPhone]..sort();
    String chatId = ids.join("_");

    Map<String, dynamic> messageData = {
      'senderName': currentUserName,
      'senderPhone': currentUserPhone,
      'receiverPhone': widget.otherUserPhone,
      'message': text,
      'timestamp': FieldValue.serverTimestamp(),
    };

    await messagesCollection.doc(chatId).collection('chats').add(messageData);
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    if (currentUserPhone == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Generate chatId based on current user and other user's phone numbers.
    List<String> ids = [currentUserPhone!, widget.otherUserPhone]..sort();
    String chatId = ids.join("_");

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUserName),
      ),
      body: Column(
        children: [
          // Display chat messages.
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: messagesCollection
                  .doc(chatId)
                  .collection('chats')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                List<DocumentSnapshot> docs = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    bool isMe = data['senderPhone'] == currentUserPhone;
                    return ListTile(
                      title: Align(
                        alignment:
                            isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.blueAccent : Colors.grey[300],
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Text(
                            data['message'] ?? '',
                            style: TextStyle(
                              color: isMe ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Message input field and send button.
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
