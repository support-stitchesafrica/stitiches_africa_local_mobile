import 'package:flutter/material.dart';
import 'models/ad.dart';
import 'product_cart.dart';

class BrandListingPage extends StatelessWidget {
  final String brand;
  final List<Ad> ads;

  const BrandListingPage({super.key, required this.brand, required this.ads});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(brand),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.builder(
          itemCount: ads.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.7,
          ),
          itemBuilder: (context, index) {
            final ad = ads[index];
            return ProductCard(ad: ad);
          },
        ),
      ),
    );
  }
}
