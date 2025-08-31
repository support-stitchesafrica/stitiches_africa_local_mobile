import 'package:flutter/material.dart';
import 'package:stitches_africa_local/models/ad.dart';
import 'package:stitches_africa_local/services/favourie_service.dart';
import 'package:stitches_africa_local/utils/prefs.dart';
import 'package:stitches_africa_local/product_cart.dart';

class FeaturedAdsPage extends StatefulWidget {
  const FeaturedAdsPage({super.key});

  @override
  State<FeaturedAdsPage> createState() => _FeaturedAdsPageState();
}

class _FeaturedAdsPageState extends State<FeaturedAdsPage> {
  List<Ad> favoriteAds = [];
  bool isLoading = true;
  String? errorMessage;
  late final AdService _adService;

  @override
  void initState() {
    super.initState();
    _adService = AdService(
      baseUrl: "https://stictches-africa-api-local.vercel.app/api",
      token: Prefs.token ?? "",
    );
    _loadFavoriteAds();
  }

  Future<void> _loadFavoriteAds() async {
    if (Prefs.token == null) {
      setState(() {
        isLoading = false;
        errorMessage = "Please login to view your favorites";
      });
      return;
    }

    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final favoriteAdsData = await _adService.getFavouriteAds();
      print("Favorite ads data: $favoriteAdsData");

      final ads = favoriteAdsData.map((favoriteData) {
        // Extract the 'ad' object from each favorite item
        final adData = favoriteData['ad'] as Map<String, dynamic>;
        return Ad.fromJson(adData);
      }).toList();

      setState(() {
        favoriteAds = ads;
        isLoading = false;
      });
    } catch (e, stackTrace) {
      print("Error loading favorites: $e");
      print("Stack trace: $stackTrace");
      setState(() {
        isLoading = false;
        errorMessage = "Error loading favorites: ${e.toString()}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          "My Favorites",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFavoriteAds,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : favoriteAds.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    "No favorite ads yet",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Add some products to your favorites to see them here",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(12),
              child: GridView.builder(
                itemCount: favoriteAds.length,
                physics: const BouncingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.7,
                ),
                itemBuilder: (context, index) {
                  final ad = favoriteAds[index];
                  return ProductCard(ad: ad);
                },
              ),
            ),
    );
  }
}
