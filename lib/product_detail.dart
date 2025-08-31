import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'models/ad.dart';
import 'services/ad_feedback_service.dart';
import 'services/favourie_service.dart';
import 'services/user_service.dart';
import 'utils/prefs.dart';

class ProductDetailPage extends StatefulWidget {
  final Ad ad;
  const ProductDetailPage({super.key, required this.ad});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late final PageController _pageController;
  int _currentImage = 0;

  double _myRating = 0; 
  List<_Comment> _comments = []; 
  final TextEditingController _commentCtrl = TextEditingController();
  bool _saving = false;

  // Favorite functionality
  bool _isLoadingFavorite = false;
  late final AdService _adService;

  late final AdFeedbackService _feedbackService;
  late final UserService _userService;

  String? _token;
  String? _userId;
  String? _userFullName;

  @override
  void initState() {
    super.initState();
    print("Product ID: ${widget.ad.id}");
    _pageController = PageController();
    _feedbackService = AdFeedbackService(baseUrl: "https://stictches-africa-api-local.vercel.app/api"); // Initialize services
    _userService = UserService();
    _adService = AdService(
      baseUrl: "https://stictches-africa-api-local.vercel.app/api",
      token: Prefs.token ?? "",
    );
    _loadStoredFeedback();
    _loadUserAndFeedback();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  // ---------------- User & Feedback ----------------
  Future<void> _loadUserAndFeedback() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString("token");

    if (_token != null) {
      final user = await _userService.getProfile();
      if (user != null) {
        _userId = user.id;
        _userFullName = user.fullName;
      }
    }

    _loadFeedback();
  }

  Future<void> _loadFeedback() async {
    if (_token == null) return;

    try {
      final data = await _feedbackService.getFeedback(widget.ad.id);
      final ratings = data['ratings'] as List<dynamic>? ?? [];
      final comments = data['comments'] as List<dynamic>? ?? [];

      final myRatingData = ratings.firstWhere(
        (r) => r['userId'] == _userId,
        orElse: () => null,
      );

      setState(() {
        _myRating = myRatingData != null ? (myRatingData['rating'] as num).toDouble() : _myRating;
        _comments = comments.map((c) => _Comment(
          author: c['fullName'] ?? c['user']['fullName'] ?? 'Anonymous',
          message: c['content'] ?? '',
          createdAt: DateTime.parse(c['createdAt']),
        )).toList();
      });
    } catch (e) {
      print("Failed to load feedback: $e");
    }
  }

  Future<void> _saveRating(double value) async {
    if (_token == null || _userId == null) return;
    setState(() => _myRating = value);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_ratingKey, value);

