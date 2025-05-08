// ignore: depend_on_referenced_packages
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Returns the SHA-256 hash of the given [password].
String hashSensitiveInformation(String sensitiveInfo) {
  return sha256.convert(utf8.encode(sensitiveInfo)).toString();
}
