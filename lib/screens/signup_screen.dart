import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'additional_info_screen.dart';

class SignupScreen extends StatefulWidget {
  final VoidCallback onToggleAuth;

  const SignupScreen({super.key, required this.onToggleAuth});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Controllers for the input fields.
  final TextEditingController nameController = TextEditingController();
  final TextEditingController companyController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  // Note: We're not using phoneController here because IntlPhoneField gives us a complete number.
  final TextEditingController addressController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  String? errorMessage;

  // For loading animation.
  bool _isLoading = false;
  // To store the complete phone number from IntlPhoneField.
  String _completePhoneNumber = "";

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
      // After Google sign-in, navigate to the additional info screen.
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const AdditionalInfoScreen(authType: "google"),
        ),
      );
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
        // After Facebook sign-in, navigate to the additional info screen.
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdditionalInfoScreen(authType: "facebook"),
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
    if (_completePhoneNumber.isEmpty) {
      setState(() {
        errorMessage = "Phone number is required";
      });
      return;
    }
    setState(() {
      _isLoading = true;
      errorMessage = null;
    });
    try {
      // Create the user using email & password.
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      final user = userCredential.user;
      if (user != null) {
        await user.updateDisplayName(nameController.text.trim());
        // Store the additional data in Firestore with the phone number as the document ID.
        await FirebaseFirestore.instance
            .collection("users")
            .doc(_completePhoneNumber)
            .set({
          "uid": user.uid,
          "name": nameController.text.trim(),
          "company": companyController.text.trim(),
          "email": emailController.text.trim(),
          "phone": _completePhoneNumber,
          "address": addressController.text.trim(),
          "createdAt": FieldValue.serverTimestamp(),
          "authType": "email",
        });
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
    } else if (label == 'Phone Number') {
      if (!RegExp(r"^[+0-9]{8,15}$").hasMatch(value)) {
        return 'Enter a valid phone number';
      }
    }
    // Other fields (Full Name, Company Name, Address) require only non-empty validation.
    return null;
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
        body: Stack(
          children: [
            Container(
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
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 20 : 30,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  _buildTextField("Full Name", nameController, false),
                  const SizedBox(height: 15),
                  _buildTextField("Company Name", companyController, false),
                  const SizedBox(height: 15),
                  _buildTextField("Email", emailController, false,
                      keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 15),
                  _buildTextField("Password", passwordController, true),
                  const SizedBox(height: 15),
                  _buildTextField(
                      "Confirm Password", confirmPasswordController, true),
                  const SizedBox(height: 15),
                  IntlPhoneField(
                    decoration: InputDecoration(
                      labelText: 'Phone Number (include country code)',
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                    initialCountryCode: 'US',
                    style: const TextStyle(color: Colors.white),
                    onChanged: (phone) {
                      // Update the complete phone number.
                      _completePhoneNumber = phone.completeNumber;
                      print(phone.completeNumber);
                    },
                    validator: (phone) {
                      if (phone == null || phone.number.isEmpty) {
                        return "Phone number is required";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                  _buildTextField("Address", addressController, false),
                  const SizedBox(height: 30),
                  if (errorMessage != null) _buildErrorMessage(),
                ],
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
      validator: (value) => _validateInput(label, value),
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
