import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talentbridge/client/client_profile_view_screen.dart';
import 'package:talentbridge/client/hires_screen.dart';
import 'package:talentbridge/client/home_screen.dart';
import 'package:talentbridge/client/message_screen.dart';
import 'package:talentbridge/client/projects_screen.dart';
import 'package:talentbridge/client/search_screen.dart';
import 'package:talentbridge/notifications/client_notification_screen.dart';
import 'package:talentbridge/screens/role_selection_screen.dart';
import 'package:talentbridge/utils/local_storage_utils.dart';

/// Main client dashboard screen that uses a PageView with a custom animated bottom navigation.
class ClientDashboardScreen extends StatefulWidget {
  const ClientDashboardScreen({super.key});

  @override
  State<ClientDashboardScreen> createState() => _ClientDashboardScreenState();
}

class _ClientDashboardScreenState extends State<ClientDashboardScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  String clientName = "Client";
  late dynamic clientData;
  String? profilePath;
  // Define pages corresponding to bottom navigation items.
  final List<Widget> _pages = [
    const HomePage(), // Home: Header, Carousel + Recommended Freelancers + Active Proposals
    const ProjectsPage(), // Projects page
    const MessagesPage(), // Messages page
    const FreelancerSearchPage(), // Freelancer Search page
    // const HiresPage(), // Hires page
  ];

  @override
  void initState() {
    super.initState();
    fetchClientInfo();
  }

  void fetchClientInfo() async {
    // 1. Get local prefs & data
    SharedPreferences prefs = await getLocalUtilResource();
    final data = await getDataFromLocalStorage(prefs, ["name", "email"]);

    print(data);

    if (data == null) return;

    // 2. Read local name immediately
    final fetchedName = data["name"] as String;
    final userEmail = data["email"] as String;

    String? fetchedProfilePath;

    try {
      // 3. Do the Firestore query
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: userEmail)
          .limit(1)
          .get();

          

      if (snapshot.docs.isNotEmpty) {
        final userData = snapshot.docs.first.data();
        clientData = userData;
        fetchedProfilePath = userData["profileImagePath"] as String?;
        await prefs.setString(
          "client_id", userData["uid"] as String
        );
      } else {
        clientData = null;
        debugPrint("No user found with email: $userEmail");
      }
    } catch (e) {
      clientData = null;
      debugPrint("Error fetching user details: $e");
    }

    // 4. Now, synchronously update state exactly once
    if (mounted) {
      setState(() {
        clientName = fetchedName;
        profilePath = fetchedProfilePath;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // _pageController.animateToPage(
    //   index,
    //   duration: const Duration(milliseconds: 300),
    //   curve: Curves.easeInOut,
    // );
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Leading circular avatar to open the drawer.
        leading: Builder(
          builder: (context) => Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              onTap: () => Scaffold.of(context).openDrawer(),
              child:
                  // ← Replace the static const avatar with your conditional:
                  profilePath != null
                      ? profilePath!.startsWith("https")
                          ? CircleAvatar(
                              radius: 20,
                              backgroundImage: NetworkImage(profilePath!),
                            )
                          : File(profilePath!).existsSync()
                              ? CircleAvatar(
                                  radius: 20,
                                  backgroundImage:
                                      FileImage(File(profilePath!)),
                                )
                              : const CircleAvatar(
                                  radius: 20,
                                  child: Icon(Icons.account_circle, size: 20),
                                )
                      : const CircleAvatar(
                          radius: 20,
                          child: Icon(Icons.account_circle, size: 20),
                        ),
            ),
          ),
        ),
        title: const Text(
          "Client Dashboard",
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ClientNotification()));

              // TODO: Navigate to notifications screen.
            },
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        children: _pages,
        onPageChanged: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.grey.shade900,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Drawer header with client profile
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.grey.shade800),
            child: Row(
              children: [
                // Replace with a NetworkImage or AssetImage as needed
                profilePath != null
                    ? profilePath!.startsWith("https")
                        ? CircleAvatar(
                            radius: 30,
                            backgroundImage: NetworkImage(profilePath!),
                          )
                        : File(profilePath!).existsSync()
                            ? CircleAvatar(
                                radius: 30,
                                backgroundImage: FileImage(File(profilePath!)),
                              )
                            : CircleAvatar(
                                radius: 30,
                                child: Icon(Icons.account_circle, size: 30),
                              )
                    : CircleAvatar(
                        radius: 30,
                        child: Icon(Icons.account_circle, size: 30),
                      ),

                const SizedBox(width: 16),
                Text(
                  '$clientName',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          // My Profile
          ListTile(
            leading: const Icon(Icons.person, color: Colors.white),
            title:
                const Text('My Profile', style: TextStyle(color: Colors.white)),
            onTap: () {
              // Navigate to My Profile screen
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ClientProfileScreen(
                            clientData: clientData,
                          )));
            },
          ),
          // Post a Project
          ListTile(
            leading: const Icon(Icons.add_circle_outline, color: Colors.white),
            title: const Text('Post a Project',
                style: TextStyle(color: Colors.white)),
            onTap: () {
              // Navigate to Post a Project screen
            },
          ),
          // Settings
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.white),
            title:
                const Text('Settings', style: TextStyle(color: Colors.white)),
            onTap: () {
              // Navigate to Settings screen
            },
          ),
          // Logout
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.white),
            title: const Text('Logout', style: TextStyle(color: Colors.white)),
            onTap: () async {
              // Handle logout logic here
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RoleSelectionScreen(),
                  ),
                  (Route) => false);
            },
          ),
        ],
      ),
    );
  }
}

