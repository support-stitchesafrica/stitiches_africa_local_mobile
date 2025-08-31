import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  final String baseUrl = "https://stictches-africa-api-local.vercel.app/api";

  /// Register User
  Future<Map<String, dynamic>> registerUser({
    required String fullName,
    required String email,
    required String password,
    required String bvn,
    required String phone,
    String? category,
    double? latitude,
    double? longitude,
    String? address,
    String? gender,
    String? userType,
  }) async {
    final url = Uri.parse("$baseUrl/auth/register");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "fullName": fullName,
        "email": email,
        "password": password,
        "bvn": bvn,
        "phone": phone,
        "category": category,
        "latitude": latitude,
        "longitude": longitude,
        "address": address,
        "gender": gender,
        "userType": "CUSTOMER",
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      print("Registration failed with status: ${response.statusCode}");
      print("Response body: ${response.body}");

      try {
        final error = jsonDecode(response.body);
        throw Exception(error["message"] ?? "Registration failed");
      } catch (e) {
        throw Exception(
          "Registration failed: ${response.statusCode} - ${response.body}",
        );
      }
    }
  }

  /// Register Vendor
  Future<Map<String, dynamic>> registerVendor({
    required String fullName,
    required String email,
    required String password,
    required String brandName,
    required String phone,
    String? logo, // optional, backend expects uploaded file
    double? latitude,
    double? longitude,
    String? bvn,
    String? address,
    List<String>? category,
  }) async {
    final url = Uri.parse("$baseUrl/auth/register/vendor");

    // Create the request body with proper null handling
    final requestBody = <String, dynamic>{
      "fullName": fullName,
      "email": email,
      "password": password,
      "brandName": brandName,
      "phone": phone,
      "userType": "VENDOR",
    };

    // Add optional fields only if they're not null
    if (logo != null) requestBody["logo"] = logo;
    if (latitude != null) requestBody["latitude"] = latitude;
    if (longitude != null) requestBody["longitude"] = longitude;
    if (bvn != null) requestBody["bvn"] = bvn;
    if (address != null) requestBody["address"] = address;
    if (category != null && category.isNotEmpty) {
      // Convert list to comma-separated string if needed
      requestBody["category"] = category.join(", ");
    }

    // Debug: Print the request body
    print("=== REQUEST BODY ===");
    print("Request body: $requestBody");
    print("===================");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      print("Vendor registration failed with status: ${response.statusCode}");
      print("Response body: ${response.body}");

      try {
        final error = jsonDecode(response.body);
        throw Exception(error["message"] ?? "Vendor registration failed");
      } catch (e) {
        throw Exception(
          "Vendor registration failed: ${response.statusCode} - ${response.body}",
        );
      }
    }
  }

  /// Verify BVN
  Future<Map<String, dynamic>> verifyBVN(String bvn) async {
    final url = Uri.parse("$baseUrl/auth/verify-bvn");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"bvn": bvn}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error["message"] ?? "BVN verification failed");
    }
  }

  /// Login
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/auth/login');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      throw Exception('Invalid credentials');
    } else {
      throw Exception('Failed to login: ${response.statusCode}');
    }
  }
}
