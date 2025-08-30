import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'models/ad.dart';
import 'services/ad_service.dart';
import 'services/category_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';


// NEW: location imports
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';


class HomePage extends StatefulWidget {
const HomePage({super.key});


@override
State<HomePage> createState() => _HomePageState();
}


class _HomePageState extends State<HomePage> {
final CategoryService _categoryService = CategoryService();


static const List<String> backendCategories = [
"BESPOKE",
"READY TO WEAR",
"FABRIC STORE OWNER",
];


bool _isLoading = false;
String? error;
List<Ad> allAds = [];
String? token;


Position? _position;
String _address = "Detecting location...";
bool _locBusy = false;


List<String> _nearbyStores = [];
String? _selectedNearbyStore;


final Map<String, (double? lat, double? lng)> _brandLocation = {};


static const double _radiusKm = 5.0;


@override
void initState() {
super.initState();
_initEverything();
}


Future<void> _initEverything() async {
setState(() {
_isLoading = true;
error = null;
});


try {
await _determineAndReverseGeocode();
}
  @override
  Widget build(BuildContext context) {
    final busy = _isLoading || _locBusy;
    return Scaffold(
      backgroundColor: Colors.white,
      body: busy
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text("Error: $error"))
              : CustomScrollView(
                  slivers: [
                    // HEADER: two horizontal fields (Location + Nearby Store dropdown)
                    SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        color: Colors.black,
                        child: Row(
                          children: [
                            // Location display (tap to refresh)
                            Expanded(
                              child: GestureDetector(
                                onTap: _refreshLocationAndStores,
                                child: Container(
                                  height: 44,
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.my_location, color: Colors.black),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _address,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Icon(Icons.refresh, color: Colors.black54, size: 18),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Nearby store dropdown (within 5km)
                            Expanded(
                              child: Container(
                                height: 44,
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedNearbyStore,
                                    isExpanded: true,
                                    icon: const Icon(Icons.expand_more, color: Colors.black),
                                    hint: const Text(
                                      "Nearby stores (5km)",
                                      style: TextStyle(
                                        color: Colors.black54,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    items: _nearbyStores
                                        .map(
                                          (store) => DropdownMenuItem(
                                            value: store,
                                            child: Text(store, overflow: TextOverflow.ellipsis),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (val) {
                                      setState(() => _selectedNearbyStore = val);
                                      if (val != null) {
                                        final ads = _adsForStore(val);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ShopListingsPage(storeName: val, ads: ads),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // CATEGORIES (no subcategories)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Text(
                          "Categories",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: backendCategories.length,
                          itemBuilder: (context, index) {
                            final category = backendCategories[index];
                            final color = _getColorForCategory(category);
                            final icon = _getIconForCategory(category);
                            return GestureDetector(
                              onTap: () {
                                final stores = _storesForCategory(category);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CategoryStoresPage(
                                      category: category,
                                      stores: stores,
                                      adsResolver: (store) => _adsForStore(store, category: category),
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                width: 110,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: color,
                                      radius: 22,
                                      child: Icon(icon, color: Colors.white, size: 20),
                                    ),
                                    const SizedBox(height: 6),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 6),
                                      child: Text(
                                        category,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 2,
                                        textAlign: TextAlign.center,
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
                    ),

                    // STORES (nearby only)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Text(
                          "Stores",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    if (_nearbyStores.isEmpty)
                      const SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Text(
                              "No stores found within 5 km",
                              style: TextStyle(fontSize: 14, color: Colors.black54),
                            ),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        sliver: SliverGrid(
                          delegate: SliverChildBuilderDelegate((context, index) {
                            final storeName = _nearbyStores[index];
                            return GestureDetector(
                              onTap: () {
                                final ads = _adsForStore(storeName);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ShopListingsPage(
                                      storeName: storeName,
                                      ads: _uniqueByTitleAndImages(ads),
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    CircleAvatar(
                                      radius: 30,
                                      backgroundColor: Colors.black,
                                      child: Icon(Icons.store, color: Colors.white, size: 28),
                                    ),
                                    SizedBox(height: 8),
                                  ],
                                ),
                              ),
                            );
                          }, childCount: _nearbyStores.length),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 1,
                          ),
                        ),
                      ),
                    // Under each store tile, show its name (outside the avatar to handle long text)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Wrap(
                          spacing: 16,
                          runSpacing: 12,
                          children: _nearbyStores
                              .map(
                                (s) => SizedBox(
                                  width: MediaQuery.of(context).size.width / 2 - 28,
                                  child: Text(
                                    s,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }


  IconData _getIconForCategory(String category) {
    switch (category.trim().toUpperCase()) {
      case "BESPOKE":
        return Icons.cut;
      case "READY TO WEAR":
        return Icons.checkroom;
      case "FABRIC STORE OWNER":
        return Icons.store_mall_directory;
      default:
        return Icons.category;
    }
  }

  Color _getColorForCategory(String category) {
    switch (category.trim().toUpperCase()) {
      case "BESPOKE":
        return Colors.cyan;
      case "READY TO WEAR":
        return Colors.pinkAccent;
      case "FABRIC STORE OWNER":
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  // TEMPORARY: Remove duplicates by title + images
  List<Ad> _uniqueByTitleAndImages(List<Ad> ads) {
    final seen = <String, bool>{};
    final uniqueAds = <Ad>[];
    for (final ad in ads) {
      final key = '${ad.title}_${ad.images.join(",")}';
      if (!seen.containsKey(key)) {
        seen[key] = true;
        uniqueAds.add(ad);
      }
    }
    return uniqueAds;
  }
}

/// Category -> Stores (within 5km) page
class CategoryStoresPage extends StatelessWidget {
  final String category;
  final List<String> stores;
  final List<Ad> Function(String store) adsResolver;

  const CategoryStoresPage({
    super.key,
    required this.category,
    required this.stores,
    required this.adsResolver,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("$category Stores (5 km)"),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
      ),
      body: stores.isEmpty
          ? const Center(child: Text("No stores nearby for this category"))
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: stores.length,
              itemBuilder: (context, index) {
                final store = stores[index];
                return GestureDetector(
                  onTap: () {
                    final ads = adsResolver(store);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ShopListingsPage(
                          storeName: store,
                          ads: ads,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.black,
                          child: Icon(Icons.store, color: Colors.white, size: 28),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            store,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

/// Store Listings Page (replaces BrandListingsPage)


/// Product Card Component (unchanged)
class ProductCard extends StatelessWidget {
  final Ad ad;
  const ProductCard({super.key, required this.ad});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (ctx) => ProductDetailPage(ad: ad)),
      ),
      child: Card(
        elevation: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ad.images.isNotEmpty
                  ? Image.network(
                      ad.images.first,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    )
                  : const Icon(Icons.image_not_supported, size: 80),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                ad.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text("₦${ad.price}"),
            ),
          ],
        ),
      ),
    );
  }
}

/// Product Detail Page (kept; call/WhatsApp intact)
class ProductDetailPage extends StatelessWidget {
  final Ad ad;
  const ProductDetailPage({super.key, required this.ad});

  void _callVendor(String phone) async {
    final uri = Uri.parse("tel:$phone");
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _whatsappVendor(String phone, String message) async {
    final uri = Uri.parse(
      "https://wa.me/$phone?text=${Uri.encodeComponent(message)}",
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            backgroundColor: Colors.white,
            iconTheme: const IconThemeData(color: Colors.black),
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: ad.id,
                child: ad.images.isNotEmpty
                    ? Image.network(ad.images.first, fit: BoxFit.cover)
                    : const Icon(Icons.image_not_supported, size: 100),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ad.title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Chip(
                        label: Text(ad.category),
                        backgroundColor: Colors.teal.shade50,
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(ad.brand),
                        backgroundColor: Colors.orange.shade50,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "₦${ad.price}",
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const Text(
                    "Contact Vendor",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _callVendor(ad.phone),
                          icon: const Icon(Icons.call, color: Colors.white),
                          label: const Text(
                            "Call Vendor",
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
  child: ElevatedButton.icon(
    onPressed: () {
      final message = "Hello, I'm interested in your ${ad.title}";
      _whatsappVendor(ad.phone, message);
    },
    icon: const FaIcon(
      FontAwesomeIcons.whatsapp,
      color: Colors.white,
    ),
    label: const Text(
      "WhatsApp Vendor",
      style: TextStyle(color: Colors.white),
    ),
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF25D366),
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
),

                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
