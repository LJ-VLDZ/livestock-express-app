import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';

// Services
import 'package:livestock_app/services/push_notification_service.dart';

// Screens
import 'package:livestock_app/screens/dashboard_screen.dart';
import 'package:livestock_app/screens/login_screen.dart';
import 'package:livestock_app/screens/sign_up_screen.dart';
import 'package:livestock_app/screens/reset_password_screen.dart';
import 'package:livestock_app/screens/splash_screen.dart';
import 'package:livestock_app/screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await PushNotificationService.initialize();

  // Check if it's the first time opening the app
  final prefs = await SharedPreferences.getInstance();
  final bool showOnboarding = prefs.getBool('show_onboarding') ?? true;

  runApp(LivestockApp(showOnboarding: showOnboarding));
}

class LivestockApp extends StatelessWidget {
  final bool showOnboarding;
  const LivestockApp({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Livestock Express',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      // If onboarding is needed, start at /onboarding, otherwise go straight to the dashboard (/home)
      initialRoute: showOnboarding ? '/onboarding' : '/home',
      routes: {
        '/onboarding': (context) => const OnboardingScreen(),
        '/': (context) => const SplashScreen(),
        '/home': (context) => const DashboardScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/reset-password': (context) => const ResetPasswordScreen(),
      },
    );
  }
}