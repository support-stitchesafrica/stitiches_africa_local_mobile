import 'dart:convert';
import 'package:http/http.dart' as http;

class AdService {
  final String baseUrl;
  final String token;

  AdService({required this.baseUrl, required this.token});

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  /// Add an ad to favourites
  Future<Map<String, dynamic>> addFavouriteAd(String adId) async {
    final url = Uri.parse('$baseUrl/favourite/favourite');
    final response = await http.post(
      url,
      headers: _headers,
      body: jsonEncode({'adId': adId}),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)['message'] ??
          'Failed to add favourite');
    }
  }

  /// Get all favourite ads for the signed-in user
  Future<List<dynamic>> getFavouriteAds() async {
    final url = Uri.parse('$baseUrl/favourite/favourites');
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception(jsonDecode(response.body)['message'] ??
          'Failed to fetch favourite ads');
    }
  }

  /// Get all ads by a specific store (user)
  Future<List<dynamic>> getStoreListings(String storeUserId) async {
    final url = Uri.parse('$baseUrl/favourite/store/$storeUserId/listings');
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['ads'] as List<dynamic>;
    } else {
      throw Exception(jsonDecode(response.body)['message'] ??
          'Failed to fetch store listings');
    }
  }

  /// Get listing by ID (with store info)
  Future<Map<String, dynamic>> getListingById(String id) async {
    final url = Uri.parse('$baseUrl/favourite/listing/$id');
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(jsonDecode(response.body)['message'] ??
          'Failed to fetch listing');
    }
  }
}
