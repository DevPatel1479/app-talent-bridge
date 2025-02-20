import 'package:http/http.dart' as http;
import 'dart:convert';

class API {
  final Map<dynamic, dynamic> service_type;

  API({required this.service_type});

  Future<http.Response> sendOTP() async {
    if (service_type.containsKey("service_type")) {
      String value = service_type["service_type"]!;
      if (value == "email") {
        String email_value = service_type["data"]!;
        final response = await http.post(
          Uri.parse('https://talent-bridge-steel.vercel.app/send-otp'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email_value}),
        );

        return http.Response(response.body, response.statusCode);
      }
    }
    return http.Response("API error", 404);
  }

  Future<http.Response> verifyOTP() async {
    if (service_type.containsKey("service_type")) {
      String value = service_type["service_type"]!;
      if (value == "email") {
        Map<String, String> email_otp =
            service_type["data"]! as Map<String, String>;

        final response = await http.post(
          Uri.parse('https://talent-bridge-steel.vercel.app/verify-otp'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(
              {'email': email_otp["email"], "otp": email_otp["otp"]}),
        );

        return http.Response(response.body, response.statusCode);
      }
    }
    return http.Response("API error", 404);
  }
}
