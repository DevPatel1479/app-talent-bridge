import 'package:cloud_firestore/cloud_firestore.dart';

class UserInfoData {
  final String uid;
  final String name;
  final String company;
  final String phone;
  final String address;
  final String password;
  final String authType;
  final String userRole;
  final String email;
  final FieldValue createdAt;

  UserInfoData({
    required this.uid,
    required this.name,
    required this.company,
    required this.phone,
    required this.address,
    required this.password,
    required this.authType,
    required this.userRole,
    required this.email,
    required this.createdAt
  });
}
