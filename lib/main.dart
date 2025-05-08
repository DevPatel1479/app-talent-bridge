import 'package:flutter/material.dart';
// import 'package:talentbridge/model/StateDistrictDataModel.dart';
import 'screens/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
      options: FirebaseOptions(
    apiKey: "",
    appId: "",
    messagingSenderId: "",
    projectId: "",
    storageBucket: "",
  ));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Freelancing App',
      theme: ThemeData(
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: Colors.transparent,
          fontFamily: 'Inter'),
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return Container(
          color: Colors.black, // or your matching dark color/gradient
          child: child,
        );
      },
      home: const SplashScreen(),
    );
  }
}
