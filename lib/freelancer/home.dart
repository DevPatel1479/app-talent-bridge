import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';
import './job_card.dart';

class HomeScreen extends StatefulWidget {
  final bool isNewUser;

  const HomeScreen({super.key, this.isNewUser = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  Map<String, dynamic>? userData;
  bool _showProfilePrompt = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // _loadUserProfile();
  }

  // Future<void> _loadUserProfile() async {
  //   final userId =
  //       Provider.of<AuthService>(context, listen: false).currentUser?.uid;
  //   if (userId == null) return;

  //   try {
  //     final profile =
  //         await Provider.of<FirestoreService>(context, listen: false)
  //             .getUserProfile(userId);

  //     setState(() {
  //       userData = profile;
  //       _isLoading = false;
  //       _showProfilePrompt =
  //           widget.isNewUser && (profile['profileComplete'] != true);
  //     });
  //   } catch (e) {
  //     setState(() => _isLoading = false);
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Failed to load profile: ${e.toString()}')),
  //     );
  //   }
  // }

  // void _navigateToProfile() {
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => UserProfileEditor(
  //         userId:
  //             Provider.of<AuthService>(context, listen: false).currentUser!.uid,
  //       ),
  //     ),
  //   ).then((_) => _loadUserProfile());
  // }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Professional Network'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: const [
              JobCard(),
              Center(child: Text('Network')),
              Center(child: Text('Notifications')),
              Center(child: Text('Jobs')),
            ],
          ),
          if (_showProfilePrompt)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: _buildProfilePrompt(),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Network',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work),
            label: 'Jobs',
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePrompt() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Complete Your Profile',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please complete your profile to get the best experience',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => setState(() => _showProfilePrompt = false),
                  child: const Text('Later'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: null,
                  child: const Text('Complete Now'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    // final authService = Provider.of<AuthService>(context);
    // final user = authService.currentUser;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pop(context); // Close drawer
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(
              //     builder: (context) =>
              //         FreelancerProfilePage(userProfile: userData),
              //   ),
              // );
            },
            child: UserAccountsDrawerHeader(
              accountName: Text(
                userData?['name'] ?? 'No Name',
                style: const TextStyle(fontSize: 16),
              ),
              accountEmail: Text(
                userData?['email'] ?? 'No Email',
                style: const TextStyle(fontSize: 14),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage: userData?['profileImageUrl'] != null
                    ? CachedNetworkImageProvider(userData!['profileImageUrl'])
                    : null,
                child: userData?['profileImageUrl'] == null
                    ? const Icon(Icons.person, size: 40)
                    : null,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Edit Profile'),
            onTap: () {
              Navigator.pop(context);
              // _navigateToProfile();
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(
              //     builder: (context) => const SettingsScreen(),
              //   ),
              // );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              Navigator.pop(context);
              try {
                // await authService.signOut();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString())),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