    try {
      await _feedbackService.addRating(adId: widget.ad.id, rating: value.toInt());
    } catch (e) {
      _toast(context, "Failed to save rating: $e");
    }
  }

  Future<void> _addComment(String text) async {
    if (text.trim().isEmpty || _token == null || _userId == null || _userFullName == null) return;

    setState(() => _saving = true);

    try {
      await _feedbackService.addComment(adId: widget.ad.id, content: text.trim());

      final newComment = _Comment(
        author: _userFullName!,
        message: text.trim(),
        createdAt: DateTime.now(),
      );

      setState(() {
        _comments.insert(0, newComment);
        _commentCtrl.clear();
      });

      // Save locally
      final prefs = await SharedPreferences.getInstance();
      prefs.setString(_commentsKey, jsonEncode(_comments.map((c) => c.toJson()).toList()));
    } catch (e) {
      _toast(context, "Failed to post comment: $e");
    } finally {
      setState(() => _saving = false);
    }
  }

  // ---------------- Favorite functionality ----------------
  Future<void> _addToFavorites() async {
    if (Prefs.token == null) {
      _toast(context, "Please login to add favorites");
      return;
    }

    setState(() => _isLoadingFavorite = true);

    try {
      await _adService.addFavouriteAd(widget.ad.id);
      _toast(context, "Added to favorites!");
    } catch (e) {
      _toast(context, "Error: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() => _isLoadingFavorite = false);
      }
    }
  }

  // ---------------- Ratings & Comments (local persistence) ----------------
  String get _ratingKey => "ad_rating_${widget.ad.id}";
  String get _commentsKey => "ad_comments_${widget.ad.id}";

  Future<void> _loadStoredFeedback() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _myRating = prefs.getDouble(_ratingKey) ?? 0;
      final raw = prefs.getString(_commentsKey);
      if (raw != null && raw.isNotEmpty) {
        final list = (jsonDecode(raw) as List)
            .map((e) => _Comment.fromJson(e as Map<String, dynamic>))
            .toList();
        _comments = list;
      }
    });
  }

  // ---------------- Toast ----------------
  void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // ---------------- Call / WhatsApp ----------------
  Future<void> _callVendor(String phone) async {
    final uri = Uri.parse("tel:$phone");
    if (await canLaunchUrl(uri)) await launchUrl(uri);
    else _toast(context, "Could not start a call.");
  }

  Future<void> _whatsappVendor(String phone, String message) async {
    final uri = Uri.parse("https://wa.me/$phone?text=${Uri.encodeComponent(message)}");
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
    else _toast(context, "Could not open WhatsApp.");
  }

  // ---------------- UI Helpers ----------------
  String _formatMoney(double n) => n % 1 == 0 ? n.toStringAsFixed(0) : n.toStringAsFixed(2);
  String _formatDate(DateTime d) {
    final local = d.toLocal();
    final two = (int v) => v.toString().padLeft(2, '0');
    return "${local.year}-${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)}";
  }

  void _openFullscreenGallery(int initialIndex) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _FullScreenGallery(images: widget.ad.images, initialPage: initialIndex, heroTag: widget.ad.id),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final ad = widget.ad;
    final hasManyImages = ad.images.length > 1;

    return Scaffold(
      floatingActionButton: Prefs.token != null
          ? FloatingActionButton(
              onPressed: _isLoadingFavorite ? null : _addToFavorites,
              backgroundColor: Colors.black,
              child: _isLoadingFavorite
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.favorite_border, color: Colors.white),
            )
          : null,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 420,
            pinned: true,
            backgroundColor: Colors.white,
            iconTheme: const IconThemeData(color: Colors.black),
            title: Text(
              ad.title,
              style: const TextStyle(color: Colors.black),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              IconButton(
                onPressed: _isLoadingFavorite ? null : _addToFavorites,
                icon: _isLoadingFavorite
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.favorite_border, color: Colors.black),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: ad.id,
                child: ad.images.isNotEmpty
                    ? Stack(
                        children: [
                          PageView.builder(
                            controller: _pageController,
                            itemCount: ad.images.length,
                            onPageChanged: (i) => setState(() => _currentImage = i),
                            itemBuilder: (_, i) => GestureDetector(
                              onTap: () => _openFullscreenGallery(i),
                              child: InteractiveViewer(
                                minScale: 1,
                                maxScale: 4,
                                child: Image.network(ad.images[i], fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                              ),
                            ),
                          ),
                          if (hasManyImages)
                            Positioned(
                              left: 16,
                              right: 16,
                              bottom: 16,
                              child: _DotsIndicator(count: ad.images.length, index: _currentImage),
                            ),
                        ],
                      )
                    : const Center(child: Icon(Icons.image_not_supported, size: 100, color: Colors.black26)),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ad.title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Chip(
                          label: Text(ad.categoryName),
                          backgroundColor: Colors.teal.shade50,
                          side: BorderSide.none,
                        ),
                        const SizedBox(width: 8),
                        Chip(
                          label: Text(ad.brand),
                          backgroundColor: Colors.orange.shade50,
                          side: BorderSide.none,
                        ),
                        if ((ad.promoType ?? '').isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Chip(
                            label: Text(ad.promoType!),
                            backgroundColor: Colors.purple.shade50,
                            side: BorderSide.none,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 11),
                  Text(
                    "₦${_formatMoney(ad.price)}",
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),

                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      if ((ad.gender ?? '').isNotEmpty) _MetaPill(icon: Icons.wc, text: ad.gender!),
                      if ((ad.address ?? '').isNotEmpty) _MetaPill(icon: Icons.location_on, text: ad.address!),
                      if (ad.latitude != null && ad.longitude != null)
                        _MetaPill(icon: Icons.place, text: "(${ad.latitude!.toStringAsFixed(4)}, ${ad.longitude!.toStringAsFixed(4)})"),
                      _MetaPill(icon: Icons.calendar_today, text: _formatDate(ad.createdAt)),
                      if (ad.user?.name != null && ad.user!.name.isNotEmpty)
                        _MetaPill(icon: Icons.person, text: "Seller: ${ad.user!.name}"),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const Text("Description", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(ad.description, style: const TextStyle(fontSize: 15, height: 1.5)),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text(
                        "Your Rating",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8), // small spacing you control
                      _StarBar(
                        value: _myRating,
                        onChanged: (v) => _saveRating(v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const Text("Contact Vendor", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _callVendor(ad.phone),
                          icon: const Icon(Icons.call, color: Colors.white),
                          label: const Text("Call Vendor", style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _whatsappVendor(ad.phone, "Hello, I'm interested in your ${ad.title}"),
                          icon: const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.white),
                          label: const Text("WhatsApp Vendor", style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const Text("Comments", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentCtrl,
                          minLines: 1,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: "Write a comment…",
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _saving ? null : () => _addComment(_commentCtrl.text),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _saving
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                            : const Text("Post", style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_comments.isEmpty)
                    const Text("No comments yet. Be the first!", style: TextStyle(color: Colors.black54))
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _comments.length,
                      separatorBuilder: (_, __) => const Divider(height: 20),
                      itemBuilder: (_, i) {
                        final c = _comments[i];
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(radius: 18, child: Text((c.author.isNotEmpty ? c.author[0] : "?").toUpperCase())),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(child: Text(c.author, style: const TextStyle(fontWeight: FontWeight.w600))),
                                      Text(_formatDate(c.createdAt), style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(c.message),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- Supporting Widgets (MetaPill, DotsIndicator, StarBar, FullScreenGallery, Comment) ----------------
class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaPill({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 16, color: Colors.black87), const SizedBox(width: 6), Text(text)]),
    );
  }
}

class _DotsIndicator extends StatelessWidget {
  final int count;
  final int index;
  const _DotsIndicator({required this.count, required this.index});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
        (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: i == index ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(color: Colors.white.withOpacity(i == index ? 0.95 : 0.6), borderRadius: BorderRadius.circular(999)),
        ),
      ),
    );
  }
}

class _StarBar extends StatelessWidget {
  final double value; // 0..5
  final ValueChanged<double> onChanged;
  const _StarBar({required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        final idx = i + 1;
        final filled = value >= idx;
        return IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () => onChanged(idx.toDouble()),
          icon: Icon(filled ? Icons.star : Icons.star_border, color: Colors.amber, size: 26),
        );
      }),
    );
  }
}

class _FullScreenGallery extends StatefulWidget {
  final List<String> images;
  final int initialPage;
  final Object heroTag;
  const _FullScreenGallery({required this.images, required this.initialPage, required this.heroTag});
  @override
  State<_FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<_FullScreenGallery> {
  late final PageController _controller;
  int _page = 0;
  @override
  void initState() {
    super.initState();
    _page = widget.initialPage;
    _controller = PageController(initialPage: widget.initialPage);
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final imgs = widget.images;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text("${_page + 1}/${imgs.length}", style: const TextStyle(color: Colors.white)),
      ),
      body: Hero(
        tag: widget.heroTag,
        child: PageView.builder(
          controller: _controller,
          itemCount: imgs.length,
          onPageChanged: (i) => setState(() => _page = i),
          itemBuilder: (_, i) => Center(child: InteractiveViewer(minScale: 1, maxScale: 5, child: Image.network(imgs[i], fit: BoxFit.contain))),
        ),
      ),
    );
  }
}

// ---------------- Local Comment Model ----------------
class _Comment {
  final String author;
  final String message;
  final DateTime createdAt;
  _Comment({required this.author, required this.message, required this.createdAt});
  factory _Comment.fromJson(Map<String, dynamic> json) => _Comment(
    author: json['author'] ?? 'Anonymous',
    message: json['message'] ?? '',
    createdAt: DateTime.parse(json['createdAt']),
  );
  Map<String, dynamic> toJson() => {"author": author, "message": message, "createdAt": createdAt.toIso8601String()};
}
