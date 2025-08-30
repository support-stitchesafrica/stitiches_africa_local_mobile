import '../models/ad.dart';

/// Ensures ads are unique by [title] + [images] combination.
List<Ad> uniqueAdsByTitleAndImages(List<Ad> ads) {
  final seen = <String, bool>{};
  final uniqueAds = <Ad>[];

  for (final ad in ads) {
    final title = ad.title.trim();
    final imagesKey = (ad.images.isNotEmpty) ? ad.images.join(",") : "";
    final key = "${title}_$imagesKey";

    if (!seen.containsKey(key)) {
      seen[key] = true;
      uniqueAds.add(ad);
    }
  }

  return uniqueAds;
}
