import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talentbridge/screens/client_dashboard_screen.dart';
import 'package:talentbridge/utils/hash_utils.dart';
import 'package:talentbridge/utils/local_storage_utils.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onToggleAuth;

  const LoginScreen({super.key, required this.onToggleAuth});

  @override
  // ignore: library_private_types_in_public_api
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  String? errorMessage;
  bool _isSubmitting = false;
  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54, // semi-transparent background
      builder: (_) => Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                color: Colors.white,
              ),
              const SizedBox(height: 20),
              Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _hideLoadingDialog() {
    if (Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
  }

  // Future<void> _signInWithGoogle() async {
  //   try {
  //     final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
  //     final GoogleSignInAuthentication? googleAuth =
  //         await googleUser?.authentication;
  //     if (googleAuth == null) return;

  //     final credential = GoogleAuthProvider.credential(
  //       accessToken: googleAuth.accessToken,
  //       idToken: googleAuth.idToken,
  //     );

  //     await _auth.signInWithCredential(credential);
  //     UserCredential userCredential =
  //         await _auth.signInWithCredential(credential);
  //     User? user = userCredential.user;

  //     if (user != null) {
  //       print("✅ Google Email: ${user.email}");
  //       try {
  //         // Efficient query: Find user where 'email' equals the entered email.
  //         QuerySnapshot querySnapshot = await FirebaseFirestore.instance
  //             .collection('users')
  //             .where('email', isEqualTo: user.email)
  //             .get();

  //         if (querySnapshot.docs.isNotEmpty) {
  //           // Fetch the first document (should be unique for a given email)
  //           final userDoc = querySnapshot.docs.first;
  //           final userData = userDoc.data() as Map<String, dynamic>;

  //           // Login successful – you may now proceed further, such as navigating to the dashboard.
  //           print("Login successful");
  //           Map<String, dynamic> data = {
  //             "email": userData["email"],
  //             "isLoggedIn": true,
  //             // "phoneNumber": widget.data.phone,
  //             "userRole": userData["userRole"],
  //             "name": userData["name"]
  //           };
  //           // SharedPreferences prefs = await getLocalUtilResource();
  //           // setDataInLocalStorage(prefs, data);
  //           print(data);
  //           // For example, you can call Navigator.pushReplacement(...) here.
  //         } else {
  //           setState(() {
  //             errorMessage = "No user found with this email";
  //           });
  //         }
  //       } catch (e) {
  //         setState(() {
  //           errorMessage = "Error: ${e.toString()}";
  //         });
  //       } finally {
  //         if (mounted) {
  //           setState(() {
  //             _isSubmitting = false;
  //           });
  //         }
  //       }
  //     }
  //   } catch (e) {
  //     setState(() {
  //       errorMessage = "Google Sign-In Failed";
  //     });
  //   }
  // }

  Future<void> _signInWithGoogle() async {
    _showLoadingDialog("Signing in with Google...");
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      final GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication;
      if (googleAuth == null) {
        _hideLoadingDialog();
        return;
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: user.email)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final userDoc = querySnapshot.docs.first;
          final userData = userDoc.data() as Map<String, dynamic>;
          print("✅ Google login successful");
          Map<String, dynamic> data = {
            "email": userData["email"],
            "name": userData["name"],
            "isLoggedIn": true,
            // "phoneNumber": widget.data.phone,
            "userRole": userData["userRole"],
          };
          print("data to shared $data");
          SharedPreferences prefs = await getLocalUtilResource();
          await setDataInLocalStorage(prefs, data);
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const ClientDashboardScreen(),
            ),
            (Route<dynamic> route) => false,
          );
        } else {
          setState(() {
            errorMessage = "No user found with this email";
          });
        }
      }
    } catch (e) {
      setState(() {
        errorMessage = "Google Sign-In Failed: $e";
      });
    } finally {
      _hideLoadingDialog();
    }
  }

  // Future<void> _signInWithFacebook() async {
  //   try {
  //     final LoginResult result = await FacebookAuth.instance.login();
  //     if (result.status == LoginStatus.success) {
  //       final AccessToken accessToken = result.accessToken!;
  //       final OAuthCredential credential =
  //           FacebookAuthProvider.credential(accessToken.tokenString);
  //       await _auth.signInWithCredential(credential);
  //       UserCredential userCredential =
  //           await _auth.signInWithCredential(credential);
  //       User? user = userCredential.user;

  //       if (user != null) {
  //         print("✅ Facebook Email: ${user.email}");
  //         try {
  //           // Efficient query: Find user where 'email' equals the entered email.
  //           QuerySnapshot querySnapshot = await FirebaseFirestore.instance
  //               .collection('users')
  //               .where('email', isEqualTo: user.email)
  //               .get();

  //           if (querySnapshot.docs.isNotEmpty) {
  //             // Fetch the first document (should be unique for a given email)
  //             final userDoc = querySnapshot.docs.first;
  //             final userData = userDoc.data() as Map<String, dynamic>;

  //             // Login successful – you may now proceed further, such as navigating to the dashboard.
  //             print("Login successful");
  //             Map<String, dynamic> data = {
  //               "email": userData["email"],
  //               "isLoggedIn": true,
  //               // "phoneNumber": widget.data.phone,
  //               "userRole": userData["userRole"],
  //               "name": userData["name"]
  //             };
  //             // SharedPreferences prefs = await getLocalUtilResource();
  //             // setDataInLocalStorage(prefs, data);
  //             print(data);
  //             // For example, you can call Navigator.pushReplacement(...) here.
  //           } else {
  //             setState(() {
  //               errorMessage = "No user found with this email";
  //             });
  //           }
  //         } catch (e) {
  //           setState(() {
  //             errorMessage = "Error: ${e.toString()}";
  //           });
  //         } finally {
  //           if (mounted) {
  //             setState(() {
  //               _isSubmitting = false;
  //             });
  //           }
  //         }
  //       }
  //     } else {
  //       setState(() {
  //         errorMessage = "Facebook Sign-In Failed";
  //       });
  //     }
  //   } catch (e) {
  //     setState(() {
  //       errorMessage = "Facebook Sign-In Error";
  //     });
  //   }
  // }

  Future<void> _signInWithFacebook() async {
    _showLoadingDialog("Signing in with Facebook...");
    try {
      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status == LoginStatus.success) {
        final AccessToken accessToken = result.accessToken!;
        final OAuthCredential credential =
            FacebookAuthProvider.credential(accessToken.tokenString);
        UserCredential userCredential =
            await _auth.signInWithCredential(credential);
        User? user = userCredential.user;

        if (user != null) {
          QuerySnapshot querySnapshot = await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: user.email)
              .get();

          if (querySnapshot.docs.isNotEmpty) {
            final userDoc = querySnapshot.docs.first;
            final userData = userDoc.data() as Map<String, dynamic>;
            print("✅ Facebook login successful");
            Map<String, dynamic> data = {
              "email": userData["email"],
              "isLoggedIn": true,
              // "phoneNumber": widget.data.phone,
              "userRole": userData["userRole"],
              "name": userData["name"]
            };
            SharedPreferences prefs = await getLocalUtilResource();
            setDataInLocalStorage(prefs, data);
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => const ClientDashboardScreen(),
              ),
              (Route<dynamic> route) => false,
            );
          } else {
            setState(() {
              errorMessage = "No user found with this email";
            });
          }
        }
      } else {
        setState(() {
          errorMessage = "Facebook Sign-In Failed";
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Facebook Sign-In Error: $e";
      });
    } finally {
      _hideLoadingDialog();
    }
  }

  void _validateAndSubmit() {
    if (_formKey.currentState!.validate()) {
      _loginWithEmailAndPassword();
      setState(() {
        errorMessage = null;
      });
    } else {
      setState(() {
        errorMessage = "Please fix the errors above";
      });
    }
  }

  /// This function validates the form and then performs login by querying Firestore.
  Future<void> _loginWithEmailAndPassword() async {
    if (_formKey.currentState?.validate() != true) {
      setState(() {
        errorMessage = "Please fix the errors above";
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      errorMessage = null;
    });

    final String email = emailController.text.trim();
    final String password = passwordController.text.trim();

    // Hash the provided password using SHA-256.
    final String hashedPassword = hashSensitiveInformation(password);

    try {
      // Efficient query: Find user where 'email' equals the entered email.
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Fetch the first document (should be unique for a given email)
        final userDoc = querySnapshot.docs.first;
        final userData = userDoc.data() as Map<String, dynamic>;
        final String storedPassword = userData['password'] as String;

        if (hashedPassword == storedPassword) {
          // Login successful – you may now proceed further, such as navigating to the dashboard.
          print("Login successful");
          Map<String, dynamic> data = {
            "email": userData["email"],
            "isLoggedIn": true,
            // "phoneNumber": widget.data.phone,
            "userRole": userData["userRole"],
            "name": userData["name"]
          };
          SharedPreferences prefs = await getLocalUtilResource();
          await setDataInLocalStorage(prefs, data);
          print('STORED client_name = ${prefs.getString('client_name')}');
          print('STORED all keys   = ${prefs.getKeys()}');
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const ClientDashboardScreen(),
            ),
            (Route<dynamic> route) => false,
          );

          print(data);
          // For example, you can call Navigator.pushReplacement(...) here.
        } else {
          setState(() {
            errorMessage = "Incorrect password";
          });
        }
      } else {
        setState(() {
          errorMessage = "No user found with this email";
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error: ${e.toString()}";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: const Color(0xFF1A1A1A), // Match gradient start color
        statusBarIconBrightness: Brightness.light, // White icons
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor:
            const Color(0xFF1A1A1A), // Dark navigation bar
        systemNavigationBarIconBrightness: Brightness.light, // White icons
      ),
      child: Scaffold(
        body: Container(
          constraints: const BoxConstraints.expand(),
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
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(
                      left: isSmallScreen ? 15 : 30,
                      top: MediaQuery.of(context).padding.top + 20),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "Login",
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 25 : 40,
                    vertical: 40,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildTextField("Email", emailController, false),
                        const SizedBox(height: 25),
                        _buildTextField("Password", passwordController, true),
                        const SizedBox(height: 30),
                        if (errorMessage != null) _buildErrorMessage(),
                        _buildActionButton(),
                        const SizedBox(height: 30),
                        const Text(
                          "OR",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.white70),
                        ),
                        const SizedBox(height: 30),
                        _buildSocialButtons(isSmallScreen),
                        const SizedBox(height: 25),
                        _buildSwitchAuthMode(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label, TextEditingController controller, bool isPassword) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
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

  String? _validateInput(String label, String? value) {
    if (value == null || value.isEmpty) {
      return "$label cannot be empty";
    } else if (label == "Email" &&
        !RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")
            .hasMatch(value)) {
      return "Enter a valid email address";
    }
    // } else if (label == "Password") {
    //   return "Password must be at least 6 characters long";
    // }
    return null;
  }

  Widget _buildErrorMessage() {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 500),
      opacity: errorMessage != null ? 1.0 : 0.0,
      child: Container(
        padding: const EdgeInsets.all(10),
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
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 14,
                ),
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

  Widget _buildSocialButton(String label, Gradient gradient, IconData icon,
      VoidCallback onTap, bool isSmallScreen) {
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
            color: Colors.tealAccent.shade400!.withOpacity(0.3),
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
          child: _isSubmitting
              ? const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                )
              : const Text(
                  "Login",
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
        const Text("Don't have an account?",
            style: TextStyle(color: Colors.white70)),
        TextButton(
          onPressed: widget.onToggleAuth,
          child: const Text("Sign Up",
              style: TextStyle(
                  color: Color(0xFF00C9A7), fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
