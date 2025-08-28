import 'package:flutter/material.dart';
import 'package:stitches_africa_local/profile_page.dart';
import 'package:stitches_africa_local/register_screen.dart';
import 'package:stitches_africa_local/featured_screen.dart';
import 'package:stitches_africa_local/product_page.dart';
import 'package:stitches_africa_local/utils/prefs.dart';
import 'home_page.dart'; // Import HomePage from its own file

class FashionPage extends StatefulWidget {
  const FashionPage({super.key});

  @override
  State<FashionPage> createState() => _FashionPageState();
}

class _FashionPageState extends State<FashionPage> {
  final t = Prefs.token;
  String get profileOrSignIn {
    if (t == null || t!.isEmpty) {
      return "Sign in";
    } else {
      return "Profile";
    }
  }

  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const FeaturedAdsPage(),
    const ProductPage(),
    ProfilePage(), // Placeholder for Sign In bottom sheet
  ];

  void _onNavTap(int index) {
    // if (index == 3) {
    //   _showSignInSheet();
    //   return;
    // }
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Image.asset("images/Stitches Africa Logo-06.png", height: 42),
                const SizedBox(width: 3),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Colors.black, Colors.black87, Colors.black54],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: const Text(
                    "Local",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, "/sell");
                  },
                  child: const Text(
                    "SELL",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        ),
        body: _pages[_currentIndex],
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: BottomNavigationBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: Colors.green,
            unselectedItemColor: Colors.grey,
            currentIndex: _currentIndex,
            onTap: _onNavTap,
            type: BottomNavigationBarType.fixed,
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: "Home",
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.star),
                label: "Featured Ads",
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.shopping_bag),
                label: "Products",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: profileOrSignIn,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
