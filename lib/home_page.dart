import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import 'models/ad.dart';
import 'services/ad_service.dart';
import 'shop_listing_page.dart';
import 'category_store.dart';
import 'utils/ad_utils.dart'; // ✅ import helper
import 'product_cart.dart'; // Import ProductCard

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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

  late final AdService _adService;

  @override
  void initState() {
    super.initState();
    _initEverything();
  }

  @override
  void dispose() {
    // Clean up any resources if needed
    super.dispose();
  }

  Future<void> _initEverything() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      error = null;
    });

    try {
      await _loadToken();
      _adService = AdService(
        baseUrl: "https://stictches-africa-api-local.vercel.app/api",
        token: token,
      );
      await _determineAndReverseGeocode();
      await _fetchAdsByLocation();
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token');
  }

  Future<void> _determineAndReverseGeocode() async {
    if (!mounted) return;
    setState(() => _locBusy = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception("Location services are disabled.");
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception("Location permission denied.");
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          "Location permission permanently denied. Enable it in settings.",
        );
      }

      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );

      String fullAddress = "";
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        fullAddress =
            "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}";
      }

      if (mounted) {
        setState(() {
          _position = pos;
          _address = fullAddress;
          _locBusy = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _locBusy = false);
        setState(() => error = "Error fetching location: $e");
      }
    }
  }

  Future<void> _fetchAdsByLocation() async {
    if (_position == null || !mounted) return;

    try {
      final ads = await _adService.getAdsByLocation(
        _position!.latitude,
        _position!.longitude,
        radius: 20,
      );
      if (mounted) {
        setState(() {
          allAds = ads;
        });
        print("=== ADS FETCHED ===");
        print("Total ads: ${ads.length}");
        print("Ads: ${ads.map((ad) => '${ad.title} (${ad.brand})').toList()}");
        print("===================");
        _populateNearbyStoresFromAds();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = "Failed to fetch ads: $e";
        });
      }
    }
  }

  void _populateNearbyStoresFromAds() {
    if (!mounted) return;

    final uniqueBrands = allAds.map((ad) => ad.brand.trim()).toSet().toList();

    setState(() {
      _nearbyStores = uniqueBrands;
      if (_nearbyStores.isNotEmpty && _selectedNearbyStore == null) {
        _selectedNearbyStore = _nearbyStores.first;
      }
    });
  }

  List<Ad> _adsForStore(String storeName) {
    return allAds
        .where(
          (ad) =>
              ad.brand.trim().toLowerCase() == storeName.trim().toLowerCase(),
        )
        .toList();
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

  Future<void> _refreshLocationAndStores() async {
    await _determineAndReverseGeocode();
    await _fetchAdsByLocation();
  }

  List<String> _storesForCategory(String category) {
    return _nearbyStores
        .where(
          (store) => allAds.any(
            (ad) =>
                ad.brand.trim().toLowerCase() == store.trim().toLowerCase() &&
                ad.categoryName.trim().toUpperCase() ==
                    category.trim().toUpperCase(),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final busy = _isLoading || _locBusy;

    // Debug information
    print("=== BUILD DEBUG ===");
    print("isLoading: $_isLoading");
    print("locBusy: $_locBusy");
    print("error: $error");
    print("allAds length: ${allAds.length}");
    print("nearbyStores: $_nearbyStores");
    print("selectedNearbyStore: $_selectedNearbyStore");
    print("==================");

    return Scaffold(
      backgroundColor: Colors.white,
      body: busy
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(child: Text(error!))
          : CustomScrollView(
              slivers: [
                // HEADER
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    color: Colors.black,
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: _refreshLocationAndStores,
                            child: Container(
                              height: 44,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.my_location,
                                    color: Colors.black,
                                  ),
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
                                  const Icon(
                                    Icons.refresh,
                                    color: Colors.black54,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
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
                                icon: const Icon(
                                  Icons.expand_more,
                                  color: Colors.black,
                                ),
                                hint: const Text(
                                  "Nearby stores",
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
                                        child: Text(
                                          store,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) {
                                  setState(() => _selectedNearbyStore = val);
                                  if (val != null) {
                                    final ads = _adsForStore(val);
                                    print("Ads for store '$val': $ads");
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ShopListingsPage(
                                          storeName: val,
                                          ads: uniqueAdsByTitleAndImages(
                                            ads,
                                          ), // ✅ use helper
                                        ),
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

                // CATEGORIES
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
                            print("Stores for category '$category': $stores");
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CategoryStoresPage(
                                  category: category,
                                  stores: stores,
                                  adsResolver: (store) => _adsForStore(store),
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
                                  child: Icon(
                                    icon,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
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

                // MAIN CONTENT - ADS LISTINGS
                if (allAds.isNotEmpty) ...[
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Text(
                        "Nearby Listings",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.7,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final ad = allAds[index];
                        return ProductCard(ad: ad);
                      }, childCount: allAds.length),
                    ),
                  ),
                ] else ...[
                  // NO ADS FOUND
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.store_mall_directory_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No listings found nearby",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Try refreshing or check back later",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _refreshLocationAndStores,
                            icon: const Icon(Icons.refresh),
                            label: const Text("Refresh"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
