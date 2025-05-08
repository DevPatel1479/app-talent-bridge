import 'dart:convert';

import 'package:keyboard_dismisser/keyboard_dismisser.dart';
import 'package:flutter/widgets.dart';

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:talentbridge/api_services/api_service.dart';
import 'package:talentbridge/model/StateDistrictDataModel.dart';
import 'package:talentbridge/model/UserInfoModel.dart';
import 'package:talentbridge/screens/otp_verification_screen.dart';
import 'package:talentbridge/utils/hash_utils.dart';
import 'additional_info_screen.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'package:country_list_pick/country_list_pick.dart';

class SignupScreen extends StatefulWidget {
  final VoidCallback onToggleAuth;
  final String userRole;
  const SignupScreen(
      {super.key, required this.onToggleAuth, required this.userRole});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with WidgetsBindingObserver {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Controllers for the input fields.
  final TextEditingController nameController = TextEditingController();
  final TextEditingController companyController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  // Note: We're not using phoneController here because IntlPhoneField gives us a complete number.
  // final TextEditingController addressController = TextEditingController();
// Variables for country dropdown.

  String _selectedCountry = "India";
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  String? errorMessage;

  // For loading animation.
  bool _isLoading = false;
  // To store the complete phone number from IntlPhoneField.
  String _completePhoneNumber = "";
  File? _profileImage;
  String? _profilePhotoUrl;
  bool _isProcessingImage = false;
  bool _pickerActive = false; // Add this flag

  List<StateData> states = [];
  String? selectedState;
  List<String> districts = [];
  String? selectedDistrict;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    loadStates();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _recoverFromAppPause();
    }
  }

  Future<void> loadStates() async {
    // Load the JSON file from assets
    final String jsonString =
        await rootBundle.loadString('assets/state_data.json');
    final Map<String, dynamic> data = json.decode(jsonString);
    final List<dynamic> statesJson = data['states'];

    List<StateData> loadedStates =
        statesJson.map((e) => StateData.fromJson(e)).toList();
    // print(loadedStates);
    setState(() {
      states = loadedStates;
      if (states.isNotEmpty) {
        selectedState = states.first.state;
        districts = states.first.districts;
        selectedDistrict = districts.isNotEmpty ? districts.first : null;
      }
    });
  }

  Future<void> _recoverFromAppPause() async {
    if (_isProcessingImage && !_pickerActive) {
      await Future.delayed(const Duration(milliseconds: 500)); // Add delay

      setState(() => _pickerActive = true);
      try {
        final image = await ImagePicker().pickImage(
          source: ImageSource.camera,
          requestFullMetadata: false, // Add for performance
        );

        if (image != null && mounted) {
          setState(() {
            _profileImage = File(image.path);
            _isProcessingImage = false;
          });
        }
      } catch (e) {
        debugPrint('Image recovery error: $e');
      } finally {
        if (mounted) {
          setState(() => _pickerActive = false);
        }
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      errorMessage = null;
    });
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      final GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication;
      if (googleAuth == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      await _auth.signInWithCredential(credential);
      final String userR = widget.userRole;
      // After Google sign-in, navigate to the additional info screen.
      if (googleUser != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdditionalInfoScreen(
              authType: "google",
              userRole: userR,
              email: googleUser.email,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        errorMessage = "Google Sign-In Failed: ${e.toString()}";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signInWithFacebook() async {
    setState(() {
      _isLoading = true;
      errorMessage = null;
    });
    try {
      final LoginResult result = await FacebookAuth.instance.login();
      if (result.status == LoginStatus.success) {
        final AccessToken accessToken = result.accessToken!;
        final OAuthCredential credential =
            FacebookAuthProvider.credential(accessToken.tokenString);
        await _auth.signInWithCredential(credential);

        final userData = await FacebookAuth.instance.getUserData();
        // After Facebook sign-in, navigate to the additional info screen.

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdditionalInfoScreen(
                authType: "facebook",
                userRole: widget.userRole,
                email: userData['email']),
          ),
        );
      } else {
        setState(() {
          errorMessage = "Facebook Sign-In Failed";
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Facebook Sign-In Error: ${e.toString()}";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _validateAndSubmit() async {
    print(_profileImage);
    if (_profileImage == null) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Please upload the Profile Photo"),
        duration: Duration(seconds: 1),
      ));

      setState(() {
        errorMessage = "Profile photo is required";
      });
      return;
    }
    if (!_formKey.currentState!.validate()) {
      setState(() {
        errorMessage = "Please fix the errors in red";
      });
      return;
    }

    if (passwordController.text.trim() !=
        confirmPasswordController.text.trim()) {
      setState(() {
        errorMessage = "Passwords do not match";
      });
      return;
    }

    // if (_selectedCountry == null || _selectedCountry!.isEmpty) {
    //   setState(() {
    //     errorMessage = "Country selection is required";
    //   });
    //   return;
    // }

    setState(() {
      _isLoading = true;
      errorMessage = null;
    });
    try {
      // Check if a user with the same phone number already exists.
      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .where("email", isEqualTo: emailController.text.trim())
          .get();

      if (userDoc.docs.isNotEmpty) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Please Login, account already exists"),
            backgroundColor: Colors.grey[800],
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // Create the user using email & password.
      // final userCredential = await _auth.createUserWithEmailAndPassword(
      //   email: emailController.text.trim(),
      //   password: passwordController.text.trim(),
      // );
      // final user = userCredential.user;
      // if (user != null) {
      //   await user.updateDisplayName(nameController.text.trim());
      // Store the additional data in Firestore with the phone number as the document ID.
      // await FirebaseFirestore.instance
      //     .collection("users")
      //     .doc(_completePhoneNumber)
      //     .set({
      //   "uid": user.uid,
      //   "name": nameController.text.trim(),
      //   "company": companyController.text.trim(),
      //   "email": emailController.text.trim(),
      //   "phone": _completePhoneNumber,
      //   "country": _selectedCountry,
      //   // "address": addressController.text.trim(),
      //   "createdAt": FieldValue.serverTimestamp(),
      //   // "authType": "email",
      //   "userRole": widget.userRole
      // });

// Save the profile image locally and retrieve its file path.
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String fileExtension = p.extension(_profileImage!.path);
      final String fileName =
          'profile_${nameController.text.trim()}$fileExtension';
      final String localImagePath = p.join(appDocDir.path, fileName);
      // Copy the file to local storage.
      await _profileImage!.copy(localImagePath);

      String hashPassword =
          hashSensitiveInformation(passwordController.text.trim());

      final data = UserInfoData(
          uid: "tmp",
          name: nameController.text.trim(),
          company: companyController.text.trim(),
          // phone: _completePhoneNumber,
          country: _selectedCountry,
          password: hashPassword,
          userRole: widget.userRole,
          email: emailController.text.trim(),
          createdAt: FieldValue.serverTimestamp(),
          profileImagePath: localImagePath,
          state: selectedState!,
          district: selectedDistrict!);

      http.Response response = await API(service_type: {
        "service_type": "email",
        "data": emailController.text.trim()
      }).sendOTP();
      if (response.statusCode == 200) {
        setState(() {
          _isLoading = false;
        });
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
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to send OTP. Please try again.")));
      }
    } catch (e) {
      setState(() {
        errorMessage = "Registration Failed: ${e.toString()}";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String? _validateInput(String label, String? value) {
    if (value == null || value.isEmpty) return "$label is required";

    if (label == 'Email') {
      if (!RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")
          .hasMatch(value)) {
        return 'Enter a valid email address';
      }
    } else if (label == 'Password') {
      if (!RegExp(r".{6,}").hasMatch(value)) {
        return 'Minimum 6 characters required';
      }
    } else if (label == 'Confirm Password') {
      if (value != passwordController.text) {
        return "Passwords do not match";
      }
    }

    // Other fields (Full Name, Company Name, Address) require only non-empty validation.
    return null;
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_pickerActive) return; // Prevent multiple activations

    try {
      setState(() {
        _isProcessingImage = true;
        _pickerActive = true;
      });

      final pickedFile = await ImagePicker().pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1080,
        maxHeight: 1080,
        requestFullMetadata: false,
      );

      if (pickedFile != null && mounted) {
        setState(() => _profileImage = File(pickedFile.path));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingImage = false;
          _pickerActive = false;
        });
      }
    }
  }

  void _handleImagePickerError(dynamic error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Image picker error: ${error.toString()}'),
        duration: const Duration(seconds: 2),
      ),
    );
    if (_isProcessingImage) {
      setState(() => _isProcessingImage = false);
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

  @override
  Widget build(BuildContext context) {
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: const Color(0xFF1A1A1A),
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: const Color(0xFF1A1A1A),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            Positioned.fill(
              child: Container(
                width: double.infinity,
                height: double.infinity,
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
                child: isPortrait
                    ? _buildPortraitLayout(isSmallScreen)
                    : _buildLandscapeWarning(),
              ),
            ),
            if (_isLoading)
              AnimatedOpacity(
                opacity: _isLoading ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  color: Colors.black45,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortraitLayout(bool isSmallScreen) {
    return Column(
      children: [
        // Header Section
        Padding(
          padding: EdgeInsets.only(
            left: isSmallScreen ? 15 : 25,
            top: MediaQuery.of(context).padding.top + 20,
          ),
          child: Align(
            alignment: Alignment.topLeft,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 10),
                const Text(
                  "Sign Up",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Scrollable Form Fields
        Expanded(
          child: KeyboardDismisser(
            gestures: const [
              GestureType.onTap,
              GestureType.onPanUpdateDownDirection, // Corrected gesture name
              GestureType.onVerticalDragDown,
            ],
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 20 : 30,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 30),
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
                                      ? NetworkImage(_profilePhotoUrl!)
                                      : null),
                              child: _profileImage == null &&
                                      _profilePhotoUrl == null
                                  ? const Icon(Icons.person,
                                      size: 50, color: Colors.white70)
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
                    const SizedBox(height: 15),
                    _buildTextField("Full Name", nameController, false),
                    const SizedBox(height: 15),
                    _buildTextField(
                        "Company Name (Optional)", companyController, false),
                    const SizedBox(height: 15),
                    _buildTextField("Email", emailController, false,
                        keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 15),
                    _buildTextField("Password", passwordController, true),
                    const SizedBox(height: 15),
                    _buildTextField(
                        "Confirm Password", confirmPasswordController, true),
                    // const SizedBox(height: 15),
                    // IntlPhoneField(
                    //   decoration: InputDecoration(
                    //     labelText: 'Phone Number',
                    //     labelStyle: const TextStyle(color: Colors.white70),
                    //     filled: true,
                    //     fillColor: Colors.white.withOpacity(0.1),
                    //     border: OutlineInputBorder(
                    //       borderRadius: BorderRadius.circular(12),
                    //       borderSide: BorderSide.none,
                    //     ),
                    //     contentPadding: const EdgeInsets.symmetric(
                    //       horizontal: 20,
                    //       vertical: 16,
                    //     ),
                    //   ),
                    //   initialCountryCode: 'US',
                    //   style: const TextStyle(color: Colors.white),
                    //   onChanged: (phone) {
                    //     // Update the complete phone number.
                    //     _completePhoneNumber = phone.completeNumber;
                    //     print(phone.completeNumber);
                    //   },
                    //   validator: (phone) {
                    //     if (phone == null || phone.number.isEmpty) {
                    //       return "Phone number is required";
                    //     }
                    //     return null;
                    //   },
                    // ),
                    const SizedBox(height: 15),
                    InputDecorator(
                      decoration: InputDecoration(
                        labelText: "Country",
                        labelStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 15),
                      ),
                      child: Row(
                        children: const [
                          Text(
                            '🇮🇳',
                            style: TextStyle(fontSize: 24),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'India',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    // Dropdown for State selection with attractive border styling
                    states.isEmpty
                        ? const CircularProgressIndicator()
                        : InputDecorator(
                            decoration: InputDecoration(
                              labelText: "Select State",
                              labelStyle: const TextStyle(
                                  color: Colors.white70, fontSize: 18),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.1),
                              // Here we style the border to be visible
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Colors.white70, width: 1.0),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 15, vertical: 15),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: selectedState,
                                dropdownColor: Colors.black,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 16),
                                items: states.map((stateData) {
                                  return DropdownMenuItem<String>(
                                    value: stateData.state,
                                    child: Text(stateData.state),
                                  );
                                }).toList(),
                                onChanged: (String? newState) {
                                  setState(() {
                                    selectedState = newState;
                                    final stateData = states.firstWhere(
                                      (element) => element.state == newState,
                                      orElse: () => states.first,
                                    );
                                    districts = stateData.districts;
                                    selectedDistrict = districts.isNotEmpty
                                        ? districts.first
                                        : null;
                                  });
                                },
                              ),
                            ),
                          ),
                    const SizedBox(height: 15),
// Dropdown for District selection with attractive border styling
                    states.isEmpty
                        ? const SizedBox()
                        : InputDecorator(
                            decoration: InputDecoration(
                              labelText: "Select District",
                              labelStyle: const TextStyle(
                                  color: Colors.white70, fontSize: 18),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.1),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Colors.white70, width: 1.0),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 15, vertical: 15),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: selectedDistrict,
                                dropdownColor: Colors.black,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 16),
                                items: districts.map((district) {
                                  return DropdownMenuItem<String>(
                                    value: district,
                                    child: Text(district),
                                  );
                                }).toList(),
                                onChanged: (String? newDistrict) {
                                  setState(() {
                                    selectedDistrict = newDistrict;
                                  });
                                },
                              ),
                            ),
                          ),

                    const SizedBox(height: 30),
                    if (errorMessage != null) _buildErrorMessage(),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Fixed Footer Buttons
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 20 : 30,
            vertical: 15,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              _buildActionButton(),
              const SizedBox(height: 15),
              const Text(
                "OR",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 15),
              _buildSocialButtons(isSmallScreen),
              const SizedBox(height: 15),
              _buildSwitchAuthMode(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLandscapeWarning() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.screen_rotation_alt,
              size: 60,
              color: Colors.white54,
            ),
            const SizedBox(height: 20),
            const Text(
              "Portrait Mode Required",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            const Text(
              "Please rotate your device to portrait mode to use the signup screen.",
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: const Icon(Icons.phone_android, color: Colors.white),
              label: const Text("Understand",
                  style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.1),
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    bool isPassword, {
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
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
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white70,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              )
            : null,
      ),
      validator: (value) => label == "Company Name (Optional)"
          ? null
          : _validateInput(label, value),
    );
  }

  Widget _buildErrorMessage() {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 500),
      opacity: errorMessage != null ? 1.0 : 0.0,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                errorMessage!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButtons(bool isSmallScreen) {
    return Column(
      children: [
        _buildSocialButton(
          "Continue with Google",
          const LinearGradient(
            colors: [Color(0xFF4285F4), Color(0xFF356ABC)],
          ),
          Icons.g_mobiledata,
          _signInWithGoogle,
          isSmallScreen,
        ),
        const SizedBox(height: 10),
        _buildSocialButton(
          "Continue with Facebook",
          const LinearGradient(
            colors: [Color(0xFF4267B2), Color(0xFF2F477A)],
          ),
          Icons.facebook,
          _signInWithFacebook,
          isSmallScreen,
        ),
      ],
    );
  }

  Widget _buildSocialButton(
    String label,
    Gradient gradient,
    IconData icon,
    VoidCallback onTap,
    bool isSmallScreen,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 14 : 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: isSmallScreen ? 22 : 24, color: Colors.white),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    return Container(
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
          onPressed: _validateAndSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            "Create Account",
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

  Widget _buildSwitchAuthMode() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Already have an account?",
            style: TextStyle(color: Colors.white70)),
        TextButton(
          onPressed: widget.onToggleAuth,
          child: const Text(
            "Login",
            style: TextStyle(
              color: Color(0xFF00C9A7),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
