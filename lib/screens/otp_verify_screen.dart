import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
// Import your main dashboard or home screen route here
import 'login_screen.dart';

class OtpVerifyScreen extends StatefulWidget {
  const OtpVerifyScreen({super.key});

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> with WidgetsBindingObserver {
  bool _isCheckingStatus = false;

  final Color _deepForestGreen = const Color(0xFF0A3622);
  final Color _vibrantGreen = const Color(0xFF1B5E20);

  @override
  void initState() {
    super.initState();
    // Register lifecycle observer to detect when app resumes from background
    WidgetsBinding.instance.addObserver(this);
    // Initial server check on load
    _checkServerVerificationStatus();
  }

  @override
  void dispose() {
    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Triggered whenever the app comes back to the foreground (e.g. from Gmail/Email app)
    if (state == AppLifecycleState.resumed) {
      _checkServerVerificationStatus();
    }
  }

  /// Calls the Laravel backend to check true verification status
  Future<void> _checkServerVerificationStatus() async {
    if (_isCheckingStatus) return;
    setState(() => _isCheckingStatus = true);

    try {
      final User? firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) return;

      // Get Firebase ID token to authenticate the API request against Laravel backend
      String? idToken = await firebaseUser.getIdToken();

      // Replace with your actual Laravel backend API endpoint / domain
      final url = Uri.parse("https://your-laravel-backend-domain.com/api/user/verification-status");

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken', // Or your session/sanctum token
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final bool isVerified = data['is_verified'] ?? false; // Adjust based on your backend json key

        if (isVerified && mounted) {
          // Strictly redirect to home/dashboard based on server truth, clearing navigation stack
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
          );
        }
      }
    } catch (e) {
      debugPrint("Verification status check error: $e");
    } finally {
      if (mounted) {
        setState(() => _isCheckingStatus = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF8),
      appBar: AppBar(
        title: const Text("Email Verification", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: _deepForestGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.mark_email_unread_rounded, size: 80, color: _vibrantGreen),
            const SizedBox(height: 24),
            Text(
              "Verify Your Email Address",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _deepForestGreen),
            ),
            const SizedBox(height: 12),
            Text(
              "We've sent a verification link or OTP to your email. Please check your inbox and verify your account to proceed.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.4),
            ),
            const SizedBox(height: 40),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _vibrantGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _isCheckingStatus ? null : _checkServerVerificationStatus,
                child: _isCheckingStatus
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
                    : const Text("I Have Verified — Check Status", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}