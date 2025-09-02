import 'dart:async';
import 'package:flutter/material.dart';

class AdvertCarousel extends StatefulWidget {
  final List<AdvertSlide> slides;
  final double height;

  const AdvertCarousel({
    Key? key,
    required this.slides,
    this.height = 160,
  }) : super(key: key);

  @override
  _AdvertCarouselState createState() => _AdvertCarouselState();
}

class _AdvertCarouselState extends State<AdvertCarousel> {
  final PageController _controller = PageController(viewportFraction: 1.0);
  Timer? _timer;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    // auto play every 4 seconds
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (widget.slides.isEmpty) return;
      _current = (_current + 1) % widget.slides.length;
      _controller.animateToPage(
        _current,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _goNext() {
    if (widget.slides.isEmpty) return;
    final next = (_current + 1) % widget.slides.length;
    _controller.animateToPage(next, duration: const Duration(milliseconds: 300), curve: Curves.ease);
  }

  @override
  Widget build(BuildContext context) {
    final height = widget.height;
    return SizedBox(
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.slides.length,
            onPageChanged: (idx) => setState(() => _current = idx),
            itemBuilder: (context, index) {
              final slide = widget.slides[index];
              return _AdvertSlideView(
                slide: slide,
                height: height,
                onNextTapped: _goNext,
              );
            },
          ),

          // indicator dots bottom-left
          Positioned(
            left: 16,
            bottom: 10,
            child: Row(
              children: List.generate(widget.slides.length, (i) {
                final active = i == _current;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 18 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active ? Colors.white : Colors.white.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class AdvertSlide {
  final String title;
  final String subtitle;
  final String label; // e.g., "Ad"
  final String imageAsset; // asset path for right-side image
  AdvertSlide({
    required this.title,
    required this.subtitle,
    required this.label,
    required this.imageAsset,
  });
}

class _AdvertSlideView extends StatelessWidget {
  final AdvertSlide slide;
  final double height;
  final VoidCallback onNextTapped;

  const _AdvertSlideView({
    Key? key,
    required this.slide,
    required this.height,
    required this.onNextTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Colors match screenshot: main red background, yellow panel on right
    final Color red = const Color(0xFFc51b1b); // tweak to match exactly
    final Color yellow = const Color(0xFFFFD400);

    return Container(
      color: Colors.black, // outer black strip like screenshot edges
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      child: Center(
        child: Container(
          // inner red banner with rounded corners
          height: height - 16,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: red,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              // Left: text block
              Expanded(
                flex: 6,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Big title
                      Text(
                        slide.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Subtitle
                      Text(
                        slide.subtitle,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // small label "Ad" with info circle if desired
                      Row(
                        children: [
                          Text(
                            slide.label,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white12,
                              border: Border.all(color: Colors.white30),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.info_outline,
                                color: Colors.white70,
                                size: 14,
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),

              // Right: yellow curved panel with image and -50 badge + arrow
              Expanded(
                flex: 4,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Yellow panel with curved left edge
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        height: double.infinity,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: yellow,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(48),
                            bottomLeft: Radius.circular(48),
                            topRight: Radius.circular(4),
                            bottomRight: Radius.circular(4),
                          ),
                        ),
                        padding: const EdgeInsets.only(left: 12, right: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Image (use asset)
                            Flexible(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(
                                  slide.imageAsset,
                                  fit: BoxFit.cover,
                                  height: height * 0.85,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // -50 badge (positioned near bottom left of yellow panel)
                    Positioned(
                      left: MediaQuery.of(context).size.width * 0.58 - 24, // approximate
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            )
                          ],
                        ),
                        child: Text(
                          "-50%",
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),

                    // circular next arrow (bottom-right on yellow)
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: GestureDetector(
                        onTap: onNextTapped,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              )
                            ],
                          ),
                          child: const Icon(
                            Icons.chevron_right,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
