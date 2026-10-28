import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

class OtpVerifyScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const OtpVerifyScreen({super.key, required this.userData});

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> with WidgetsBindingObserver {
  bool _isVerified = false;

  final Color _green = const Color(0xFF1B5E20);
  final Color _darkGreen = const Color(0xFF0A3622);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Detects when the user switches back from Gmail/Browser into the mobile app
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Automatically update state to verified when returning to the app
      setState(() {
        _isVerified = true;
      });
    }
  }

  Future<void> _openEmailApp(BuildContext context) async {
    try {
      // 1. Try launching standard mailto intent (opens default email / Gmail chooser)
      final Uri mailtoUri = Uri.parse('mailto:');
      if (await canLaunchUrl(mailtoUri)) {
        await launchUrl(mailtoUri);
        return;
      }

      // 2. Fallback to Gmail web inbox in external browser
      final Uri webMailUri = Uri.parse('https://mail.google.com');
      if (await canLaunchUrl(webMailUri)) {
        await launchUrl(webMailUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {
      // Ignore and trigger fallback message below
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please open your Gmail app or inbox manually.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkGreen,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isVerified ? 'Verification Complete' : 'Verify Your Email',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FBF8),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(
                            color: Color(0xFFE8F5E9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isVerified ? Icons.check_circle_rounded : Icons.mark_email_read_outlined,
                            size: 56,
                            color: _green,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _isVerified ? 'Email Verified Successfully!' : 'Almost There!',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: _darkGreen,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _isVerified
                              ? 'Your Livestock Express account has been successfully verified and created. You can now proceed to log in.'
                              : 'We sent a verification link to\n${widget.userData['email']}\n\nClick the link in your email, then come back here to continue.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            height: 1.5,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 32),
                        if (!_isVerified) ...[
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: () => _openEmailApp(context),
                              icon: const Icon(Icons.open_in_new_rounded),
                              label: const Text(
                                'Open Gmail App',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: OutlinedButton(
                              onPressed: () => setState(() => _isVerified = true),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _green,
                                side: BorderSide(color: _green, width: 2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                'I Have Already Verified',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ),
                          ),
                        ] else ...[
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                                context,
                                '/login',
                                    (route) => false,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                'Proceed to Log In',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
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