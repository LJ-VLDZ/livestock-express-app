
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'login_screen.dart';

class OtpVerifyScreen extends StatefulWidget {
  final String email;
  final String password;

  const OtpVerifyScreen({
    super.key,
    required this.email,
    required this.password,
  });

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen>
    with WidgetsBindingObserver {

  bool _isCheckingStatus = false;
  bool _hasShownSuccess = false;

  final Color _deepForestGreen = const Color(0xFF0A3622);
  final Color _vibrantGreen = const Color(0xFF1B5E20);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVerificationStatus();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      _checkVerificationStatus();
    }
  }

  Future<void> _checkVerificationStatus({
    bool showMessage = false,
  }) async {

    if (_isCheckingStatus || _hasShownSuccess || !mounted) {
      return;
    }

    setState(() => _isCheckingStatus = true);

    try {
      FirebaseAuth auth = FirebaseAuth.instance;

      User? user = auth.currentUser;

      // STEP 1: Authenticate if no Firebase session exists.
      // Laravel creates the Firebase account only after
      // the user clicks the verification link.

      if (user == null) {
        try {
          final credential =
          await auth.signInWithEmailAndPassword(
            email: widget.email,
            password: widget.password,
          );

          user = credential.user;
        } on FirebaseAuthException catch (e) {

          debugPrint('Firebase sign-in: ${e.code}');

          if (e.code == 'user-not-found') {
            _showMessage(
              'Please verify your email first. '
                  'The verification link may not have been completed.',
            );
          } else if (e.code == 'wrong-password' ||
              e.code == 'invalid-credential') {
            _showMessage(
              'Unable to authenticate your account. '
                  'Please check your email first.',
            );
          } else {
            _showMessage(
              'Unable to connect to your account. Please try again.',
            );
          }

          return;
        }
      }

      if (user == null) {
        _showMessage('Unable to retrieve your Firebase account.');
        return;
      }

      // STEP 2: Refresh Firebase account information.
      await user.reload();

      user = auth.currentUser;

      if (user == null) {
        _showMessage('Unable to refresh your account.');
        return;
      }

      debugPrint('Email: ${user.email}');
      debugPrint('Email verified: ${user.emailVerified}');

      // STEP 3: Check the actual Firebase email verification status.
      if (user.emailVerified) {

        if (!mounted || _hasShownSuccess) return;

        _hasShownSuccess = true;

        await _showSuccessDialog();

      } else {

        if (showMessage) {
          _showMessage(
            'Your email is not yet verified. '
                'Please click the verification link in your inbox.',
          );
        }
      }

    } catch (e) {

      debugPrint('Verification error: $e');

      if (showMessage && mounted) {
        _showMessage(
          'Unable to check verification. Please try again.',
        );
      }

    } finally {

      if (mounted) {
        setState(() => _isCheckingStatus = false);
      }
    }
  }

  Future<void> _showSuccessDialog() async {

    if (!mounted) return;

    final result = await showDialog<bool>(
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
                  padding: const EdgeInsets.symmetric(vertical: 14),
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

    if (result == true && mounted) {

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

  void _showMessage(String message) {

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
          style: TextStyle(fontWeight: FontWeight.bold),
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
                'We have sent a verification link to ${widget.email}. '
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
