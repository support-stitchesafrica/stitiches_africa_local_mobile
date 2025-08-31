import 'package:flutter/material.dart';
import 'package:stitches_africa_local/models/ad.dart';
import 'package:stitches_africa_local/utils/ad_utils.dart';
import 'product_cart.dart';

class ShopListingsPage extends StatelessWidget {
  final String storeName;
  final List<Ad> ads;
  final String? storeLogo;
  final IconData? fallbackIcon;

  const ShopListingsPage({
    super.key,
    required this.storeName,
    required this.ads,
    this.storeLogo,
    this.fallbackIcon,
  });

  @override
  Widget build(BuildContext context) {
    final uniqueAds = uniqueAdsByTitleAndImages(ads);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (storeLogo != null && storeLogo!.isNotEmpty)
              CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(storeLogo!),
                backgroundColor: Colors.transparent,
              )
            else if (fallbackIcon != null)
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.black,
                child: Icon(
                  fallbackIcon,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "$storeName Listings",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: uniqueAds.isEmpty
          ? const Center(child: Text("No listings found nearby"))
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
