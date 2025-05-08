import 'package:flutter/material.dart';

class FreelancerSearchPage extends StatefulWidget {
  const FreelancerSearchPage({Key? key}) : super(key: key);

  @override
  _FreelancerSearchPageState createState() => _FreelancerSearchPageState();
}

class _FreelancerSearchPageState extends State<FreelancerSearchPage> {
  final TextEditingController _searchController = TextEditingController();

  // Dummy data representing freelancers.
  final List<Map<String, dynamic>> dummyFreelancers = [
    {
      'name': 'Jatin Pandit',
      'skills': 'UI/UX Design, Photoshop',
      'rating': 4.5,
      'hourlyRate': '₹500/hr',
      'location': 'Mumbai, India',
    },
    {
      'name': 'Vivek Singh',
      'skills': 'Flutter, Dart, Mobile Development',
      'rating': 4.8,
      'hourlyRate': '₹700/hr',
      'location': 'Bangalore, India',
    },
    {
      'name': 'Priya Mehta',
      'skills': 'Web Development, React, Node.js',
      'rating': 4.2,
      'hourlyRate': '₹600/hr',
      'location': 'Hyderabad, India',
    },
    {
      'name': 'Ruhini Shah',
      'skills': 'Content Writing, SEO, Copywriting',
      'rating': 4.7,
      'hourlyRate': '₹400/hr',
      'location': 'Delhi, India',
    },
    {
      'name': 'Sachin Trivedi',
      'skills': 'Graphic Design, Illustrator, Branding',
      'rating': 4.4,
      'hourlyRate': '₹550/hr',
      'location': 'Chennai, India',
    },
  ];

  List<Map<String, dynamic>> filteredFreelancers = [];
  String _selectedFilter = "All";

  @override
  void initState() {
    super.initState();
    filteredFreelancers = dummyFreelancers;
    _searchController.addListener(_filterFreelancers);
  }

  void _filterFreelancers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredFreelancers = dummyFreelancers.where((freelancer) {
        final name = freelancer['name'].toLowerCase();
        final skills = freelancer['skills'].toLowerCase();
        return name.contains(query) || skills.contains(query);
      }).toList();
    });
  }

  void _selectFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      if (filter == "All") {
        filteredFreelancers = dummyFreelancers;
      } else {
        filteredFreelancers = dummyFreelancers.where((freelancer) {
          return freelancer['skills']
              .toLowerCase()
              .contains(filter.toLowerCase());
        }).toList();
      }
    });
  }

  // Build freelancer card widget.
  Widget buildFreelancerCard(Map<String, dynamic> freelancer,
      double screenWidth, double screenHeight) {
    return Card(
      color: Colors.grey.shade800,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.symmetric(
          vertical: screenHeight * 0.01, horizontal: screenWidth * 0.01),
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Selected ${freelancer['name']}")),
          );
        },
        borderRadius: BorderRadius.circular(12),
        splashColor: Colors.amber.withOpacity(0.3),
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: Row(
            children: [
              CircleAvatar(
                radius: screenWidth * 0.07,
                backgroundColor: Colors.lightBlueAccent,
                child: Text(
                  freelancer['name'].substring(0, 1),
                  style: TextStyle(
                    fontSize: screenWidth * 0.07,
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
                      freelancer['name'],
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth * 0.05,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.005),
                    Text(
                      freelancer['skills'],
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: screenWidth * 0.04,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: screenHeight * 0.005),
                    Row(
                      children: [
                        Icon(Icons.star,
                            color: Colors.amber, size: screenWidth * 0.045),
                        SizedBox(width: 4),
                        Text(
                          freelancer['rating'].toString(),
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: screenWidth * 0.04,
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.04),
                        Text(
                          freelancer['hourlyRate'],
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: screenWidth * 0.04,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.005),
                    Text(
                      freelancer['location'],
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: screenWidth * 0.04,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  color: Colors.white54, size: screenWidth * 0.045),
            ],
          ),
        ),
      ),
    );
  }

  // Build filter chips.
  Widget buildFilterBar(double screenWidth) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChoiceChip(
            label: Text("All"),
            labelStyle: TextStyle(
              color: _selectedFilter == "All" ? Colors.black : Colors.white,
            ),
            selected: _selectedFilter == "All",
            selectedColor: Colors.lightBlueAccent.withOpacity(0.4),
            backgroundColor: Colors.grey.shade800,
            onSelected: (_) => _selectFilter("All"),
          ),
          SizedBox(width: screenWidth * 0.02),
          ChoiceChip(
            label: Text("Design"),
            labelStyle: TextStyle(
              color: _selectedFilter == "Design" ? Colors.black : Colors.white,
            ),
            selected: _selectedFilter == "Design",
            selectedColor: Colors.lightBlueAccent.withOpacity(0.4),
            backgroundColor: Colors.grey.shade800,
            onSelected: (_) => _selectFilter("Design"),
          ),
          SizedBox(width: screenWidth * 0.02),
          ChoiceChip(
            label: Text("Development"),
            labelStyle: TextStyle(
              color: _selectedFilter == "Development"
                  ? Colors.black
                  : Colors.white,
            ),
            selected: _selectedFilter == "Development",
            selectedColor: Colors.lightBlueAccent.withOpacity(0.4),
            backgroundColor: Colors.grey.shade800,
            onSelected: (_) => _selectFilter("Development"),
          ),
          SizedBox(width: screenWidth * 0.02),
          ChoiceChip(
            label: Text("Writing"),
            labelStyle: TextStyle(
              color: _selectedFilter == "Writing" ? Colors.black : Colors.white,
            ),
            selected: _selectedFilter == "Writing",
            selectedColor: Colors.lightBlueAccent.withOpacity(0.4),
            backgroundColor: Colors.grey.shade800,
            onSelected: (_) => _selectFilter("Writing"),
          ),
        ],
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
        title: const Text("Browse Freelancer",
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        // No group chat button is included.
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(screenSize.width * 0.05),
          child: Column(
            children: [
              // Search bar.
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
              // Filter chips.
              buildFilterBar(screenSize.width),
              SizedBox(height: screenSize.height * 0.02),
              // Freelancer list.
              Expanded(
                child: ListView.builder(
                  itemCount: filteredFreelancers.length,
                  itemBuilder: (context, index) {
                    return buildFreelancerCard(filteredFreelancers[index],
                        screenSize.width, screenSize.height);
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
