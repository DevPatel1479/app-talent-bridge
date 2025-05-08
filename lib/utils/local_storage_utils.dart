import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

Future<SharedPreferences> getLocalUtilResource() async {
  SharedPreferences localStorageObject = await SharedPreferences.getInstance();
  return localStorageObject;
}

Future<void> setDataInLocalStorage(
  SharedPreferences prefs,
  Map<String, dynamic> data,
) async {
  for (var entry in data.entries) {
    final key = entry.key;
    final value = entry.value;

    if (value is String) {
      await prefs.setString(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    } else if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is List<String>) {
      await prefs.setStringList(key, value);
    } else {
      // Fallback: serialize anything else to a JSON string
      await prefs.setString(key, jsonEncode(value));
    }
  }
}

Future<Map<String, dynamic>> getDataFromLocalStorage(
    SharedPreferences prefs, List<String> keys) async {
  Map<String, dynamic> data = {};

  for (String key in keys) {
    dynamic value = prefs.get(key);
    if (value != null) {
      data[key] = value;
    }
  }

  return data;
}
