import 'package:flutter/material.dart';

class FreelancerDashBoardScreen extends StatefulWidget {
  const FreelancerDashBoardScreen({super.key});

  @override
  State<FreelancerDashBoardScreen> createState() =>
      _FreelancerDashBoardScreen();
}

class _FreelancerDashBoardScreen extends State<FreelancerDashBoardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.grey[900],
      // Use an AppBar to place the back arrow in the top left corner.
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white,),
          onPressed: () {
            // Handle the back button press, for example:
            Navigator.pop(context);
          },
        ),
      ),
      // Center the animation content responsively.
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RotationTransition(
              turns: _animation,
              child: ScaleTransition(
                scale: Tween(begin: 0.5, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _controller,
                    curve: const Interval(0.0, 1.0, curve: Curves.easeInOut),
                  ),
                ),
                child: Icon(
                  Icons.refresh,
                  size: screenSize.width * 0.2,
                  color: Colors.blueAccent,
                ),
              ),
            ),
            const SizedBox(height: 20),
            FadeTransition(
              opacity: Tween(begin: 0.5, end: 1.0).animate(
                CurvedAnimation(
                  parent: _controller,
                  curve: const Interval(0.0, 1.0, curve: Curves.easeInOut),
                ),
              ),
              child: const Text(
                'Under Development...',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white70,
                  fontWeight: FontWeight.w300,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
