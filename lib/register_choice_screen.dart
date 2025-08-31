import 'package:flutter/material.dart';

class RegisterChoiceScreen extends StatelessWidget {
  const RegisterChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // ✅ Logo
                      Image.asset(
                        "images/Stitches Africa Logo-06.png",
                        height: 80,
                      ),
                      const SizedBox(height: 30),

                      // ✅ Illustration / Hero image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          "images/register_choice.png", // 👈 add your beautiful image in assets
                          height: 260,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 40),

                      const Text(
                        "Join Stitches Africa",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Choose how you want to register and start your journey.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 40),

                      // ✅ Buyer button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, "/register");
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Sign up as Buyer",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ✅ Seller button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, "/register_vendor");
                          },
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            side: const BorderSide(color: Colors.black, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Sign up as Seller",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ✅ Sign In button at top-right
            Positioned(
              top: 10,
              right: 10,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, "/login"); // 👈 your sign in route
                },
                icon: const Icon(Icons.person, color: Colors.black),
                label: const Text(
                  "Sign In",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
