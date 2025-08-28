// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stitches_africa_local/utils/prefs.dart';

// ✅ Correct import for pay_with_paystack
import 'package:pay_with_paystack/pay_with_paystack.dart';

import 'controllers/auth_controller.dart';
import 'fashion_page.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'sell_ad.dart';
import 'splash_screen.dart';

// ✅ Add your Paystack public key here
const String paystackPublicKey = "pk_test_37eba43300c473e8c80690177c32daf9302f82e6";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Prefs.init(); // IMPORTANT: init once before runApp

  final initialRoute = (Prefs.token != null && Prefs.token!.isNotEmpty)
      ? '/home'
      : '/splash';

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthController>(
          create: (_) => AuthController(),
        ),
      ],
      child: StitchesAfricaApp(
        initialRoute: initialRoute,
      ), // ✅ MaterialApp is BELOW providers
    ),
  );
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
