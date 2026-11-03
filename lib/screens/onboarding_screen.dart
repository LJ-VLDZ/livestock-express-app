import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  Future<void> _completeOnboarding(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_onboarding', false);

    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color deepForestGreen = const Color(0xFF0A3622);
    final Color vibrantGreen = const Color(0xFF1B5E20);
    final Color softGreenTint = const Color(0xFFE8F5E9);

    return IntroductionScreen(
      globalBackgroundColor: const Color(0xFFF8FBF8),
      pages: [
        PageViewModel(
          title: "Welcome to Livestock Express",
          body: "Your official Alaminos City digital marketplace for secure, transparent, and biosecure livestock trading.",
          image: Center(
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: softGreenTint,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.pets_rounded, size: 80, color: vibrantGreen),
            ),
          ),
          decoration: _pageDescriptionStyle(deepForestGreen, vibrantGreen),
        ),
        PageViewModel(
          title: "Browse & Negotiate Securely",
          body: "Explore verified livestock listings across Pangasinan, chat directly with traders, and make custom price offers.",
          image: Center(
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: softGreenTint,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.handshake_rounded, size: 80, color: vibrantGreen),
            ),
          ),
          decoration: _pageDescriptionStyle(deepForestGreen, vibrantGreen),
        ),
        PageViewModel(
          title: "Live GPS Delivery Tracking",
          body: "Monitor shipments moving across Alaminos City with real-time road tracking and municipal inspection verification.",
          image: Center(
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: softGreenTint,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.local_shipping_rounded, size: 80, color: vibrantGreen),
            ),
          ),
          decoration: _pageDescriptionStyle(deepForestGreen, vibrantGreen),
        ),
      ],
      onDone: () => _completeOnboarding(context),
      onSkip: () => _completeOnboarding(context),
      showSkipButton: true,
      skip: Text("Skip", style: TextStyle(fontWeight: FontWeight.bold, color: vibrantGreen)),
      next: Icon(Icons.arrow_forward_rounded, color: vibrantGreen),
      done: Text("Get Started", style: TextStyle(fontWeight: FontWeight.bold, color: vibrantGreen)),
      dotsDecorator: DotsDecorator(
        size: const Size.square(10.0),
        activeSize: const Size(22.0, 10.0),
        activeColor: vibrantGreen,
        color: Colors.green.shade200,
        spacing: const EdgeInsets.symmetric(horizontal: 4.0),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25.0),
        ),
      ),
    );
  }

  PageDecoration _pageDescriptionStyle(Color titleColor, Color bodyColor) {
    return PageDecoration(
      titleTextStyle: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: titleColor),
      bodyTextStyle: TextStyle(fontSize: 15, color: Colors.grey.shade700, height: 1.5),
      imagePadding: const EdgeInsets.all(24),
      pageColor: const Color(0xFFF8FBF8),
    );
  }
}