/// Custom bottom navigation bar widget.
class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onItemTapped;

  const CustomBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onItemTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          _buildNavItem(context, Icons.home, "Home", 0),
          _buildNavItem(context, Icons.work, "My Jobs", 1),
          _buildNavItem(context, Icons.chat, "Messages", 2),
          _buildNavItem(context, Icons.search, "Search", 3),
          // _buildNavItem(context, Icons.assignment_ind, "Hires", 4),
        ],
      ),
    );
  }

  Widget _buildNavItem(
      BuildContext context, IconData icon, String label, int index) {
    final bool isSelected = currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => onItemTapped(index),
        borderRadius: BorderRadius.circular(50),
        splashColor: Colors.lightBlueAccent.withOpacity(0.5),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Wrap the icon in a fixed circular container.
              ClipOval(
                child: Container(
                  width: 40,
                  height: 30,
                  alignment: Alignment.center,
                  child: Icon(
                    icon,
                    color: isSelected ? Colors.lightBlueAccent : Colors.white70,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.lightBlueAccent : Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Carousel widget with auto‑swipe, dot indicators, and a production-level "View Details" button.
class CarouselWidget extends StatefulWidget {
  const CarouselWidget({super.key});

  @override
  State<CarouselWidget> createState() => _CarouselWidgetState();
}

class _CarouselWidgetState extends State<CarouselWidget> {
  final PageController _pageController = PageController(initialPage: 0);
  late Timer _timer;
  int _currentPage = 0;

  final List<Map<String, dynamic>> cardData = [
    {
      'title': 'Flutter App Development',
      'description': 'Build beautiful and performant apps with Flutter.',
      'progress': 0.75,
    },
    {
      'title': 'UI/UX Design',
      'description': 'Create intuitive and engaging user experiences.',
      'progress': 0.85,
    },
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      _currentPage = (_currentPage + 1) % cardData.length;
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildCard(Map<String, dynamic> data, BuildContext context) {
    // Calculate percentage.
    final int percentage = (data['progress'] * 100).toInt();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF3A3D40), Color(0xFF1F2125)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data['title'],
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                data['description'],
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: data['progress'],
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Colors.lightBlueAccent,
                ),
              ),
              const SizedBox(height: 16),
              // Row with percentage text and "View Details" button.
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "$percentage% Completed",
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Handle view details action.
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: const Text(
                      "View Details",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(cardData.length, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index ? 12 : 8,
          height: _currentPage == index ? 12 : 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentPage == index ? Colors.white : Colors.white54,
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double carouselHeight = MediaQuery.of(context).size.width * 0.6;
    return Column(
      children: [
        SizedBox(
          height: carouselHeight,
          child: PageView.builder(
            controller: _pageController,
            itemCount: cardData.length,
            onPageChanged: (int index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              return _buildCard(cardData[index], context);
            },
          ),
        ),
        const SizedBox(height: 12),
        _buildIndicators(),
      ],
    );
  }
}

// /// Recommended Freelancers Section with header and vertical scrollable list.
// class RecommendedFreelancersSection extends StatelessWidget {
//   const RecommendedFreelancersSection({super.key});

//   final List<Map<String, dynamic>> freelancerData = const [
//     {
//       'name': 'John Doe',
//       'skills': 'Flutter, Dart',
//       'rating': 4.5,
//     },
//     {
//       'name': 'Jane Smith',
//       'skills': 'UI/UX, Photoshop',
//       'rating': 4.7,
//     },
//     {
//       'name': 'Mike Johnson',
//       'skills': 'React, Node.js',
//       'rating': 4.3,
//     },
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // Header with title and Explore button.
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16.0),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               const Text(
//                 "Recommended Freelancers",
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               TextButton(
//                 onPressed: () {
//                   // TODO: Handle Explore action.
//                 },
//                 child: const Text(
//                   "Explore",
//                   style: TextStyle(
//                     color: Colors.lightBlueAccent,
//                     fontSize: 16,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//         const SizedBox(height: 8),
//         ListView.builder(
//           itemCount: freelancerData.length,
//           shrinkWrap: true,
//           physics: const NeverScrollableScrollPhysics(),
//           itemBuilder: (context, index) {
//             final freelancer = freelancerData[index];
//             return Padding(
//               padding:
//                   const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
//               child: Card(
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(16),
//                 ),
//                 clipBehavior: Clip.antiAlias, // Clipping the ripple effect.
//                 color: const Color(0xFF2D3033),
//                 elevation: 4,
//                 child: ListTile(
//                   leading: CircleAvatar(
//                     backgroundColor: Colors.lightBlueAccent,
//                     child: Text(
//                       freelancer['name'][0],
//                       style: const TextStyle(color: Colors.white),
//                     ),
//                   ),
//                   title: Text(
//                     freelancer['name'],
//                     style: const TextStyle(
//                         color: Colors.white, fontWeight: FontWeight.bold),
//                   ),
//                   subtitle: Text(
//                     freelancer['skills'],
//                     style: const TextStyle(color: Colors.white70),
//                   ),
//                   trailing: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       const Icon(Icons.star, color: Colors.amber, size: 20),
//                       const SizedBox(width: 4),
//                       Text(
//                         freelancer['rating'].toString(),
//                         style: const TextStyle(color: Colors.white),
//                       ),
//                     ],
//                   ),
//                   onTap: () {
//                     // TODO: Handle tap on freelancer card.
//                   },
//                 ),
//               ),
//             );
//           },
//         ),
//       ],
//     );
//   }
// }

/// Active Proposals Section with header and vertical scrollable list.
class ActiveProposalsSection extends StatelessWidget {
  const ActiveProposalsSection({super.key});

  // Dummy proposals data.
  final List<Map<String, dynamic>> proposalsData = const [
    {
      'freelancer': 'Aarav Sharma',
      'bid': '₹600',
      'timeline': '1 week',
      'summary':
          'Experienced in backend development and scalable architecture. Can deliver efficient solutions.',
      'time': 'Just now',
    },
    {
      'freelancer': 'Bhavya Mehta',
      'bid': '₹750',
      'timeline': '12 days',
      'summary':
          'Skilled in frontend frameworks and modern UI design. Would love to work on this project.',
      'time': '30 minutes ago',
    },
    {
      'freelancer': 'Chirag Patel',
      'bid': '₹480',
      'timeline': '2 weeks',
      'summary':
          'Have worked on multiple cross-platform apps using Flutter. Ready to start immediately.',
      'time': '1 hour ago',
    },
    {
      'freelancer': 'Deepika Rao',
      'bid': '₹550',
      'timeline': '10 days',
      'summary':
          'Experienced in both Android and iOS development. Can ensure top-quality work.',
      'time': '2 hours ago',
    },
    {
      'freelancer': 'Esha Kulkarni',
      'bid': '₹620',
      'timeline': '8 days',
      'summary':
          'Proficient in Flutter and Dart. Focused on performance and clean code.',
      'time': '3 hours ago',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with title and Explore button.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Active Proposals",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Handle Explore action.
                },
                child: const Text(
                  "Explore",
                  style: TextStyle(
                    color: Colors.lightBlueAccent,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          itemCount: proposalsData.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final proposal = proposalsData[index];
            return Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                color: const Color(0xFF2D3033),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        proposal['freelancer'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Bid: ${proposal['bid']} • Timeline: ${proposal['timeline']}",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        proposal['summary'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            proposal['time'],
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              // TODO: Handle review proposal action.
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.lightBlueAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                            child: const Text(
                              "Review Proposal",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Widget that adds a hover/tap animation effect.
class AnimatedHoverCard extends StatefulWidget {
  final Widget child;
  const AnimatedHoverCard({super.key, required this.child});

  @override
  State<AnimatedHoverCard> createState() => _AnimatedHoverCardState();
}

class _AnimatedHoverCardState extends State<AnimatedHoverCard> {
  bool _isHovered = false;
  bool _isTapped = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isTapped = true),
        onTapUp: (_) => setState(() => _isTapped = false),
        onTapCancel: () => setState(() => _isTapped = false),
        child: AnimatedScale(
          scale: _isTapped
              ? 0.97
              : _isHovered
                  ? 1.02
                  : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutQuad,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            transform: Matrix4.identity()
              ..translate(0.0, _isHovered ? -4.0 : 0.0, 0.0),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
