// chat main method part

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import '../test/background_tasks.dart';
import '../test/users_list_screen.dart';
import '../test/signup_screen.dart';
import 'chat_screen.dart';

import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
      options: FirebaseOptions(
    apiKey: "AIzaSyBwoYlTn0igozdA589vGzvKhHGtSnFears",
    appId: "1:152470510862:android:b2f004131ba800728a4b5f",
    messagingSenderId: "152470510862",
    projectId: "newtestproject-f7d42",
    storageBucket: "newtestproject-f7d42.appspot.com",
  ));

  // Initialize Firebase if you haven't already:
  // await Firebase.initializeApp();

  // Initialize Android Alarm Manager for background tasks.
  await AndroidAlarmManager.initialize();

  // Schedule a periodic task to run every 15 minutes.
  // Alarm ID 0 is used here (make sure it's unique if you schedule multiple alarms).
  await AndroidAlarmManager.periodic(
    const Duration(minutes: 15),
    0,
    backgroundTaskCallback,
    wakeup: true,
    exact: true,
    allowWhileIdle: true,
  );

  // Check if the user is already signed up.
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isSignedUp = prefs.getBool('isSignedUp') ?? false;

  runApp(MyApp(initialRoute: isSignedUp ? '/chat' : '/signup'));
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  const MyApp({Key? key, required this.initialRoute}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat App',
      initialRoute: initialRoute,
      routes: {
        '/signup': (context) => const SignupScreen(),
        '/users': (context) => const UsersListScreen(),
      },
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
      ),
    );
  }
}
