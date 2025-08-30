import 'package:flutter/material.dart';
import 'package:stitches_africa_local/models/ad.dart';
import 'package:stitches_africa_local/utils/ad_utils.dart'; // ✅ import helper
import 'product_cart.dart';

class ShopListingsPage extends StatelessWidget {
  final String storeName;
  final List<Ad> ads;

  const ShopListingsPage({
    super.key,
    required this.storeName,
    required this.ads,
  });

  @override
  Widget build(BuildContext context) {
    final uniqueAds = uniqueAdsByTitleAndImages(ads); // ✅ use helper
    return Scaffold(
      appBar: AppBar(title: Text("$storeName Listings")),
      body: uniqueAds.isEmpty
          ? const Center(child: Text("No listings found"))
          : GridView.builder(
              padding: const EdgeInsets.all(10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: uniqueAds.length,
              itemBuilder: (context, index) {
                final ad = uniqueAds[index];
                return ProductCard(ad: ad);
              },
            ),
    );
  }
}
