import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:image_picker/image_picker.dart';
import 'package:talentbridge/api_services/api_service.dart';
import 'package:talentbridge/model/UserInfoModel.dart';
import 'package:talentbridge/screens/otp_verification_screen.dart';

class AdditionalInfoScreen extends StatefulWidget {
  final String authType; // e.g., "google" or "facebook"
  final String userRole;
  const AdditionalInfoScreen(
      {Key? key, required this.authType, required this.userRole})
      : super(key: key);

  @override
  _AdditionalInfoScreenState createState() => _AdditionalInfoScreenState();
}

class _AdditionalInfoScreenState extends State<AdditionalInfoScreen> {
  // Controllers for form fields.
  final TextEditingController nameController = TextEditingController();
  final TextEditingController companyController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  File? _profileImage;
  String? _profilePhotoUrl;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? errorMessage;
  String _completePhoneNumber = "";

  @override
  void initState() {
    super.initState();
    // Optionally prefill with current Firebase user details.
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      nameController.text = user.displayName ?? "";
      _profilePhotoUrl = user.photoURL;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: ${e.toString()}')),
      );
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.white),
              title: const Text('Take Photo',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.white),
              title: const Text('Choose from Gallery',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
      backgroundColor: Colors.grey[850],
    );
  }

  Widget _buildTextField(
      String label, TextEditingController controller, bool isPassword,
      {TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return "$label is required";
        return null;
      },
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller,
      ValueNotifier<bool> obscureNotifier) {
    return ValueListenableBuilder<bool>(
      valueListenable: obscureNotifier,
      builder: (context, obscure, child) {
        return TextFormField(
          controller: controller,
          obscureText: obscure,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: Colors.white70),
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            suffixIcon: IconButton(
              icon: Icon(
                obscure ? Icons.visibility_off : Icons.visibility,
                color: Colors.white70,
              ),
              onPressed: () {
                obscureNotifier.value = !obscureNotifier.value;
              },
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return "$label is required";
            if (value.length < 6)
              return "Password must be at least 6 characters";
            return null;
          },
        );
      },
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: confirmPasswordController,
      obscureText: _obscureConfirmPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Confirm Password',
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
            color: Colors.white70,
          ),
          onPressed: () {
            setState(() {
              _obscureConfirmPassword = !_obscureConfirmPassword;
            });
          },
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty)
          return "Please confirm your password";
        if (value != passwordController.text) return "Passwords do not match";
        return null;
      },
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              errorMessage ?? "",
              style: const TextStyle(color: Colors.redAccent, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _submitAdditionalInfo() async {
    if (!_formKey.currentState!.validate()) {
      setState(() {
        errorMessage = "Please fix the errors in red";
      });
      return;
    }
    if (phoneController.text.trim().isEmpty) {
      setState(() {
        errorMessage = "Phone number is required";
      });
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A1A1A), Color(0xFF121212)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.secondary,
                      ),
                      strokeWidth: 3,
                    ),
                    Icon(
                      Icons.verified_outlined,
                      color: theme.colorScheme.secondary,
                      size: 28,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: "SENDING ",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white.withOpacity(0.9),
                          letterSpacing: 1.2,
                        ),
                      ),
                      TextSpan(
                        text: "OTP",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.secondary,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Please wait while we prepare your verification",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
    setState(() {
      _isLoading = true;
      errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        http.Response response = await API(
                service_type: {"service_type": "email", "data": user.email!})
            .sendOTP();
        if (response.statusCode == 200) {
          Navigator.pop(context);
          final data = UserInfoData(
              uid: user.uid,
              name: nameController.text.trim(),
              company: companyController.text.trim(),
              phone: _completePhoneNumber,
              address: addressController.text.trim(),
              password: passwordController.text.trim(),
              authType: "email",
              userRole: widget.userRole,
              email: user.email!,
              createdAt: FieldValue.serverTimestamp());

          Navigator.push(
            context,
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 500),
              pageBuilder: (context, animation, secondaryAnimation) =>
                  FadeTransition(
                opacity: animation,
                child: OtpVerificationScreen(data: data),
              ),
            ),
          );
        } else {
          // Dismiss popup and show error if API did not return 200.
          Navigator.pop(context);
          setState(() {
            errorMessage = "Failed to send OTP. Please try again.";
          });
        }
        // await FirebaseFirestore.instance
        //     .collection("users")
        //     .doc(_completePhoneNumber)
        //     .set({
        //   "uid": user.uid,
        //   "name": nameController.text.trim(),
        //   "company": companyController.text.trim(),
        //   "email": user.email,
        //   "phone": _completePhoneNumber,
        //   "address": addressController.text.trim(),
        //   "createdAt": FieldValue.serverTimestamp(),
        //   "authType": "email",
        //   "userRole": widget.userRole,
        // });
      }
      // Navigator.pop(context);
    } catch (e) {
      print(e);
      setState(() {
        errorMessage = "Submission failed: ${e.toString()}";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildActionButton() {
    return Container(
      // The submit button container remains outside the scrollable area.
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00C9A7), Color(0xFF009D87)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.tealAccent.shade400.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _submitAdditionalInfo,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            "Submit",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 10),
          const Text(
            "Complete Your Profile",
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 400;

    return Scaffold(
      body: !isPortrait
          ? Container(
              color: Colors.black,
              child: Center(
                child: Text(
                  "Portrait Mode Required",
                  style: TextStyle(fontSize: 24, color: Colors.white),
                ),
              ),
            )
          : Stack(
              children: [
                // Retain the original background.
                Positioned.fill(
                  child: Container(
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
                  ),
                ),
                // Main content: header, scrollable form, and fixed submit button.
                SafeArea(
                  child: Column(
                    children: [
                      // Fixed header.
                      _buildHeader(),
                      // Scrollable container for input fields and error messages.
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 20),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                GestureDetector(
                                  onTap: _showImagePickerOptions,
                                  child: Center(
                                    child: Stack(
                                      children: [
                                        CircleAvatar(
                                          radius: 50,
                                          backgroundImage: _profileImage != null
                                              ? FileImage(_profileImage!)
                                              : (_profilePhotoUrl != null
                                                  ? NetworkImage(
                                                      _profilePhotoUrl!)
                                                  : null),
                                          child: _profileImage == null &&
                                                  _profilePhotoUrl == null
                                              ? const Icon(Icons.person,
                                                  size: 50,
                                                  color: Colors.white70)
                                              : null,
                                        ),
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF00C9A7),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.camera_alt,
                                                size: 20, color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 30),
                                _buildTextField(
                                    "Full Name", nameController, false),
                                const SizedBox(height: 15),
                                _buildTextField(
                                    "Company Name", companyController, false),
                                const SizedBox(height: 15),
                                IntlPhoneField(
                                  controller: phoneController,
                                  decoration: InputDecoration(
                                    labelText: 'Phone Number',
                                    labelStyle:
                                        const TextStyle(color: Colors.white70),
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.1),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 16),
                                  ),
                                  initialCountryCode: 'US',
                                  style: const TextStyle(color: Colors.white),
                                  onChanged: (phone) {
                                    _completePhoneNumber = phone.completeNumber;
                                  },
                                  validator: (phone) {
                                    if (phone == null || phone.number.isEmpty) {
                                      return "Phone number is required";
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 15),
                                _buildTextField(
                                    "Address", addressController, false),
                                const SizedBox(height: 15),
                                _buildPasswordField(
                                  'Password',
                                  passwordController,
                                  ValueNotifier(_obscurePassword),
                                ),
                                const SizedBox(height: 15),
                                _buildConfirmPasswordField(),
                                const SizedBox(height: 30),
                                if (errorMessage != null) _buildErrorMessage(),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Fixed submit button outside the scrollable container.
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 20),
                        child: _buildActionButton(),
                      ),
                    ],
                  ),
                ),
                // Optional loading overlay.
                if (_isLoading)
                  Container(
                    color: Colors.black45,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
    );
  }
}
