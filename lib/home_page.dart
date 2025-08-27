import 'package:flutter/material.dart';
import 'services/category_service.dart'; // ✅ Ensure this exists
// import other necessary files if needed

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final CategoryService _categoryService = CategoryService();
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
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
                // Search Bar
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

                // Categories Title
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text(
                      "Categories",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                // Dynamic Categories
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
                                      _categories[index]["subcategories"]),
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
                                  child: Icon(icon, color: Colors.white, size: 20),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  category,
                                  style: const TextStyle(
                                      fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/* ---------------- Subcategory Page ---------------- */
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

/* ---------------- Other Widgets ---------------- */
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
      style: const TextStyle(fontSize: 13, color: Colors.black),
    );
  }
}
