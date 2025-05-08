// users_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'chat_screen.dart';
import 'chat_socket.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .orderBy('lastActive', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Text('Error: ${snapshot.error}');
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          return FutureBuilder(
            future: SharedPreferences.getInstance(),
            builder: (context, prefsSnapshot) {
              if (!prefsSnapshot.hasData) return Container();
              final prefs = prefsSnapshot.data!;
              final currentUser = prefs.getString('phone') ?? '';

              return ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final user = snapshot.data!.docs[index];
                  if (user['phone'] == currentUser) return Container();

                  return ListTile(
                    title: Text(user['name']),
                    subtitle: Text(user['phone']),
                    trailing: const Icon(Icons.chat_bubble_outline),
                    onTap: () => _startChat(context, user),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _startChat(BuildContext context, DocumentSnapshot user) async {
    final prefs = await SharedPreferences.getInstance();
    final currentUser = prefs.getString('phone')!;
    final otherUser = user['phone'] as String;

    List<String> participants = [currentUser, otherUser]..sort();
    final chatId = participants.join('_');

    final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);
    await chatRef.set({
      'participants': participants,
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          chatSocket: ChatSocket(),
          chatId: chatId,
          otherUser: user.data() as Map<String, dynamic>,
        ),
      ),
    );
  }
}
