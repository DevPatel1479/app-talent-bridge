import 'package:flutter/material.dart';
import 'package:talentbridge/screens/client_dashboard_screen.dart';
import 'package:talentbridge/utils/local_storage_utils.dart';
import 'role_selection_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool? isLoggedIn;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await getLocalUtilResource();
    final data = await getDataFromLocalStorage(prefs, ["isLoggedIn"]);
    dynamic loginStatus = data["isLoggedIn"];

    Future.delayed(const Duration(seconds: 3), () {
      if (loginStatus != null && loginStatus == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => const ClientDashboardScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Image.asset("assets/app_icon.png", width: 200, height: 200,),
      ),
    );
  }
}
