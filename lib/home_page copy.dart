import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/ad.dart';
import 'services/ad_service.dart';
import 'services/category_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final CategoryService _categoryService = CategoryService();
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = false;
  String? error;
  List<String> brandList = []; // ✅ Only store brand names
  String? token;
  double? latitude;
  double? longitude;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _loadDataAndFetchBrands();
  }

  Future<void> _fetchCategories() async {
    try {
      setState(() => _isLoading = true);
      final data = await _categoryService.getCategoriesWithSubcategories();
      setState(() {
        _categories = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching categories: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadDataAndFetchBrands() async {
    try {
      setState(() {
        _isLoading = true;
        error = null;
      });

      final prefs = await SharedPreferences.getInstance();
      token = prefs.getString('token');
      latitude = prefs.getDouble('latitude');
      longitude = prefs.getDouble('longitude');

      if (latitude == null || longitude == null) {
        throw Exception("Location not found. Please log in again.");
      }

      final adService = AdService(
        baseUrl: "https://stictches-africa-api-local.vercel.app/api",
        token: token,
      );

      final result = await adService.getBrandsByLocation(latitude!, longitude!);

      setState(() {
        brandList = result;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  IconData _getIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case "men":
        return Icons.man;
      case "women":
        return Icons.woman;
      case "kids":
        return Icons.child_friendly;
      case "accessories":
        return Icons.umbrella;
      default:
        return Icons.category;
    }
  }

  Color _getColorForCategory(String category) {
    switch (category.toLowerCase()) {
      case "men":
        return Colors.cyan;
      case "women":
        return Colors.pinkAccent;
      case "kids":
        return Colors.green;
      case "accessories":
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    color: Colors.black,
                    child: Row(
                      children: [
                        const _CountryDropdown(),
                        const SizedBox(width: 8),
                        const Expanded(child: _SearchField()),
                      ],
                    ),
                  ),
                ),

                /// ✅ Categories Section
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
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index]["category"];
                        final color = _getColorForCategory(category);
                        final icon = _getIconForCategory(category);

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SubCategoryPage(
                                  mainCategory: category,
                                  subCategories: List<String>.from(
                                    _categories[index]["subcategories"],
                                  ),
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: 90,
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
                                  radius: 20,
                                  child: Icon(
                                    icon,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  category,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
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

                /// ✅ Brands Section
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text(
                      "Brands Near You",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                if (brandList.isEmpty)
                  const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          "No brands within the location",
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
                        final brandName = brandList[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BrandListingsPage(
                                  brand: brandName,
                                  latitude: latitude!,
                                  longitude: longitude!,
                                  token: token,
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
                              children: [
                                const CircleAvatar(
                                  radius: 30,
                                  backgroundColor: Colors.black,
                                  child: Icon(
                                    Icons.store,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  brandName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }, childCount: brandList.length),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 1,
                          ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class SubCategoryPage extends StatelessWidget {
  final String mainCategory;
  final List<String> subCategories;

  const SubCategoryPage({
    super.key,
    required this.mainCategory,
    required this.subCategories,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: Text(
          "$mainCategory Categories",
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView.builder(
        itemCount: subCategories.length,
        itemBuilder: (context, index) {
          final sub = subCategories[index];
          return ListTile(
            leading: const Icon(Icons.label, color: Colors.black),
            title: Text(sub, style: const TextStyle(color: Colors.black)),
            tileColor: Colors.white70,
          );
        },
      ),
    );
  }
}

class _CountryDropdown extends StatelessWidget {
  const _CountryDropdown();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white54,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: "All Fashion",
          dropdownColor: Colors.white,
          icon: const Icon(Icons.expand_more, color: Colors.black),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          items: const [
            DropdownMenuItem(value: "All Fashion", child: Text("All Fashion")),
            DropdownMenuItem(
              value: "Men's Fashion",
              child: Text("Men's Fashion"),
            ),
            DropdownMenuItem(
              value: "Women's Fashion",
              child: Text("Women's Fashion"),
            ),
            DropdownMenuItem(
              value: "Kids Fashion",
              child: Text("Kids Fashion"),
            ),
            DropdownMenuItem(value: "Accessories", child: Text("Accessories")),
          ],
          onChanged: (_) {},
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: "Search fashion...",
        hintStyle: const TextStyle(fontSize: 13, color: Colors.black54),
        prefixIcon: const Icon(Icons.search, color: Colors.black),
        filled: true,
        fillColor: Colors.white70,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
      style: const TextStyle(fontSize: 13, color: Colors.black),
    );
  }
}

class BrandListingsPage extends StatefulWidget {
  final String brand;
  final double latitude;
  final double longitude;
  final String? token;

  const BrandListingsPage({
    super.key,
    required this.brand,
    required this.latitude,
    required this.longitude,
    this.token,
  });

  @override
  State<BrandListingsPage> createState() => _BrandListingsPageState();
}

class _BrandListingsPageState extends State<BrandListingsPage> {
  bool _isLoading = false;
  String? error;
  List<Ad> listings = [];

  String? selectedCategory;
  String? selectedCondition;
  final TextEditingController minPriceController = TextEditingController();
  final TextEditingController maxPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchListings();
  }

  Future<void> _fetchListings() async {
    setState(() {
      _isLoading = true;
      error = null;
    });

    try {
      final adService = AdService(
        baseUrl: "https://stictches-africa-api-local.vercel.app/api",
        token: widget.token,
      );
      final result = await adService.getListingsByBrand(
        widget.brand,
        widget.latitude,
        widget.longitude,
      );
      setState(() {
        listings = result;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Ad> get filteredListings {
    final minPrice = int.tryParse(minPriceController.text) ?? 0;
    final maxPrice = int.tryParse(maxPriceController.text) ?? 999999999;

    return listings.where((ad) {
      if (selectedCategory != null && ad.category != selectedCategory) {
        return false;
      }
      if (selectedCondition != null && ad.title != selectedCondition) {
        return false;
      }
      if (ad.price < minPrice || ad.price > maxPrice) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Listings for ${widget.brand}")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text("Error: $error"))
              : listings.isEmpty
                  ? const Center(child: Text("No listings found"))
                  : Column(
                      children: [
                        // ---------- FILTERS ----------
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  decoration: const InputDecoration(
                                      labelText: "Category"),
                                  value: selectedCategory,
                                  items: ["Men", "Women", "Kids"]
                                      .map((c) => DropdownMenuItem(
                                          value: c, child: Text(c)))
                                      .toList(),
                                  onChanged: (val) =>
                                      setState(() => selectedCategory = val),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  decoration: const InputDecoration(
                                      labelText: "Condition"),
                                  value: selectedCondition,
                                  items: ["New", "Used"]
                                      .map((c) => DropdownMenuItem(
                                          value: c, child: Text(c)))
                                      .toList(),
                                  onChanged: (val) =>
                                      setState(() => selectedCondition = val),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: minPriceController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                      labelText: "Min Price"),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: maxPriceController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                      labelText: "Max Price"),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ---------- PRODUCT GRID ----------
                        Expanded(
                          child: GridView.builder(
                            padding: const EdgeInsets.all(10),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.7,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                            itemCount: filteredListings.length,
                            itemBuilder: (context, index) {
                              final ad = filteredListings[index];
                              return GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (ctx) =>
                                        ProductDetailPage(ad: ad),
                                  ),
                                ),
                                child: Card(
                                  elevation: 3,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: ad.images.isNotEmpty
                                            ? Image.network(
                                                ad.images.first,
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                              )
                                            : const Icon(
                                                Icons.image_not_supported,
                                                size: 80,
                                              ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          ad.title,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8.0),
                                        child: Text("₦${ad.price}"),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
    );
  }
}

// ---------------- PRODUCT DETAIL PAGE -----------------
class ProductDetailPage extends StatelessWidget {
  final Ad ad;
  const ProductDetailPage({super.key, required this.ad});

  // Call Vendor
  void _callVendor(String phone) async {
    final uri = Uri.parse("tel:$phone");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  // WhatsApp Vendor
  void _whatsappVendor(String phone, String message) async {
    final uri = Uri.parse(
        "https://wa.me/$phone?text=${Uri.encodeComponent(message)}");
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
                        label: Text(ad.title),
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
                          label: const Text("Call Vendor",
                              style: TextStyle(color: Colors.white)),
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
                          onPressed: () => _whatsappVendor(
                            ad.phone,
                            "Hello, I'm interested in your ${ad.title}",
                          ),
                          icon: const FaIcon(FontAwesomeIcons.whatsapp,
                              color: Colors.white),
                          label: const Text("WhatsApp Vendor",
                              style: TextStyle(color: Colors.white)),
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
          )
        ],
      ),
    );
  }
}