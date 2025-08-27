import 'dart:convert';
import 'package:http/http.dart' as http;

class CategoryService {
  final String baseUrl = "http://10.0.2.2:5000/api"; // Android emulator local API

  /// Fetch categories with their subcategories
  Future<List<Map<String, dynamic>>> getCategoriesWithSubcategories() async {
    final url = Uri.parse('$baseUrl/category/categories');
    print("🔍 Sending GET request to: $url");

    try {
      final response = await http.get(url, headers: {
        "Content-Type": "application/json",
      });

      print("✅ Response status: ${response.statusCode}");
      print("✅ Response body: ${response.body}");

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        print("✅ Decoded data: $data");

        // Convert to List<Map<String, dynamic>>
        return data.map((item) => {
              "category": item["category"],
              "subcategories": List<String>.from(item["subcategories"] ?? []),
            }).toList();
      } else {
        print("❌ Failed response: ${response.body}");
        throw Exception("Failed to fetch categories: ${response.body}");
      }
    } catch (e) {
      print("❌ Error occurred: $e");
      throw Exception("Error: $e");
    }
  }
}
