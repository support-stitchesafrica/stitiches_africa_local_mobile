import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stitches_africa_local/profile_page.dart';
import 'package:stitches_africa_local/login_screen.dart'; // <-- import your Login screen
import 'package:stitches_africa_local/featured_screen.dart';
import 'package:stitches_africa_local/utils/prefs.dart';
import 'package:stitches_africa_local/models/user_model.dart';
import 'home_page.dart'; // Import HomePage from its own file

class FashionPage extends StatefulWidget {
  const FashionPage({super.key});

  @override
  State<FashionPage> createState() => _FashionPageState();
}

class _FashionPageState extends State<FashionPage> {
  int _currentIndex = 0;
  User? _user;
  bool _isLoadingUser = true;

  String get profileOrSignIn {
    final t = Prefs.token;
    if (t == null || t.isEmpty) {
      return "Sign in";
    } else {
      return "Profile";
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh user data when dependencies change (e.g., returning from other screens)
    if (_user == null && !_isLoadingUser) {
      _loadUserData();
    }
  }

  Future<void> _loadUserData() async {
    try {
      final userData = Prefs.userData;
      if (userData != null) {
        setState(() {
          _user = User.fromJson(userData);
          _isLoadingUser = false;
        });
      } else {
        setState(() {
          _isLoadingUser = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingUser = false;
      });
      debugPrint("Error loading user data: $e");
    }
  }

  // Method to refresh user data (can be called when returning from profile updates)
  Future<void> _refreshUserData() async {
    await _loadUserData();
  }

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });

    // Refresh user data when switching to profile tab to ensure SELL button visibility is up to date
    if (index == 2 && _user != null) {
      _refreshUserData();
    }
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Exit App'),
          content: const Text('Are you sure you want to exit the app?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Exit the app
                SystemNavigator.pop();
              },
              child: const Text('Exit'),
            ),
          ],
        );
      },
    );
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
          : ProfilePage(), // <-- show Profile when signed in
    ];

    return PopScope(
      canPop: false, // Prevent normal back navigation
      onPopInvoked: (didPop) {
        // Show exit confirmation dialog
        _showExitDialog(context);
      },
      child: SafeArea(
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
                  // Only show SELL button for VENDOR users
                  if (_user?.userType == "VENDOR")
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
                        Navigator.pushNamed(context, "/sell");
                      },
                      child: const Text(
                        "SELL",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
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
      ),
    );
  }
}
