import 'dart:io';
import 'package:flutter/material.dart';

class ClientProfileScreen extends StatefulWidget {
  final Map<String, dynamic> clientData;

  const ClientProfileScreen({Key? key, required this.clientData})
      : super(key: key);

  @override
  _ClientProfileScreenState createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen>
    with SingleTickerProviderStateMixin {
  late final String? profilePath;
  late final String clientName;
  late final String clientEmail;
  late final String clientState;
  late final String clientDistrict;

  late final AnimationController _controller;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    // Extract values from passed-in clientData
    profilePath = widget.clientData['profileImagePath'] as String?;
    clientName = widget.clientData['name'] ?? 'Unknown';
    clientEmail = widget.clientData['email'] ?? 'No Email';
    clientState = widget.clientData['state'] ?? 'Unknown';
    clientDistrict = widget.clientData['district'] ?? 'Unknown';

    // Animation for glowing effect
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 4.0, end: 16.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      appBar: AppBar(
        leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(
              Icons.arrow_back,
              color: Colors.white,
            )),
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'My Profile',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Animated glowing avatar
            AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, child) {
                return Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.6),
                        blurRadius: _glowAnimation.value,
                        spreadRadius: _glowAnimation.value / 2,
                      ),
                    ],
                  ),
                  child: _buildProfileAvatar(),
                );
              },
            ),
            const SizedBox(height: 24),

            // Client information
            _infoCard(Icons.person, 'Name', clientName),
            _infoCard(Icons.email, 'Email', clientEmail),
            _infoCard(Icons.map, 'Location', '$clientState, $clientDistrict'),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    if (profilePath != null) {
      if (profilePath!.startsWith('https')) {
        return CircleAvatar(
          radius: 60,
          backgroundImage: NetworkImage(profilePath!),
        );
      } else if (File(profilePath!).existsSync()) {
        return CircleAvatar(
          radius: 60,
          backgroundImage: FileImage(File(profilePath!)),
        );
      }
    }
    // Fallback icon
    return const CircleAvatar(
      radius: 60,
      child: Icon(Icons.account_circle, size: 60),
    );
  }

  Widget _infoCard(IconData icon, String label, String value) {
    return Card(
      color: Colors.grey.shade800,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
