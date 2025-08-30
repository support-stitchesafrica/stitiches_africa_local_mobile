import 'dart:convert';
import 'package:http/http.dart' as http;

class CategoryService {
  final String baseUrl =
      "https://stictches-africa-api-local.vercel.app/api"; // Update if needed

  /// Fetch categories from backend
  Future<List<Map<String, dynamic>>> getCategories() async {
    final url = Uri.parse('$baseUrl/category/categories');
    print("🔍 Sending GET request to: $url");

    try {
      final response = await http.get(
        url,
        headers: {"Content-Type": "application/json"},
      );

      print("✅ Response status: ${response.statusCode}");
      print("✅ Response body: ${response.body}");

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        print("✅ Decoded data: $data");

        // Convert to List<Map<String, dynamic>> (id + categoryName only)
        return data
            .map<Map<String, dynamic>>(
              (item) => {
                "id": item["id"],
                "categoryName": item["categoryName"],
              },
            )
            .toList();
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
