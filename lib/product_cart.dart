import 'package:flutter/material.dart';

import 'models/ad.dart';
import 'product_detail.dart';

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
