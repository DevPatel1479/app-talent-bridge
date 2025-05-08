import 'package:cloud_firestore/cloud_firestore.dart';

class UserInfoData {
  String uid;
  final String name;
  final String company;
  String? phone;
  final String country;
  final String password;
  final String profileImagePath;
  final String? authType;
  final String userRole;
  final String email;
  final FieldValue createdAt;
  final String state;
  final String district;

  UserInfoData(
      {required this.uid,
      required this.name,
      required this.company,
      // required this.phone,
      required this.country,
      required this.password,
      required this.userRole,
      required this.email,
      required this.createdAt,
      required this.profileImagePath,
      required this.state,
      required this.district,
      this.authType});
}
