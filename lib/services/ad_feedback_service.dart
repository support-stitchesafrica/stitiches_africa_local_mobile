import 'dart:convert';
import 'package:http/http.dart' as http;

class AdFeedbackService {
  final String baseUrl;
  final String? token;

  AdFeedbackService({required this.baseUrl, this.token});

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  /// Add or update a rating for an ad
  Future<Map<String, dynamic>> addRating({
    required String adId,
    required int rating,
  }) async {
    final url = Uri.parse('$baseUrl/fedback/rating'); // ✅ fixed path
    print("➡️ POST $url");
    print("Headers: $_headers");
    print("Body: ${jsonEncode({'adId': adId, 'rating': rating})}");

    final response = await http.post(
      url,
      headers: _headers,
      body: jsonEncode({'adId': adId, 'rating': rating}),
    );

    print("⬅️ Response ${response.statusCode}: ${response.body}");

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to add rating: ${response.body}');
    }
  }

  /// Add a comment to an ad
  Future<Map<String, dynamic>> addComment({
    required String adId,
    required String content,
  }) async {
    final url = Uri.parse('$baseUrl/fedback/comment'); // ✅ fixed path
    print("➡️ POST $url");
    print("Headers: $_headers");
    print("Body: ${jsonEncode({'adId': adId, 'content': content})}");

    final response = await http.post(
      url,
      headers: _headers,
      body: jsonEncode({'adId': adId, 'content': content}),
    );

    print("⬅️ Response ${response.statusCode}: ${response.body}");

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to add comment: ${response.body}');
    }
  }

  /// Get all ratings and comments for an ad
  Future<Map<String, dynamic>> getFeedback(String adId) async {
    final url = Uri.parse('$baseUrl/fedback/$adId'); // ✅ fixed path
    print("➡️ GET $url");
    print("Headers: $_headers");

    final response = await http.get(url, headers: _headers);

    print("⬅️ Response ${response.statusCode}: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch feedback: ${response.body}');
    }
  }
}
