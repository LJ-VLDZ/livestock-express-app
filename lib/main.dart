import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

// Services
import 'package:livestock_app/services/push_notification_service.dart';

// Screens
import 'package:livestock_app/screens/dashboard_screen.dart';
import 'package:livestock_app/screens/login_screen.dart';
import 'package:livestock_app/screens/sign_up_screen.dart';
import 'package:livestock_app/screens/reset_password_screen.dart';
import 'package:livestock_app/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize FCM Push Notifications for Phase 3
  await PushNotificationService.initialize();

  runApp(const LivestockApp());
}

class LivestockApp extends StatelessWidget {
  const LivestockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Livestock Express',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      // Start at the Splash Screen route '/'
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/home': (context) => const DashboardScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/reset-password': (context) => const ResetPasswordScreen(),
      },
    );
  }
}