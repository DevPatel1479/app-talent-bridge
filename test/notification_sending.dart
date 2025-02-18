// import 'dart:async';
// import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//     FlutterLocalNotificationsPlugin();

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   // Initialize local notifications
//   var initializationSettingsAndroid =
//       const AndroidInitializationSettings('@mipmap/ic_launcher');
//   var initializationSettings =
//       InitializationSettings(android: initializationSettingsAndroid);
//   await flutterLocalNotificationsPlugin.initialize(initializationSettings);

//   // Initialize Android Alarm Manager
//   await AndroidAlarmManager.initialize();

//   // Schedule an alarm after 10 seconds (change duration as needed)
//   DateTime alarmTime = DateTime.now().add(const Duration(seconds: 10));
//   await AndroidAlarmManager.oneShotAt(
//     alarmTime,
//     0,
//     showNotification,
//     wakeup: true,
//     exact: true,
//     alarmClock: true,
//   );

//   runApp(const MyApp());
// }

// // Function to show a notification
// void showNotification() async {
//   const AndroidNotificationDetails androidPlatformChannelSpecifics =
//       AndroidNotificationDetails(
//     'your_channel_id',
//     'your_channel_name',
//     importance: Importance.max,
//     priority: Priority.high,
//     ticker: 'ticker',
//   );

//   const NotificationDetails platformChannelSpecifics =
//       NotificationDetails(android: androidPlatformChannelSpecifics);

//   await flutterLocalNotificationsPlugin.show(
//     0,
//     'Reminder',
//     'It\'s time for your task!',
//     platformChannelSpecifics,
//   );
// }

// // Flutter UI
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: Scaffold(
//         appBar: AppBar(title: const Text('Alarm Manager Example')),
//         body: const Center(child: Text('Notification will be sent shortly!')),
//       ),
//     );
//   }
// }

import 'dart:async';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

late Database database;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: FirebaseOptions(
          apiKey: "AIzaSyDGliIArwUsGMMRih-YQYC50maswh67pzg",
          appId: "1:331071882476:android:9666bd9cf447126e0dd1c9",
          messagingSenderId: "331071882476",
          projectId: "demofirebaseproject-58990"));

  // ✅ Initialize SQLite database before starting the alarm
  await initDatabase();

  // Initialize local notifications
  var initializationSettingsAndroid =
      const AndroidInitializationSettings('@mipmap/ic_launcher');
  var initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Initialize Android Alarm Manager
  await AndroidAlarmManager.initialize();

  // ✅ Start periodic check for Firebase every 5 seconds
  await AndroidAlarmManager.periodic(
    const Duration(seconds: 2),
    0,
    checkFirebaseForNotifications,
    wakeup: true,
    exact: true,
    allowWhileIdle: true,
  );

  runApp(const MyApp());
}

// ✅ Initialize SQLite database
Future<void> initDatabase() async {
  database = await openDatabase(
    join(await getDatabasesPath(), 'notifications.db'),
    onCreate: (db, version) {
      return db.execute(
        "CREATE TABLE messages (id TEXT PRIMARY KEY)",
      );
    },
    version: 1,
  );
}

// ✅ Check Firebase for new notifications
void checkFirebaseForNotifications() async {
  // ✅ Ensure Firebase is initialized in the background process
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
        options: FirebaseOptions(
            apiKey: "AIzaSyDGliIArwUsGMMRih-YQYC50maswh67pzg",
            appId: "1:331071882476:android:9666bd9cf447126e0dd1c9",
            messagingSenderId: "331071882476",
            projectId: "demofirebaseproject-58990"));
  }

  // ✅ Ensure SQLite is initialized in the background process
  await initDatabase(); // 🔥 Fix: Initialize database before using it

  DatabaseReference ref = FirebaseDatabase.instance.ref("notifications");

  DataSnapshot snapshot = await ref.get();
  if (snapshot.exists) {
    Map<dynamic, dynamic>? data = snapshot.value as Map?;
    if (data != null) {
      for (var key in data.keys) {
        Map<dynamic, dynamic> messageData = data[key];

        String messageId = key;
        String title = messageData["title"] ?? "New Notification";
        String body = messageData["body"] ?? "You have a new message!";

        // ✅ Check if this message ID is new
        bool isNew = await isNewMessage(messageId);
        if (isNew) {
          showNotification(title, body);

          // ✅ Save the message ID in SQLite
          await saveMessageId(messageId);
        }
      }
    }
  }
}

// ✅ Function to check if a message ID is new
Future<bool> isNewMessage(String messageId) async {
  List<Map<String, dynamic>> result = await database.query(
    'messages',
    where: 'id = ?',
    whereArgs: [messageId],
  );
  return result.isEmpty;
}

// ✅ Function to save the message ID in SQLite
Future<void> saveMessageId(String messageId) async {
  await database.insert(
    'messages',
    {'id': messageId},
    conflictAlgorithm: ConflictAlgorithm.ignore,
  );
}

// ✅ Function to show a notification
void showNotification(String title, String body) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'TalentBridge',
    'Notification Updates',
    importance: Importance.max,
    priority: Priority.high,
    ticker: 'ticker',
  );

  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

  await flutterLocalNotificationsPlugin.show(
    0,
    title,
    body,
    platformChannelSpecifics,
  );
}

// ✅ Flutter UI
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('Firebase Notification Example')),
        body: const Center(child: Text('Waiting for Firebase messages...')),
      ),
    );
  }
}
