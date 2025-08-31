import 'package:flutter/material.dart';
import 'package:stitches_africa_local/models/ad.dart';
import 'package:stitches_africa_local/services/favourie_service.dart';
import 'package:stitches_africa_local/utils/prefs.dart';
import 'brand_listing_page.dart';

class FeaturedAdsPage extends StatefulWidget {
  const FeaturedAdsPage({super.key});

  @override
  State<FeaturedAdsPage> createState() => _FeaturedAdsPageState();
}

class _FeaturedAdsPageState extends State<FeaturedAdsPage> {
  Map<String, List<Ad>> brandAds = {};
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

      final ads = favoriteAdsData.map((favoriteData) {
        final adData = favoriteData['ad'] as Map<String, dynamic>;
        return Ad.fromJson(adData);
      }).toList();

      // ✅ Group ads by brand
      final grouped = <String, List<Ad>>{};
      for (final ad in ads) {
        final brand = ad.brand.isNotEmpty ? ad.brand : "Unknown Brand";
        grouped.putIfAbsent(brand, () => []).add(ad);
      }

      setState(() {
        brandAds = grouped;
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
          "My Favorites Stores",
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
          ?  Center(
            child: Image.asset(
              "images/Stitches Africa Logo-06.png", // ✅ your logo
              height: 120, // adjust size if needed
            ),
          )
          : errorMessage != null
          ? _buildError(errorMessage!)
          : brandAds.isEmpty
          ? _buildEmpty()
          : Padding(
              padding: const EdgeInsets.all(12),
              child: GridView.builder(
                itemCount: brandAds.keys.length,
                physics: const BouncingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.8,
                ),
                itemBuilder: (context, index) {
                  final brand = brandAds.keys.elementAt(index);
                  final ads = brandAds[brand]!;
                  final firstImage = ads.first.images.isNotEmpty
                      ? ads.first.images.first
                      : null;

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              BrandListingPage(brand: brand, ads: ads),
                        ),
                      );
                    },
                    child: Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12),
                                ),
                              ),
                              child: Center(
                                child: firstImage != null
                                    ? Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: ClipOval(
                                          child: Image.network(
                                            firstImage,
                                            fit: BoxFit
                                                .contain, // logo-like, not cropped
                                            width: 80,
                                            height: 80,
                                          ),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.image_not_supported,
                                        size: 60,
                                        color: Colors.grey,
                                      ),
                              ),
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              brand,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildError(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.favorite_border, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            msg,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.favorite_border, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            "No favorite ads yet",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Add some products to your favorites to see them here",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
