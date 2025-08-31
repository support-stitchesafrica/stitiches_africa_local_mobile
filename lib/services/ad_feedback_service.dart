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
    final url = Uri.parse('$baseUrl/fedback/rating');
    final response = await http.post(
      url,
      headers: _headers,
      body: jsonEncode({'adId': adId, 'rating': rating}),
    );

    if (response.statusCode == 201) {
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
    final url = Uri.parse('$baseUrl/fedback/comment');
    final response = await http.post(
      url,
      headers: _headers,
      body: jsonEncode({'adId': adId, 'content': content}),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to add comment: ${response.body}');
    }
  }

  /// Get all ratings and comments for an ad
  Future<Map<String, dynamic>> getFeedback(String adId) async {
    final url = Uri.parse('$baseUrl/fedback/$adId');
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch feedback: ${response.body}');
    }
  }
}
