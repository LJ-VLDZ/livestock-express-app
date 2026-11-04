import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'login_screen.dart';

class OtpVerifyScreen extends StatefulWidget {
  const OtpVerifyScreen({super.key});

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen>
    with WidgetsBindingObserver {

  bool _isCheckingStatus = false;
  bool _hasShownSuccess = false;

  final Color _deepForestGreen = const Color(0xFF0A3622);
  final Color _vibrantGreen = const Color(0xFF1B5E20);

  static const String verificationUrl =
      'https://adminlivestockexpress.site/api/user/verification-status';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    // Automatically check verification when screen opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVerificationStatus();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Detect when the user returns to the application.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      _checkVerificationStatus();
    }
  }

  // MAIN VERIFICATION CHECK
  Future<void> _checkVerificationStatus({
    bool showMessage = false,
  }) async {

    if (_isCheckingStatus || _hasShownSuccess || !mounted) {
      return;
    }

    setState(() {
      _isCheckingStatus = true;
    });

    bool isVerified = false;

    try {
      // STEP 1: Check Firebase Authentication first.
      User? firebaseUser = FirebaseAuth.instance.currentUser;

      if (firebaseUser == null) {
        if (showMessage) {
          _showSnackBar(
            'No active user session found. Please log in again.',
          );
        }
        return;
      }

      try {
        // IMPORTANT: Reload the Firebase user.
        // This retrieves the latest email verification status.
        await firebaseUser.reload();

        // Get the refreshed Firebase user.
        firebaseUser = FirebaseAuth.instance.currentUser;

        if (firebaseUser != null) {
          debugPrint(
            'Firebase email: ${firebaseUser.email}',
          );

          debugPrint(
            'Firebase email verified: ${firebaseUser.emailVerified}',
          );

          isVerified = firebaseUser.emailVerified;
        }
      } catch (firebaseError) {
        debugPrint(
          'Firebase verification refresh error: $firebaseError',
        );
      }

      // STEP 2: Check Laravel only if Firebase is not verified.
      // This supports systems that also maintain a verification
      // status in the Laravel database.
      if (!isVerified) {
        isVerified = await _checkLaravelVerificationStatus();
      }

      // STEP 3: If either trusted source confirms verification,
      // show the congratulations dialog.
      if (isVerified) {
        if (!mounted || _hasShownSuccess) return;

        _hasShownSuccess = true;

        await _showSuccessDialog();
      } else {
        debugPrint('Email is still not verified.');

        if (showMessage && mounted) {
          _showSnackBar(
            'Email not yet verified. Please check your inbox.',
          );
        }
      }

    } catch (e) {
      debugPrint('Verification check error: $e');

      if (showMessage && mounted) {
        _showSnackBar(
          'Unable to check verification. Please try again.',
        );
      }

    } finally {
      if (mounted) {
        setState(() {
          _isCheckingStatus = false;
        });
      }
    }
  }

  // LARAVEL VERIFICATION CHECK
  Future<bool> _checkLaravelVerificationStatus() async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;

      if (firebaseUser == null) {
        return false;
      }

      // Get a fresh Firebase authentication token.
      final String? idToken = await firebaseUser.getIdToken(true);

      if (idToken == null || idToken.isEmpty) {
        debugPrint('Unable to retrieve Firebase ID token.');
        return false;
      }

      final response = await http.get(
        Uri.parse(verificationUrl),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      ).timeout(const Duration(seconds: 15));

      debugPrint(
        'Laravel verification response: ${response.statusCode}',
      );

      debugPrint(
        'Laravel response body: ${response.body}',
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded is Map<String, dynamic>) {
          // Supports both direct and nested Laravel responses.
          final dynamic verificationValue =
              decoded['is_verified'] ??
                  (decoded['data'] is Map
                      ? decoded['data']['is_verified']
                      : null);

          if (verificationValue == true ||
              verificationValue == 1 ||
              verificationValue == '1' ||
              verificationValue == 'true') {
            return true;
          }
        }
      }

      return false;

    } catch (e) {
      debugPrint('Laravel verification API error: $e');
      return false;
    }
  }

  // SUCCESS DIALOG
  Future<void> _showSuccessDialog() async {
    if (!mounted) return;

    final bool? shouldContinue = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),

          icon: const Icon(
            Icons.verified_rounded,
            color: Colors.green,
            size: 65,
          ),

          title: const Text(
            'Congratulations!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),

          content: const Text(
            'Your email address has been successfully verified. '
                'You can now log in to your Livestock Express account.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
            ),
          ),

          actionsAlignment: MainAxisAlignment.center,

          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _vibrantGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),

                onPressed: () {
                  Navigator.of(dialogContext).pop(true);
                },

                child: const Text(
                  'Continue to Login',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldContinue == true && mounted) {
      // Sign out the verified account before returning to login.
      // The user can authenticate again using their credentials.
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
            (route) => false,
      );
    }
  }

  // SNACKBAR
  void _showSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF8),

      appBar: AppBar(
        title: const Text(
          'Email Verification',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: _deepForestGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,

            children: [

              Icon(
                Icons.mark_email_unread_rounded,
                size: 85,
                color: _vibrantGreen,
              ),

              const SizedBox(height: 25),

              Text(
                'Verify Your Email Address',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  color: _deepForestGreen,
                ),
              ),

              const SizedBox(height: 15),

              Text(
                'We have sent a verification link to your email address. '
                    'Please open your inbox, click the verification link, '
                    'and return to this application.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 35),

              SizedBox(
                height: 52,

                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _vibrantGreen,
                    foregroundColor: Colors.white,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),

                  onPressed: _isCheckingStatus
                      ? null
                      : () {
                    _checkVerificationStatus(
                      showMessage: true,
                    );
                  },

                  child: _isCheckingStatus
                      ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )

                      : const Text(
                    'I Have Verified — Check Status',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'The application will automatically check your '
                    'verification status when you return.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}