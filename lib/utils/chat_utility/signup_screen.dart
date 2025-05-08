// signup_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'chat_socket.dart';
import 'users_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  Future<void> _handleSignup() async {
    if (_formKey.currentState!.validate()) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final phone = _phoneController.text.trim();

        await FirebaseFirestore.instance.collection('users').doc(phone).set({
          'name': _nameController.text.trim(),
          'phone': phone,
          'lastActive': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        });

        await prefs.setString('name', _nameController.text.trim());
        await prefs.setString('phone', phone);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const UsersScreen()),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _handleSignup,
                child: const Text('Sign Up'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
