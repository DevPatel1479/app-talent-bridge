
///  ** [main], chat socket [ChatSocket]
library;


import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'signup_screen.dart';
import 'users_screen.dart';

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

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        appBarTheme: const AppBarTheme(elevation: 0),
      ),
      home: FutureBuilder(
        future: SharedPreferences.getInstance(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final prefs = snapshot.data!;
            return prefs.getString('phone') == null
                ? const SignupScreen()
                : const UsersScreen();
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}


