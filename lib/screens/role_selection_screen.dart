import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:talentbridge/auth/authentication_screen.dart';
import 'package:talentbridge/screens/client_dashboard_screen.dart';
import '../widgets/role_card.dart';
import 'package:flutter/services.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  _RoleSelectionScreenState createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  double _opacity = 0;
  Offset _offsetFreelancer = const Offset(-0.5, 0);
  Offset _offsetClient = const Offset(0.5, 0);

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _opacity = 1;
        _offsetFreelancer = Offset.zero;
        _offsetClient = Offset.zero;
      });
    });
  }

  void _navigateToScreen({Widget? screen}) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen!,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.5, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOutCubic,
              )),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Color(0xFF1A1A1A),
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        child: Container(
          constraints: const BoxConstraints.expand(),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF1A1A1A),
                Color(0xFF121212),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Text(
                    'Choose Your Role',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 800),
                  opacity: _opacity,
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeInOutCubic,
                    offset: _offsetFreelancer,
                    child: RoleCard(
                      title: 'Freelancer',
                      icon: Icons.work,
                      color: Colors.tealAccent[400]!,
                      onTap: () => _navigateToScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 1000),
                  opacity: _opacity,
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeInOutCubic,
                    offset: _offsetClient,
                    child: RoleCard(
                      title: 'Client',
                      icon: Icons.business,
                      color: Colors.blueAccent,
                      onTap: () =>
                          _navigateToScreen(screen: AuthenticationScreen()),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
