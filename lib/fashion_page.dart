import 'package:flutter/material.dart';
import 'package:stitches_africa_local/profile_page.dart';
import 'package:stitches_africa_local/login_screen.dart'; // <-- import your Login screen
import 'package:stitches_africa_local/featured_screen.dart';
import 'package:stitches_africa_local/utils/prefs.dart';
import 'home_page.dart'; // Import HomePage from its own file

class FashionPage extends StatefulWidget {
  const FashionPage({super.key});

  @override
  State<FashionPage> createState() => _FashionPageState();
}

class _FashionPageState extends State<FashionPage> {
  int _currentIndex = 0;

  String get profileOrSignIn {
    final t = Prefs.token;
    if (t == null || t.isEmpty) {
      return "Sign in";
    } else {
      return "Profile";
    }
  }

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final token = Prefs.token;

    // build pages dynamically based on token
    final List<Widget> pages = [
      const HomePage(),
      const FeaturedAdsPage(),
      (token == null || token.isEmpty)
          ? const LoginScreen() // <-- show Login when not signed in
          : ProfilePage(),       // <-- show Profile when signed in
    ];

    return SafeArea(
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Image.asset("images/Stitches Africa Logo-06.png", height: 80),
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
        body: pages[_currentIndex],
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
                icon: Image(
                  image: AssetImage("images/Stitches Africa Logo-06.png"),
                  height: 42,
                ),
                label: "",
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.favorite),
                label: "Favorites",
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.person),
                label: profileOrSignIn,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
