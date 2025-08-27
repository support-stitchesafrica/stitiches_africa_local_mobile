import 'package:flutter/material.dart';

class FeaturedAdsPage extends StatelessWidget {
  const FeaturedAdsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> featuredAds = [
      {
        "image": "images/product1.png",
        "title": "Luxury Leather Bag",
        "price": "\$120",
        "rating": 4.5,
        "verified": true,
      },
      {
        "image": "images/product2.png",
        "title": "Designer Sneakers",
        "price": "\$80",
        "rating": 4.2,
        "verified": true,
      },
      {
        "image": "images/product3.png",
        "title": "Handmade Jewelry",
        "price": "\$50",
        "rating": 4.8,
        "verified": false,
      },
      {
        "image": "images/product4.png",
        "title": "African Print Dress",
        "price": "\$95",
        "rating": 4.7,
        "verified": true,
      },
      {
        "image": "images/product12.png",
        "title": "Men’s Luxury Watch",
        "price": "\$210",
        "rating": 4.9,
        "verified": true,
      },
      {
        "image": "images/product6.png",
        "title": "Stylish Sunglasses",
        "price": "\$35",
        "rating": 4.3,
        "verified": false,
      },
      {
        "image": "images/product7.png",
        "title": "Elegant Handbag",
        "price": "\$75",
        "rating": 4.6,
        "verified": true,
      },
      {
        "image": "images/product18.png",
        "title": "Casual Sneakers",
        "price": "\$60",
        "rating": 4.4,
        "verified": true,
      },
      {
        "image": "images/product9.png",
        "title": "Classic Leather Shoes",
        "price": "\$150",
        "rating": 4.5,
        "verified": true,
      },
      {
        "image": "images/product10.png",
        "title": "Premium Headphones",
        "price": "\$199",
        "rating": 4.7,
        "verified": false,
      },
      {
        "image": "images/product11.png",
        "title": "Trendy Backpack",
        "price": "\$65",
        "rating": 4.3,
        "verified": true,
      },
      {
        "image": "images/product12.png",
        "title": "Fitness Smartwatch",
        "price": "\$145",
        "rating": 4.8,
        "verified": true,
      },
      {
        "image": "images/product13.png",
        "title": "Vintage Sunglasses",
        "price": "\$55",
        "rating": 4.1,
        "verified": false,
      },
      {
        "image": "images/product14.png",
        "title": "Designer Scarf",
        "price": "\$40",
        "rating": 4.6,
        "verified": true,
      },
      {
        "image": "images/product15.png",
        "title": "Luxury Wallet",
        "price": "\$110",
        "rating": 4.4,
        "verified": true,
      },
      {
        "image": "images/product16.png",
        "title": "Casual Jacket",
        "price": "\$85",
        "rating": 4.5,
        "verified": false,
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white, // ✅ White background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          "Featured Ads",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.builder(
          itemCount: featuredAds.length,
          physics: const BouncingScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.7,
          ),
          itemBuilder: (context, index) {
            final ad = featuredAds[index];
            return _FeaturedAdCard(
              image: ad["image"] as String,
              title: ad["title"] as String,
              price: ad["price"] as String,
              rating: ad["rating"] as double,
              verified: ad["verified"] as bool,
            );
          },
        ),
      ),
    );
  }
}

/* ----------------- Featured Ad Card ----------------- */
class _FeaturedAdCard extends StatelessWidget {
  final String image;
  final String title;
  final String price;
  final double rating;
  final bool verified;

  const _FeaturedAdCard({
    required this.image,
    required this.title,
    required this.price,
    required this.rating,
    required this.verified,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 3, // ✅ modern shadow
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, // ✅ white card background
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: Image.asset(
                    image,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // fallback if asset not found
                      return Container(
                        height: 140,
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Icon(Icons.broken_image,
                              color: Colors.black54, size: 40),
                        ),
                      );
                    },
                  ),
                ),
                if (verified)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.green,
                      child: const Icon(
                        Icons.verified,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    price,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildStars(rating),
                      const SizedBox(width: 4),
                      Text(
                        rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStars(double rating) {
    int fullStars = rating.floor();
    bool hasHalfStar = (rating - fullStars) >= 0.5;

    return Row(
      children: [
        for (int i = 0; i < fullStars; i++)
          const Icon(Icons.star, size: 16, color: Colors.amber),
        if (hasHalfStar)
          const Icon(Icons.star_half, size: 16, color: Colors.amber),
        for (int i = 0; i < (5 - fullStars - (hasHalfStar ? 1 : 0)); i++)
          const Icon(Icons.star_border, size: 16, color: Colors.amber),
      ],
    );
  }
}
