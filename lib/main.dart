import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stitches_africa_local/register_screen.dart';
import 'package:stitches_africa_local/sell_ad.dart';

import 'fashion_page.dart';
import 'featured_screen.dart';
import 'login_screen.dart';
import 'product_page.dart';
import 'splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Required for async in main
  // ✅ Preload SharedPreferences and determine initial route before runApp
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('token');
  String initialRoute = (token != null && token.isNotEmpty) ? '/home' : '/splash';

  runApp(StitchesAfricaApp(initialRoute: initialRoute));
}

class StitchesAfricaApp extends StatelessWidget {
  final String initialRoute;

  const StitchesAfricaApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Stitches Africa',
      themeMode: ThemeMode.system,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        primaryColor: Colors.grey.shade200,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.grey.shade500,
          primary: Colors.black,
          secondary: Colors.orange,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.white,
        primaryColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.white,
          primary: Colors.white,
          secondary: Colors.orange,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      initialRoute: initialRoute,
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/home': (context) => const FashionPage(),
        '/register': (context) => const RegisterScreen(),
        '/sell': (context) => const SellFormScreen(),
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}




/* ----------- Home Content ----------- */

class _CategoryTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _CategoryTile({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white60,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, size: 30, color: color),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

/* ---------------- Helpers ---------------- */
class _Cat {
  final IconData icon;
  final String title;
  final Color color;
  _Cat(this.icon, this.title, this.color);
}
