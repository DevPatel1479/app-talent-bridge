import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class AuthenticationScreen extends StatefulWidget {
  const AuthenticationScreen({super.key});

  @override
  _AuthenticationScreenState createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool isLogin = true;
  bool _obscurePassword = true;
  String? errorMessage;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  void _toggleAuthMode() {
    setState(() {
      isLogin = !isLogin;
      errorMessage = null;
      isLogin ? _controller.reverse() : _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      final GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication;
      if (googleAuth == null) return;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
    } catch (e) {
      setState(() {
        errorMessage = "Google Sign-In Failed";
      });
    }
  }

  Future<void> _signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login();
      if (result.status == LoginStatus.success) {
        final AccessToken accessToken = result.accessToken!;
        final OAuthCredential credential =
            FacebookAuthProvider.credential(accessToken.tokenString);
        await _auth.signInWithCredential(credential);
      } else {
        setState(() {
          errorMessage = "Facebook Sign-In Failed";
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Facebook Sign-In Error";
      });
    }
  }

  void _validateAndSubmit() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        errorMessage = null;
      });
    } else {
      setState(() {
        errorMessage = "Please fix the errors above";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Full-screen background with gradient overlay for SignUp
            AnimatedContainer(
              duration: const Duration(seconds: 1),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isLogin
                      ? [
                          Colors.teal,
                          Colors.blueAccent
                        ] // Teal to Deep Blue for Login
                      : [
                          Colors.green.shade300,
                          Colors.green.shade700
                        ], // Green Gradient for SignUp
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.5),
                      Colors.black.withOpacity(0.2)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            // Main content - Ensure it's above the background
            SingleChildScrollView(
              child: Column(
                children: [
                  // Back Button and Heading (Aligned)
                  Padding(
                    padding: const EdgeInsets.only(left: 15, top: 30),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 28,
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                          const SizedBox(width: 10),
                          Text(
                            isLogin ? "Login" : "Sign Up",
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          // Email Text Field
                          _buildTextField("Email", emailController, false),
                          const SizedBox(height: 20),
                          // Password Text Field
                          _buildTextField("Password", passwordController, true),
                          if (errorMessage != null) _buildErrorMessage(),
                          const SizedBox(height: 20),
                          // Login/Sign Up Button
                          _buildActionButton(),
                          const SizedBox(height: 20),
                          // Social Media Buttons
                          _buildSocialButtons(),
                          const SizedBox(height: 20),
                          // Switch between Login/Sign Up
                          _buildSwitchAuthMode(),
                          const SizedBox(height: 50),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Email/Password Input Fields
  Widget _buildTextField(
      String label, TextEditingController controller, bool isPassword) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
      style: const TextStyle(color: Colors.white, fontSize: 18),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70, fontSize: 16),
        filled: true,
        fillColor: Colors.white.withOpacity(0.2),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        errorStyle: TextStyle(
          color: Colors.green, // Set error message color to yellow
          fontSize: 14, // Adjust font size if needed
          fontWeight: FontWeight.bold, // Optional: Make it bold for emphasis
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white70,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              )
            : null,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "$label cannot be empty";
        } else if (label == "Email" &&
            !RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")
                .hasMatch(value)) {
          return "Enter a valid email address";
        } else if (label == "Password" && value.length < 6) {
          return "Password must be at least 6 characters long";
        }
        return null;
      },
    );
  }

  // Error Message Display
  // Error Message Display
  Widget _buildErrorMessage() {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 500),
      opacity: errorMessage != null ? 1.0 : 0.0,
      child: Text(
        errorMessage!,
        style: const TextStyle(
          color: Colors.yellowAccent, // Change color to yellow
          fontSize: 16, // Increased font size for better visibility
          fontWeight: FontWeight.bold, // Bold for emphasis
        ),
      ),
    );
  }

  // Social Media Buttons (Google and Facebook)
  Widget _buildSocialButtons() {
    return Column(
      children: [
        _buildSocialButton("Continue with Google", Colors.redAccent,
            Icons.g_mobiledata, _signInWithGoogle),
        const SizedBox(height: 10),
        _buildSocialButton("Continue with Facebook", Colors.blueAccent,
            Icons.facebook, _signInWithFacebook),
      ],
    );
  }

  // Social Button
  Widget _buildSocialButton(
      String label, Color color, IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        icon: Icon(icon, size: 24),
        label: Text(label, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  // Login/Sign Up Action Button
  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _validateAndSubmit,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.tealAccent,
        ),
        child: Text(
          isLogin ? "Login" : "Sign Up",
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }

  // Switch Between Login/Sign Up Mode
  Widget _buildSwitchAuthMode() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          isLogin ? "Don't have an account?" : "Already have an account?",
          style: const TextStyle(fontSize: 16, color: Colors.white70),
        ),
        TextButton(
          onPressed: _toggleAuthMode,
          child: Text(
            isLogin ? "Sign Up" : "Login",
            style: const TextStyle(fontSize: 16, color: Colors.tealAccent),
          ),
        ),
      ],
    );
  }
}
