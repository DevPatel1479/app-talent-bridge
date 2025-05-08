import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:talentbridge/screens/post_job_screen.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:intl/intl.dart';

class ProjectsPage extends StatefulWidget {
  const ProjectsPage({Key? key}) : super(key: key);

  @override
  _ProjectsPageState createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> projects = [];
  List<Map<String, dynamic>> filteredProjects =
      []; // Define filteredProjects here
  String selectedStatus = 'All';
  String searchQuery = '';
  String client_id = "";
  late WebSocketChannel channel;

  String formatDate(String dateStr) {
    DateTime dateTime = DateTime.parse(dateStr);
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }

  Future<void> setClientId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString("client_id");
    if (id != null) {
      setState(() {
        client_id = id;
      });
    }
  }

  void updateEndpoint() async {
    await setClientId();
    channel = WebSocketChannel.connect(
      Uri.parse(
          'wss://websocket-app-api.onrender.com/get/jobs?client_id=$client_id'),
    );
    channel.stream.listen((message) {
      final decodedMessage = jsonDecode(message);
      final String type = decodedMessage['type'];
      final dynamic data = decodedMessage['data'];
      
      if (mounted) {
        setState(() {
          if (type == 'initial' && data is List) {
            projects = List<Map<String, dynamic>>.from(data);
            // sort by posted_date descending
            projects.sort((a, b) {
              return DateTime.parse(b['posted_date'])
                  .compareTo(DateTime.parse(a['posted_date']));
            });
            print("✅ Initial jobs fetched: ${projects.length}");
            filteredProjects = List.from(
                projects); // Initialize filteredProjects with all jobs
            _isLoading = false;
          } else if (type == 'added') {
            final exists = projects.any((p) => p['job_id'] == data['job_id']);
            if (!exists) {
              projects.insert(0, data);
              filteredProjects.insert(
                  0, data); // Add to filteredProjects as well
              print("➕ Job added: ${data['job_title']}");
            }
          } else if (type == 'modified') {
            final mainIndex =
                projects.indexWhere((p) => p['job_id'] == data['job_id']);
            if (mainIndex != -1) {
              projects[mainIndex] = data;
            }

            // 2) Update filteredProjects in place
            final filteredIndex = filteredProjects
                .indexWhere((p) => p['job_id'] == data['job_id']);
            if (filteredIndex != -1) {
              filteredProjects[filteredIndex] = data;
              print("✏️ Job modified: ${data['job_title']}");
            }
          } else if (type == 'removed') {
            projects.removeWhere((p) => p['job_id'] == data['job_id']);
            filteredProjects.removeWhere((p) => p['job_id'] == data['job_id']);
            _filterProjects(); // reapply filter so the UI updates
            print("❌ Job removed: ${data['job_title']}");
          }
        });
      }
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    updateEndpoint();
  }

  // Method to filter projects based on status and search query
  void _filterProjects() {
    setState(() {
      // Filter projects based on selected status and search query
      filteredProjects = projects.where((project) {
        final matchesStatus = selectedStatus == 'All' ||
            project['status'].toString().toLowerCase() ==
                selectedStatus.toLowerCase();
        final matchesSearch = project['job_title']
            .toLowerCase()
            .contains(searchQuery.toLowerCase());
        return matchesStatus && matchesSearch;
      }).toList()
        ..sort((a, b) {
          return DateTime.parse(b['posted_date'])
              .compareTo(DateTime.parse(a['posted_date']));
        });
    });
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'Active':
        return Colors.greenAccent;
      case 'Pending':
        return Colors.orangeAccent;
      case 'Completed':
        return Colors.blueAccent;
      case 'Cancelled':
        return Colors.redAccent;
      default:
        return Colors.white;
    }
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }

  Widget _buildShimmerCard(Size screenSize) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade800,
        highlightColor: Colors.grey.shade700,
        child: Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade800,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildEditableField({
    required TextEditingController controller,
    required String label,
    int minLines = 1,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        minLines: minLines,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white70),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white24),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blue),
          ),
          border: OutlineInputBorder(),
        ),
        validator: validator,
      ),
    );
  }

  // ✅ Reusable Card Builder with Fixed Size
  Widget _buildCard(String title, String value, Size screenSize,
      {Color? color}) {
    return Card(
      color: Colors.grey.shade800,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Container(
        width: screenSize.width,
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "$title:",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: color ?? Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectCard(Map<String, dynamic> project, Size screenSize) {
    final statusColor = getStatusColor(project['status']);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            hoverColor: Colors.grey.shade700,
            splashColor: Colors.grey.shade600,
            onTap: () {
              print("job id ${project['job_id']}");

              final _formKey = GlobalKey<FormState>();
              final titleController =
                  TextEditingController(text: project['job_title']);
              final descController =
                  TextEditingController(text: project['description']);
              final budgetController =
                  TextEditingController(text: project['budget'].toString());
              final skillsController = TextEditingController(
                text: project['required_skills']?.join(', ') ?? '',
              );

              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (BuildContext context) {
                  final screenSize = MediaQuery.of(context).size;

                  return SafeArea(
                    child: Container(
                      width: screenSize.width,
                      height: screenSize.height,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade900,
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              SizedBox(height: 10),
                              Center(
                                child: Text(
                                  "Job Post Details",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: screenSize.width * 0.06,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              SizedBox(height: 16),
                              Expanded(
                                child: SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      _buildEditableField(
                                        controller: titleController,
                                        label: "Title",
                                        validator: (value) =>
                                            value == null || value.isEmpty
                                                ? "Title required"
                                                : null,
                                      ),
                                      _buildEditableField(
                                        controller: descController,
                                        label: "Description",
                                        minLines: 3,
                                        maxLines: 5,
                                        validator: (value) =>
                                            value == null || value.length < 10
                                                ? "Min 10 characters"
                                                : null,
                                      ),
                                      _buildEditableField(
                                        controller: budgetController,
                                        label: "Budget",
                                        keyboardType: TextInputType.number,
                                        validator: (value) {
                                          if (value == null || value.isEmpty)
                                            return "Budget required";
                                          final parsed = int.tryParse(value);
                                          if (parsed == null || parsed <= 0)
                                            return "Enter a valid number";
                                          return null;
                                        },
                                      ),
                                      TextFormField(
                                        controller: skillsController,
                                        decoration: InputDecoration(
                                          labelText:
                                              "Required Skills (comma separated)",
                                          labelStyle:
                                              TextStyle(color: Colors.white70),
                                          enabledBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: Colors.white54),
                                          ),
                                          focusedBorder: UnderlineInputBorder(
                                            borderSide:
                                                BorderSide(color: Colors.white),
                                          ),
                                        ),
                                        style: TextStyle(color: Colors.white),
                                        validator: (value) {
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return "Required skills cannot be empty";
                                          }
                                          if (!value.contains(',')) {
                                            return "Separate skills with commas";
                                          }
                                          return null;
                                        },
                                      ),
                                      _buildCard("Status", project['status'],
                                          screenSize,
                                          color: statusColor),
                                      _buildCard(
                                          "Posted on",
                                          formatDate(project['posted_date']),
                                          screenSize),
                                    ],
                                  ),
                                ),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      if (_formKey.currentState!.validate()) {
                                        final jobId = project['job_id'];
                                        // Parse and split skills entered in the input
                                        final newSkills = skillsController.text
                                            .split(',')
                                            .map((e) => e.trim())
                                            .where((e) => e.isNotEmpty)
                                            .toList();

                                        // Combine with the existing skills (if any)
                                        final updatedSkills = newSkills;

                                        channel.sink.add(jsonEncode({
                                          'type': 'edit_job',
                                          'job_id': jobId,
                                          'updates': {
                                            'job_title': titleController.text,
                                            'description': descController.text,
                                            'budget': int.tryParse(
                                                budgetController.text),
                                            'required_skills':
                                                updatedSkills, // Updated list
                                          },
                                        }));

                                        Navigator.of(context).pop();
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  "✅ Job update requested")),
                                        );
                                      }
                                    },
                                    icon: Icon(Icons.save, color: Colors.white),
                                    label: Text("Save",
                                        style: TextStyle(color: Colors.white)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 24, vertical: 12),
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      final ok = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          backgroundColor: Colors.grey.shade900,
                                          title: Text('Confirm Deletion',
                                              style: TextStyle(
                                                  color: Colors.white)),
                                          content: Text(
                                              'Are you sure you want to delete this job?',
                                              style: TextStyle(
                                                  color: Colors.white70)),
                                          actions: [
                                            TextButton(
                                              child: Text('Cancel',
                                                  style: TextStyle(
                                                      color: Colors.white70)),
                                              onPressed: () =>
                                                  Navigator.of(ctx).pop(false),
                                            ),
                                            ElevatedButton(
                                              child: Text(
                                                'Delete',
                                                style: TextStyle(
                                                    color: Colors.white),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red),
                                              onPressed: () =>
                                                  Navigator.of(ctx).pop(true),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (ok == true) {
                                        // send delete message
                                        channel.sink.add(jsonEncode({
                                          'type': 'delete_job',
                                          'job_id': project['job_id'],
                                        }));
                                        Navigator.of(context)
                                            .pop(); // close bottom sheet
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content:
                                                  Text('🗑️ Delete requested')),
                                        );
                                      }
                                      // TODO: Add delete logic
                                    },
                                    icon:
                                        Icon(Icons.delete, color: Colors.white),
                                    label: Text("Delete",
                                        style: TextStyle(color: Colors.white)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 24, vertical: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.all(screenSize.width * 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project['job_title'],
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenSize.width * 0.05,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: screenSize.height * 0.01),
                  Text(
                    project['description'],
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: screenSize.width * 0.04,
                    ),
                  ),
                  SizedBox(height: screenSize.height * 0.015),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Budget: ${project['budget']}",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: screenSize.width * 0.04,
                        ),
                      ),
                      Text(
                        project['status'],
                        style: TextStyle(
                          color: statusColor,
                          fontSize: screenSize.width * 0.04,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenSize.height * 0.01),
                  Text(
                    "Posted on: ${formatDate(project['posted_date'])}",
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: screenSize.width * 0.035,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    // Filter the projects based on the selected status and search query
    _filterProjects();

    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      appBar: AppBar(
        title: const Text("My Jobs", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        actions: [
          Container(
            width: 130,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PostJobScreen()),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text("Post Job"),
            ),
          ),
          const SizedBox(width: 12.5),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(screenSize.width * 0.05),
          child: _isLoading
              ? ListView.builder(
                  itemCount: 5,
                  itemBuilder: (context, index) =>
                      _buildShimmerCard(screenSize),
                )
              : Column(
                  children: [
                    // Filters Row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['All', 'Pending', 'Active', 'Cancelled']
                            .map((status) {
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 5.0),
                            child: ChoiceChip(
                              label: Text(status),
                              selected: selectedStatus == status,
                              onSelected: (selected) {
                                setState(() {
                                  selectedStatus = selected ? status : 'All';
                                  _filterProjects(); // Re-filter when status is changed
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Search Bar
                    TextField(
                      onChanged: (query) {
                        setState(() {
                          searchQuery = query;
                          _filterProjects(); // Re-filter when search query is changed
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search by Job Title',
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (filteredProjects.isEmpty)
                      Center(
                        child: Text(
                          'No jobs available for the selected filter.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenSize.width * 0.04,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    // Job List
                    Expanded(
                      child: CustomScrollView(
                        slivers: [
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => _buildProjectCard(
                                  filteredProjects[index], screenSize),
                              childCount: filteredProjects.length,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
