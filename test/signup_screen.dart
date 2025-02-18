import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'users_list_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      String name = _nameController.text.trim();
      String phone = '+91' + _phoneController.text.trim(); // Auto-append +91

      // Save user info into SharedPreferences.
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isSignedUp', true);
      await prefs.setString('userName', name);
      await prefs.setString('userPhone', phone);

      // Also store user info into Firestore.
      try {
        await FirebaseFirestore.instance.collection('users').doc(phone).set({
          'name': name,
          'phone': phone,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        print("Error storing user data in Firestore: $e");
      }

      // Navigate to the Users List screen.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const UsersListScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Signup'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple, Colors.black],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Please enter your name';
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixText: '+91 ',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.length != 10)
                    return 'Enter a valid 10-digit number';
                  return null;
                },
              ),
              const SizedBox(height: 24.0),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Signup'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
