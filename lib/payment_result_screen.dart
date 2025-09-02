import 'package:flutter/material.dart';

class PaymentResultScreen extends StatelessWidget {
  const PaymentResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ✅ Logo at the top
                Align(
                  alignment: Alignment.topCenter,
                  child: Image.asset(
                        "images/Stitches Africa Logo-06.png", // ✅ your logo
                        height: 120, // adjust size if needed
                      ),
                ),
                const Spacer(),

                // ✅ Success Illustration
                Image.asset(
                  "images/payment-success.PNG", // your success illustration path
                  height: 200,
                ),

                const SizedBox(height: 30),

                // ✅ Success Message
                const Text(
                  "Payment Successful!",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                  textAlign: TextAlign.center,
                ),

                const Spacer(),

                // ✅ Button
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                        context, "/home", (r) => false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Go to Home",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
