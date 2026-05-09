import 'package:flutter/material.dart';

import '../l10n/strings.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/smakolist-logo.png', width: 72, height: 72),
            const SizedBox(height: 20),
            Text(
              S.appTitle,
              style: const TextStyle(
                fontFamily: 'FixelDisplay',
                fontWeight: FontWeight.w700,
                fontSize: 42,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              S.appTagline,
              style: const TextStyle(
                fontFamily: 'FixelDisplay',
                fontWeight: FontWeight.w600,
                fontSize: 20,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
