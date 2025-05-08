import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talentbridge/utils/local_storage_utils.dart';

class PostJobScreen extends StatefulWidget {
  const PostJobScreen({Key? key}) : super(key: key);

  @override
  _PostJobScreenState createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  final PageController _pageController = PageController();
  int _milestoneCount = 0;
  final List<Map<String, dynamic>> _milestones = [];
  bool _isSubmitting = false;
  bool _showSuccessAnimation = false;

  final TextEditingController _jobTitleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _skillsController = TextEditingController();
  String? _jobCategory;
  String? _paymentType;

  final List<String> _jobCategories = [
    'Development',
    'Design',
    'Writing',
    'Marketing',
    'Support'
  ];
  final List<String> _paymentTypes = [
    'Fixed Price',
    'Hourly',
    'Milestone-based'
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_formKey.currentState!.validate()) {
      if (_currentStep < 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        setState(() => _currentStep++);
      }
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);

      SharedPreferences prefs = await getLocalUtilResource();
      final result = await getDataFromLocalStorage(prefs, ["email"]);
      final String? email = result["email"];

      if (email == null || email.isEmpty) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not authenticated')),
        );
        return;
      }

      try {
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: email)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final userDoc = querySnapshot.docs.first;
          final String uid = userDoc.id;

          List<Map<String, dynamic>> milestones = _milestones.map((m) {
            return {
              'title': m['title'].text,
              'start_date': m['startDate']?.toIso8601String(),
              'end_date': m['endDate']?.toIso8601String(),
            };
          }).toList();
          final userData = userDoc.data() as Map<String, dynamic>;
          Map<String, dynamic> jobData = {
            'client_id': uid,
            'job_title': _jobTitleController.text,
            'description': _descriptionController.text,
            'job_category': _jobCategory,
            'budget': double.parse(_budgetController.text),
            'payment_type': _paymentType,
            'required_skills':
                _skillsController.text.split(',').map((s) => s.trim()).toList(),
            'milestones': _paymentType == "Milestone-based" ? milestones : null,
            'posted_date': DateTime.now().toIso8601String(),
            'status': 'pending',
            'state': userData["state"],
            'district': userData["district"],
            'client_name': userData["name"]
          };

          final response = await http.post(
            Uri.parse('https://websocket-app-api.onrender.com/api/jobs'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(jobData),
          );

          if (response.statusCode == 201) {
            setState(() {
              _showSuccessAnimation = true;
              _isSubmitting = false;
            });

            await Future.delayed(const Duration(seconds: 2));
            if (mounted) Navigator.pop(context);
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed: ${response.body}')),
              );
            }
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSubmitting = false);
        }
      }
    }
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(2, (index) {
        return Container(
          width: 40,
          height: 40,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: _currentStep >= index
                ? Colors.lightBlueAccent
                : Colors.grey.shade800,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: _currentStep > index
                ? const Icon(Icons.check, color: Colors.black, size: 20)
                : Text(
                    '${index + 1}',
                    style: TextStyle(
                        color: _currentStep == index
                            ? Colors.white
                            : Colors.grey.shade400,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
          ),
        );
      }),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    int? maxLines,
    String? prefixText,
    Widget? prefixIcon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines ?? 1,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          prefixText: prefixText,
          prefixIcon: prefixIcon,
          prefixStyle: TextStyle(color: Colors.grey.shade400),
          labelStyle: TextStyle(color: Colors.grey.shade400),
          filled: true,
          fillColor: Colors.grey.shade800,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey.shade700),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide:
                const BorderSide(color: Colors.lightBlueAccent, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        ),
        validator: (value) => value!.isEmpty ? 'Required field' : null,
      ),
    );
  }

  Widget _buildStepOne() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildInputField(
            controller: _jobTitleController,
            label: 'Job Title',
            prefixIcon: const Icon(Icons.work_outline, color: Colors.grey),
          ),
          _buildInputField(
            controller: _descriptionController,
            label: 'Description',
            maxLines: 5,
            prefixIcon: const Icon(Icons.description, color: Colors.grey),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.shade700),
            ),
            child: DropdownButtonFormField<String>(
              value: _jobCategory,
              dropdownColor: Colors.grey.shade900,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                border: InputBorder.none,
                labelText: 'Job Category',
                labelStyle: TextStyle(color: Colors.white),
                prefixIcon: Icon(Icons.category, color: Colors.grey),
              ),
              items: _jobCategories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) => setState(() => _jobCategory = value),
              validator: (value) => value == null ? 'Required' : null,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(
      BuildContext context, bool isStart, int index) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _milestones[index]['startDate'] = picked;
        } else {
          _milestones[index]['endDate'] = picked;
        }
      });
    }
  }

  Widget _buildStepTwo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildInputField(
            controller: _budgetController,
            label: 'Budget',
            keyboardType: TextInputType.number,
            prefixText: '₹ ',
            prefixIcon: const Icon(Icons.money, color: Colors.grey),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.shade700),
            ),
            child: DropdownButtonFormField<String>(
              value: _paymentType,
              dropdownColor: Colors.grey.shade900,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                border: InputBorder.none,
                labelText: 'Payment Type',
                labelStyle: TextStyle(color: Colors.white),
                prefixIcon: Icon(Icons.payment, color: Colors.grey),
              ),
              items: _paymentTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) => setState(() => _paymentType = value),
              validator: (value) => value == null ? 'Required' : null,
            ),
          ),
          _buildInputField(
            controller: _skillsController,
            label: 'Required Skills (comma separated)',
            prefixIcon: const Icon(Icons.code, color: Colors.grey),
          ),
          if (_paymentType == "Milestone-based") ...[
            TextFormField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Milestone Count',
                prefixIcon: const Icon(Icons.flag_outlined, color: Colors.grey),
                labelStyle: TextStyle(color: Colors.grey.shade400),
                filled: true,
                fillColor: Colors.grey.shade800,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.grey.shade700),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide:
                      const BorderSide(color: Colors.lightBlueAccent, width: 2),
                ),
              ),
              onChanged: (value) {
                final count = int.tryParse(value!) ?? 0;
                if (count > _milestones.length) {
                  setState(() {
                    for (int i = _milestones.length; i < count; i++) {
                      _milestones.add({
                        'title': TextEditingController(),
                        'startDate': null,
                        'endDate': null
                      });
                    }
                  });
                } else if (count < _milestones.length) {
                  setState(() {
                    _milestones.removeRange(count, _milestones.length);
                  });
                }
              },
              validator: (value) => value!.isEmpty ? 'Required field' : null,
            ),
            ..._milestones.asMap().entries.map((entry) {
              final index = entry.key;
              final milestone = entry.value;
              return Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Milestone ${index + 1}',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    TextFormField(
                      controller: milestone['title'],
                      decoration: InputDecoration(
                        labelText: 'Title',
                        filled: true,
                        fillColor: Colors.grey.shade800,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: Colors.grey.shade700),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(context, true, index),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Start Date',
                                labelStyle:
                                    const TextStyle(color: Colors.white),
                                filled: true,
                                fillColor: Colors.grey.shade800,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade700),
                                ),
                              ),
                              child: Text(
                                milestone['startDate'] == null
                                    ? 'Select Date'
                                    : DateFormat('dd/MM/yyyy')
                                        .format(milestone['startDate']),
                                style: TextStyle(
                                  color: milestone['startDate'] == null
                                      ? Colors.grey.shade400
                                      : Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(context, false, index),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'End Date',
                                labelStyle:
                                    const TextStyle(color: Colors.white),
                                filled: true,
                                fillColor: Colors.grey.shade800,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade700),
                                ),
                              ),
                              child: Text(
                                milestone['endDate'] == null
                                    ? 'Select Date'
                                    : DateFormat('dd/MM/yyyy')
                                        .format(milestone['endDate']),
                                style: TextStyle(
                                  color: milestone['endDate'] == null
                                      ? Colors.grey.shade400
                                      : Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            })
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return _isSubmitting || _showSuccessAnimation
        ? Container(
            color: _showSuccessAnimation
                ? Colors.black // Solid dark for animation + text
                : Colors.black.withOpacity(0.5), // Transparent for loading
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_showSuccessAnimation) ...[
                    Lottie.asset(
                      'assets/animations_assets/post_success.json',
                      width: MediaQuery.of(context).size.width * 0.8,
                      fit: BoxFit.contain,
                      repeat: false,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Job Posted Successfully",
                      style: TextStyle(color: Colors.white, fontSize: 22),
                    ),
                  ],
                  if (_isSubmitting)
                    const CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.lightBlueAccent),
                    ),
                ],
              ),
            ),
          )
        : const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      body: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              title: const Text('Post a Job',
                  style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.transparent,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: _isSubmitting ? null : () => Navigator.pop(context),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(80),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    _buildStepIndicator(),
                    const SizedBox(height: 15),
                    LinearProgressIndicator(
                      value: (_currentStep + 1) / 2,
                      backgroundColor: Colors.grey.shade800,
                      color: Colors.lightBlueAccent,
                      minHeight: 4,
                    ),
                  ],
                ),
              ),
            ),
            body: Form(
              key: _formKey,
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStepOne(),
                  _buildStepTwo(),
                ],
              ),
            ),
            bottomNavigationBar: Container(
              padding: const EdgeInsets.all(20),
              color: Colors.grey.shade900,
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmitting ? null : _prevStep,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          side: BorderSide(color: Colors.grey.shade700),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Back',
                          style: TextStyle(
                              color: Colors.grey.shade400, fontSize: 16),
                        ),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting
                          ? null
                          : _currentStep == 1
                              ? _submitForm
                              : _nextStep,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _currentStep == 1 ? 'Submit Job' : 'Next',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildLoadingOverlay(),
        ],
      ),
    );
  }
}
