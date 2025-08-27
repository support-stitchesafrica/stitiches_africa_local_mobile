import 'package:flutter/material.dart';

class FeaturedAdsGrid extends StatelessWidget {
  final List<Map<String, dynamic>> featuredAds;

  const FeaturedAdsGrid({super.key, required this.featuredAds});

  @override
  Widget build(BuildContext context) {
    // ✅ Responsive column count based on screen width
    final double screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = 2; // default for phones
    if (screenWidth > 600) crossAxisCount = 3; // tablets
    if (screenWidth > 900) crossAxisCount = 4; // large screens

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ Title Section
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            "Featured Ads",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // ✅ Grid Section
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(), // parent scroll
          padding: const EdgeInsets.all(8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.72,
          ),
          itemCount: featuredAds.length,
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
      ],
    );
  }
}

/* -------- Featured Ad Card -------- */
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
      elevation: 2,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(10),
                    ),
                    child: Image.asset(
                      image,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
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
                      top: 6,
                      right: 6,
                      child: CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.green,
                        child: const Icon(Icons.verified,
                            color: Colors.white, size: 16),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    price,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildStars(rating),
                      const SizedBox(width: 4),
                      Text(
                        rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 11,
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
          const Icon(Icons.star, size: 12, color: Colors.amber),
        if (hasHalfStar)
          const Icon(Icons.star_half, size: 12, color: Colors.amber),
        for (int i = 0;
            i < (5 - fullStars - (hasHalfStar ? 1 : 0));
            i++)
          const Icon(Icons.star_border, size: 12, color: Colors.amber),
      ],
    );
  }
}
