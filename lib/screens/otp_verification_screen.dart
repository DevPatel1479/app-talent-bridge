import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import 'package:talentbridge/model/UserInfoModel.dart';
import 'package:http/http.dart' as http;
import 'package:talentbridge/api_services/api_service.dart' as api;

class OtpVerificationScreen extends StatefulWidget {
  final UserInfoData data;
  const OtpVerificationScreen({Key? key, required this.data}) : super(key: key);

  @override
  _OtpVerificationScreenState createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  bool _isVerifying = false;
  String? _otpError;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  void dispose() {
    for (var ctrl in _otpControllers) ctrl.dispose();
    for (var node in _otpFocusNodes) node.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
    super.dispose();
  }

  String get _otpCode => _otpControllers.map((e) => e.text).join();

  Future<bool> _verifyOtp(String email, String otp) async {
    http.Response response = await api.API(service_type: {
      "service_type": "email",
      "data": {"email": email, "otp": otp}
    }).verifyOTP();

    if (response.statusCode == 200) {
      return true;
    }
    return false;
  }

  Future<void> _onVerify() async {
    setState(() {
      _isVerifying = true;
      _otpError = null;
    });
    final otp = _otpCode;
    if (otp.length != 6) {
      setState(() {
        _otpError = "Please enter a 6-digit OTP";
        _isVerifying = false;
      });
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final success = await _verifyOtp(user.email!, otp);
      if (success) {
        try {
          // final user = FirebaseAuth.instance.currentUser;
          // if (user != null) {
          //   await FirebaseFirestore.instance
          //       .collection("users")
          //       .doc(widget.data.phone)
          //       .set({
          //     "uid": user.uid,
          //     "name": widget.data.name,
          //     "company": widget.data.company,
          //     "phone": widget.data.phone,
          //     "address": widget.data.address,
          //     "createdAt": FieldValue.serverTimestamp(),
          //     "authType": widget.data.authType,
          //     "userRole": widget.data.userRole,
          //   });
          // }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("OTP Verified! Your data has been stored."),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
          
          // Navigator.popUntil(context, (route) => route.isFirst);
        } catch (e) {
          setState(() {
            _otpError = "Error storing data: ${e.toString()}";
          });
        }
      } else {
        setState(() {
          _otpError = "Invalid OTP. Please try again.";
        });
      }
    }

    setState(() {
      _isVerifying = false;
    });
  }

  Widget _buildOtpBox(int index, double boxSize) {
    return Container(
      width: boxSize,
      height: boxSize,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _otpFocusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: TextStyle(fontSize: boxSize * 0.4, color: Colors.white),
        decoration: InputDecoration(
          counterText: "",
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            _otpFocusNodes[index].unfocus();
            FocusScope.of(context).requestFocus(_otpFocusNodes[index + 1]);
          } else if (value.isEmpty && index > 0) {
            FocusScope.of(context).requestFocus(_otpFocusNodes[index - 1]);
          }
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 20,
        right: 20,
        bottom: 10,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 12),
          const Text(
            "OTP Verification",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A1A1A), Color(0xFF121212)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: isPortrait
                              ? MediaQuery.of(context).size.height * 0.3
                              : MediaQuery.of(context).size.height * 0.2,
                          child: Lottie.asset(
                            'assets/animations_assets/otp_verification.json',
                            repeat: true,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "Enter the 6-digit OTP sent to your email",
                          style: TextStyle(color: Colors.white, fontSize: 18),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 30),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final availableWidth = constraints.maxWidth;
                            final totalHorizontalSpace =
                                isPortrait ? 70.0 : 40.0;
                            final availableWidthForBoxes =
                                availableWidth - totalHorizontalSpace;
                            final boxSize = (availableWidthForBoxes / 6)
                                .clamp(isPortrait ? 45 : 35, 60)
                                .toDouble();

                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 5),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  6,
                                  (index) => _buildOtpBox(index, boxSize),
                                ),
                              ),
                            );
                          },
                        ),
                        if (_otpError != null) ...[
                          const SizedBox(height: 20),
                          AnimatedOpacity(
                            opacity: 1.0,
                            duration: const Duration(milliseconds: 500),
                            child: Text(
                              _otpError ?? "",
                              style: const TextStyle(
                                  color: Colors.redAccent, fontSize: 16),
                            ),
                          ),
                        ],
                        const SizedBox(height: 30),
                        _isVerifying
                            ? const CircularProgressIndicator()
                            : ElevatedButton(
                                onPressed: _onVerify,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 40, vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  backgroundColor: const Color(0xFF00C9A7),
                                ),
                                child: const Text(
                                  "Verify OTP",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                      ],
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
}
