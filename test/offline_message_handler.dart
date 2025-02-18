import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OfflineMessageHandler {
  static Database? _database;

  // Initialize the local SQLite database.
  static Future<void> initialize() async {
    _database = await openDatabase(
      join(await getDatabasesPath(), 'offline_messages.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE messages(id INTEGER PRIMARY KEY AUTOINCREMENT, senderName TEXT, senderPhone TEXT, message TEXT, timestamp INTEGER)',
        );
      },
      version: 1,
    );
  }

  // Insert a message into the local database.
  static Future<void> insertOfflineMessage(
      Map<String, dynamic> messageData) async {
    final db = _database;
    if (db == null) return;
    await db.insert(
      'messages',
      {
        'senderName': messageData['senderName'],
        'senderPhone': messageData['senderPhone'],
        'message': messageData['message'],
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Retrieve all offline messages.
  static Future<List<Map<String, dynamic>>> getOfflineMessages() async {
    final db = _database;
    if (db == null) return [];
    return await db.query('messages');
  }

  // Clear the local messages after sending.
  static Future<void> clearOfflineMessages() async {
    final db = _database;
    if (db == null) return;
    await db.delete('messages');
  }

  // Attempt to send any offline messages to Firestore.
  static Future<void> sendOfflineMessages() async {
    List<Map<String, dynamic>> offlineMessages = await getOfflineMessages();
    for (var message in offlineMessages) {
      Map<String, dynamic> messageData = {
        'senderName': message['senderName'],
        'senderPhone': message['senderPhone'],
        'message': message['message'],
        'timestamp': FieldValue.serverTimestamp(),
        'isTyping': false,
      };
      try {
        await FirebaseFirestore.instance
            .collection('messages')
            .add(messageData);
      } catch (e) {
        // If sending fails (still offline), exit and try later.
        return;
      }
    }
    await clearOfflineMessages();
  }
}
