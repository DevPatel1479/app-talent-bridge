import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:shimmer/shimmer.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import '../model/job_post.dart';

class JobCard extends StatefulWidget {
  const JobCard({super.key});

  @override
  _JobCardState createState() => _JobCardState();
}

class _JobCardState extends State<JobCard> {
  late WebSocketChannel _channel;
  final List<JobPost> _jobPosts = [];
  bool _isLoading = true;
  String? _error;
  bool _isExpanded = false;
  final Map<String, Map<String, dynamic>> _clientProfiles = {};
  bool _hasInternet = true;

  @override
  void initState() {
    super.initState();
    print('Initializing JobCard');
    _checkInternetConnection().then((_) {
      print('Internet check completed, hasInternet: $_hasInternet');
      if (_hasInternet) {
        _connectToWebSocket();
      } else {
        setState(() {
          _error = 'No internet connection. Please connect to the internet.';
          _isLoading = false;
        });
      }
    }).catchError((e) {
      print('Error in initState: $e');
      setState(() {
        _error = 'Error initializing: $e';
        _isLoading = false;
      });
    });
  }

  Future<void> _checkInternetConnection() async {
    try {
      var connectivityResult = await Connectivity().checkConnectivity();
      setState(() {
        _hasInternet = connectivityResult != ConnectivityResult.none;
        print('Internet connection status: $_hasInternet');
      });
    } catch (e) {
      print('Error checking internet: $e');
      setState(() {
        _hasInternet = false;
      });
    }
  }

  Future<void> _fetchClientProfile(String clientId) async {
    if (_clientProfiles.containsKey(clientId)) return;

    try {
      String id = "sqHapZFQJob3wcYJDCrtDkJIgxH2";
      final response = await http.get(
        Uri.parse(
            'https://websocket-app-api.onrender.com/api/client/profile/$id'),
      );
      print(
          'Fetched client profile for $clientId, status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _clientProfiles[clientId] = data['data'];
          });
        }
      }
    } catch (e) {
      print('Error fetching client profile: $e');
    }
  }

  void _connectToWebSocket() {
    if (!_hasInternet) {
      setState(() {
        _error = 'No internet connection. Please connect to the internet.';
        _isLoading = false;
      });
      return;
    }

    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('wss://websocket-app-api.onrender.com/jobs'),
      );

      _channel.stream.listen(
        (message) {
          try {
            print("📥 Raw message: $message");
            print("🧠 Message type: ${message.runtimeType}");

            Map<String, dynamic> data;

            // Decode the message
            if (message is String) {
              data = json.decode(message) as Map<String, dynamic>;
            } else {
              throw Exception(
                  "Unsupported message type: ${message.runtimeType}");
            }

            print("📦 Decoded WebSocket data: $data");

            // Check the message type
            if (data['type'] == 'added' || data['type'] == 'initial') {
              final jobData = data['data'];

              // Check if jobData is a Map
              if (jobData is Map<String, dynamic>) {
                final newJobPost = JobPost.fromJson(jobData);

                setState(() {
                  _jobPosts.add(newJobPost); // Enable this when needed
                  _isLoading = false;
                });
              } else if (jobData is String) {
                // Try parsing it again if it's a stringified JSON
                final parsedJobData =
                    json.decode(jobData) as Map<String, dynamic>;
                final newJobPost = JobPost.fromJson(parsedJobData);

                setState(() {
                  _jobPosts.add(newJobPost); // Enable this when needed
                  _isLoading = false;
                });
              } else {
                throw Exception(
                    'Job data is not in expected format. Got: ${jobData.runtimeType}');
              }
            }
          } catch (e, st) {
            print("🔥 Error processing WebSocket message: $e\n$st");
            setState(() {
              _error = 'Error processing WebSocket message: $e';
              _isLoading = false;
            });
          }
        },
        onError: (error) {
          setState(() {
            _error = 'Failed to connect to job feed: $error';
            _isLoading = false;
          });
        },
        onDone: () {
          if (_channel.closeCode != status.normalClosure) {
            setState(() {
              _error = 'WebSocket connection closed unexpectedly';
              _isLoading = false;
            });
          }
        },
      );
    } catch (e) {
      setState(() {
        _error = 'Connection error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _channel.sink.close(status.normalClosure);
    super.dispose();
  }

  void _showClientProfile(BuildContext context, String clientId) {
    final profile = _clientProfiles[clientId];
    if (profile == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (_, controller) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Client Profile',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  controller: controller,
                  children: [
                    Center(
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage:
                            NetworkImage(profile['profileImagePath'] ?? ''),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        profile['name'],
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildProfileDetail(Icons.email, 'Email', profile['email']),
                    _buildProfileDetail(Icons.location_city, 'Company',
                        profile['company'] ?? 'Not provided'),
                    _buildProfileDetail(Icons.location_on, 'Location',
                        '${profile['district']}, ${profile['state']}, ${profile['country']}'),
                    const SizedBox(height: 16),
                    if (profile['userRole'] != null)
                      Chip(
                        label: Text(profile['userRole']),
                        backgroundColor:
                            Theme.of(context).primaryColor.withOpacity(0.1),
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

  Widget _buildProfileDetail(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerCard() {
    final bool isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    Color baseColor = isDarkTheme ? Colors.grey[700]! : Colors.grey[300]!;
    Color highlightColor = isDarkTheme ? Colors.grey[500]! : Colors.grey[100]!;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 24,
                color: Colors.white,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 120,
                    height: 16,
                    color: Colors.white,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 180,
                    height: 16,
                    color: Colors.white,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 100,
                    height: 16,
                    color: Colors.white,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 80,
                    height: 14,
                    color: Colors.white,
                  ),
                  Container(
                    width: 140,
                    height: 14,
                    color: Colors.white,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJobCard(JobPost jobPost) {
    final clientProfile = _clientProfiles[jobPost.clientId];
    final clientName = clientProfile?['name'] ?? 'Loading...';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                jobPost.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _showClientProfile(context, jobPost.clientId),
                child: Row(
                  children: [
                    const Icon(Icons.person, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      clientName,
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16),
                  const SizedBox(width: 4),
                  Text('${jobPost.city}, ${jobPost.state}'),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Text('₹', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 4),
                  Text('${jobPost.salary}'),
                ],
              ),
              if (_isExpanded) ...[
                const SizedBox(height: 12),
                Text(
                  'Description',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(jobPost.description),
                const SizedBox(height: 12),
                Text(
                  'Required Skills',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  children: jobPost.requiredSkills
                      .map((skill) => Chip(label: Text(skill)))
                      .toList(),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Implement apply logic
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Apply For Job'),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    jobPost.jobType,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    'Posted: ${DateFormat('MMM d, yyyy').format(jobPost.datePosted)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  child: Text(
                    _isExpanded ? 'Read Less' : 'Read More',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print(
        'Building widget - isLoading: $_isLoading, hasInternet: $_hasInternet, error: $_error, jobPosts: ${_jobPosts.length}');

    if (!_hasInternet) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No internet connection',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text('Please connect to the internet and try again'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _checkInternetConnection();
                if (_hasInternet) {
                  _connectToWebSocket();
                }
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _connectToWebSocket,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      print('Showing shimmer effect');
      return ListView.builder(
        itemCount: 3,
        itemBuilder: (context, index) => _buildShimmerCard(),
      );
    }

    if (_jobPosts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No jobs available',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _jobPosts.length,
      itemBuilder: (context, index) => _buildJobCard(_jobPosts[index]),
    );
  }
}
