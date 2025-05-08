import 'package:flutter/material.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({Key? key}) : super(key: key);

  @override
  _MessagesPageState createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final TextEditingController _searchController = TextEditingController();

  // Dummy data for chat list – each representing a freelancer chat.
  final List<Map<String, String>> dummyChats = [
    {
      'name': 'Aarav Mehta',
      'lastMessage': 'Are you ready for tomorrow’s presentation?',
      'time': '10:45 AM'
    },
    {
      'name': 'Sneha Sharma',
      'lastMessage': 'I’ve sent the document on email.',
      'time': '9:30 AM'
    },
    {
      'name': 'Rohan Kapoor',
      'lastMessage': 'We might need to reschedule the client call.',
      'time': 'Yesterday'
    },
    {
      'name': 'Priya Verma',
      'lastMessage': 'The designs look good, great job!',
      'time': 'Yesterday'
    },
    {
      'name': 'Vikram Singh',
      'lastMessage': 'I’ve sent the invoice, please check.',
      'time': '2 days ago'
    },
  ];
  List<Map<String, String>> filteredChats = [];

  @override
  void initState() {
    super.initState();
    filteredChats = dummyChats;
    _searchController.addListener(_filterChats);
  }

  void _filterChats() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredChats = dummyChats.where((chat) {
        final name = chat['name']!.toLowerCase();
        return name.contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Build each chat item with freelancer profile.
  Widget buildChatItem(
      Map<String, String> chat, double screenWidth, double screenHeight) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
      child: Material(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Chat with ${chat['name']}")),
            );
          },
          borderRadius: BorderRadius.circular(12),
          splashColor: Colors.amber.withOpacity(0.3),
          hoverColor: Colors.grey.shade700,
          child: Padding(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: Row(
              children: [
                // Freelancer profile avatar with initials.
                CircleAvatar(
                  radius: screenWidth * 0.06,
                  backgroundColor: Colors.lightBlueAccent,
                  child: Text(
                    chat['name']!.substring(0, 1),
                    style: TextStyle(
                      fontSize: screenWidth * 0.06,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: screenWidth * 0.04),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chat['name']!,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth * 0.045,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.005),
                      Text(
                        chat['lastMessage']!,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: screenWidth * 0.04,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Text(
                  chat['time']!,
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: screenWidth * 0.035,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size and orientation.
    final screenSize = MediaQuery.of(context).size;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    // If in landscape mode, show a full-screen warning.
    if (isLandscape) {
      return Scaffold(
        backgroundColor: Colors.grey.shade900,
        body: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Landscape mode is not supported. Please switch to portrait mode.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenSize.width * 0.045,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      appBar: AppBar(
        title: const Text(
          "Chat With Freelancers",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        actions: [
          // Elevated icon button on top right for Create Group Chat.
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Create Group Chat')),
              );
            },
            icon: const Icon(Icons.group, color: Colors.black),
            label: const Text(
              "Create Group",
              style: TextStyle(color: Colors.black),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.lightBlueAccent,
              elevation: 0,
            ),
          ),
          SizedBox(width: screenSize.width * 0.02),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(screenSize.width * 0.05),
          child: Column(
            children: [
              // Search bar for filtering freelancers.
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: screenSize.width * 0.03,
                  vertical: screenSize.height * 0.01,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search Freelancer',
                    hintStyle: const TextStyle(color: Colors.white54),
                    border: InputBorder.none,
                    icon: const Icon(Icons.search, color: Colors.white),
                  ),
                ),
              ),
              SizedBox(height: screenSize.height * 0.02),
              // Chat list.
              Expanded(
                child: ListView.builder(
                  itemCount: filteredChats.length,
                  itemBuilder: (context, index) {
                    return buildChatItem(filteredChats[index], screenSize.width,
                        screenSize.height);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
