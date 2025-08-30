import 'package:flutter/material.dart';
import 'package:stitches_africa_local/shop_listing_page.dart';

import 'models/ad.dart';

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
        title: Text("$category Stores"),
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
                        builder: (_) =>
                            ShopListingsPage(storeName: store, ads: ads),
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
                          child: Icon(
                            Icons.store,
                            color: Colors.white,
                            size: 28,
                          ),
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
