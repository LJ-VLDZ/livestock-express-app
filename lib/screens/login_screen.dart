import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _captchaController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  // --- CAPTCHA STATE VARIABLES ---
  String _captchaCode = '';
  bool _isCaptchaValid = false;
  // -------------------------------

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final Color _vibrantGreen = const Color(0xFF1B5E20);
  final Color _deepForestGreen = const Color(0xFF0A3622);
  final Color _cardBackground = const Color(0xFFF8FBF8);

  @override
  void initState() {
    super.initState();
    _generateCaptcha();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _identifierController.dispose();
    _passwordController.dispose();
    _captchaController.dispose();
    super.dispose();
  }

  // --- CAPTCHA GENERATOR METHOD ---
  void _generateCaptcha() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Excludes visually ambiguous chars (0, O, I, 1)
    final rnd = Random();
    final code = String.fromCharCodes(
      Iterable.generate(4, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
    setState(() {
      _captchaCode = code;
      _captchaController.clear();
      _isCaptchaValid = false;
    });
  }

  // --- CAPTCHA VALIDATION METHOD ---
  void _validateCaptcha(String value) {
    setState(() {
      _isCaptchaValid = value.trim().toUpperCase() == _captchaCode;
    });
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isCaptchaValid) {
      _showErrorSnackBar('Please complete the correct CAPTCHA verification.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final String input = _identifierController.text.trim();
      String emailToAuth = input;

      if (!input.contains('@')) {
        String cleanPhone = input.replaceAll(RegExp(r'[\s-]'), '');

        if (cleanPhone.startsWith('+63')) {
          cleanPhone = cleanPhone.substring(3);
        } else if (cleanPhone.startsWith('63')) {
          cleanPhone = cleanPhone.substring(2);
        } else if (cleanPhone.startsWith('0')) {
          cleanPhone = cleanPhone.substring(1);
        }

        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('phone', isEqualTo: cleanPhone)
            .limit(1)
            .get();

        if (querySnapshot.docs.isEmpty) {
          _showErrorSnackBar('No account found with this mobile number.');
          setState(() => _isLoading = false);
          _generateCaptcha(); // Reset captcha on failure
          return;
        }

        final userData = querySnapshot.docs.first.data();
        emailToAuth = (userData['email'] ?? '').toString().trim();

        if (emailToAuth.isEmpty) {
          _showErrorSnackBar('This account has no registered email address.');
          setState(() => _isLoading = false);
          _generateCaptcha();
          return;
        }
      }

      final String finalEmail = emailToAuth.toLowerCase().trim();
      final String finalPassword = _passwordController.text.trim();

      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: finalEmail,
        password: finalPassword,
      );

      final user = credential.user;

      if (user == null) {
        _showErrorSnackBar('Unable to retrieve your account. Please try again.');
        setState(() => _isLoading = false);
        _generateCaptcha();
        return;
      }

      // --- EMAIL VERIFICATION GUARD ---
      await user.reload();
      final refreshedUser = FirebaseAuth.instance.currentUser;

      if (refreshedUser != null && !refreshedUser.emailVerified) {
        await FirebaseAuth.instance.signOut();
        _showErrorSnackBar('Please verify your email address via the link sent to your inbox before logging in.');
        setState(() => _isLoading = false);
        _generateCaptcha();
        return;
      }
      // -------------------------------

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_email', user.email ?? '');

      // --- RECORD LOGIN ACTIVITY LOG ---
      try {
        final userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        final userData = userSnapshot.data() ?? {};
        final firstName = (userData['firstName'] ?? '').toString();
        final lastName = (userData['lastName'] ?? '').toString();

        final fullName = ('$firstName $lastName').trim().isNotEmpty
            ? ('$firstName $lastName').trim()
            : (userData['name'] ?? userData['fullName'] ?? 'Registered User').toString();

        await FirebaseFirestore.instance.collection('activity_logs').add({
          'user_id': user.uid,
          'user_email': user.email ?? '',
          'user_name': fullName,
          'action': 'User logged in',
          'details': 'User successfully logged in to Livestock Express.',
          'actorType': 'user',
          'timestamp': FieldValue.serverTimestamp(),
        });
      } catch (logError) {
        debugPrint('Unable to save login activity to Firestore: $logError');
      }
      // -------------------------------

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
            (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Authentication failed. Please verify your credentials.';

      if (e.code == 'user-not-found' || e.code == 'invalid-email') {
        errorMessage = 'The email address or mobile number is incorrect or does not exist.';
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        errorMessage = 'The password you entered is incorrect.';
      } else if (e.code == 'user-disabled') {
        errorMessage = 'This account has been disabled by administrators.';
      }

      _showErrorSnackBar(errorMessage);
      _generateCaptcha(); // Reset CAPTCHA on error
    } on FirebaseException catch (e) {
      debugPrint('Firebase login error: ${e.code} - ${e.message}');
      _showErrorSnackBar('A Firebase error occurred. Please check your connection and try again.');
      _generateCaptcha();
    } catch (e) {
      debugPrint('Unexpected login error: $e');
      _showErrorSnackBar('An unexpected error occurred. Please try again.');
      _generateCaptcha();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _deepForestGreen,
      body: SafeArea(
        bottom: false,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'ALAMINOS CITY VET NETWORK',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 11,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: const Icon(
                            Icons.pets,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Livestock Express',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Secure digital agricultural marketplace portal',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
                    decoration: BoxDecoration(
                      color: _cardBackground,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(36),
                        topRight: Radius.circular(36),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 25,
                          offset: const Offset(0, -8),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Welcome Back',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: _deepForestGreen,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Sign in to continue trading and monitoring',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: _identifierController,
                              keyboardType: TextInputType.text,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Email Address or Mobile Number',
                                labelStyle: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                                prefixIcon: Icon(
                                  Icons.person_outline_rounded,
                                  color: _vibrantGreen,
                                  size: 20,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: BorderSide(
                                    color: Colors.green.shade200,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: BorderSide(
                                    color: Colors.green.shade200,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: BorderSide(
                                    color: _vibrantGreen,
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                              ),
                              validator: (value) =>
                              value == null || value.trim().isEmpty
                                  ? 'Please enter your email or mobile number'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                labelStyle: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                                prefixIcon: Icon(
                                  Icons.lock_outline_rounded,
                                  color: _vibrantGreen,
                                  size: 20,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: 20,
                                    color: _vibrantGreen,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: BorderSide(
                                    color: Colors.green.shade200,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: BorderSide(
                                    color: Colors.green.shade200,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: BorderSide(
                                    color: _vibrantGreen,
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                              ),
                              validator: (value) =>
                              value == null || value.isEmpty
                                  ? 'Please enter your password'
                                  : null,
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                ),
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/reset-password',
                                  );
                                },
                                child: Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    color: _vibrantGreen,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // --- CAPTCHA UI WIDGET SECTION ---
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: Colors.green.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Security Verification',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: _deepForestGreen,
                                        ),
                                      ),
                                      InkWell(
                                        onTap: _generateCaptcha,
                                        child: Row(
                                          children: [
                                            Icon(Icons.refresh_rounded, size: 14, color: _vibrantGreen),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Get New Code',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: _vibrantGreen,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      // CAPTCHA Code Display Box
                                      Expanded(
                                        flex: 2,
                                        child: Container(
                                          height: 48,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Colors.green.shade300),
                                          ),
                                          child: Text(
                                            _captchaCode,
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 6.0,
                                              color: _vibrantGreen,
                                              decoration: TextDecoration.lineThrough,
                                              decorationColor: Colors.green.shade200,
                                              decorationThickness: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // CAPTCHA Input Field
                                      Expanded(
                                        flex: 3,
                                        child: SizedBox(
                                          height: 48,
                                          child: TextFormField(
                                            controller: _captchaController,
                                            onChanged: _validateCaptcha,
                                            textCapitalization: TextCapitalization.characters,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 2.0,
                                            ),
                                            decoration: InputDecoration(
                                              hintText: 'Enter code',
                                              hintStyle: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.normal,
                                                letterSpacing: 0,
                                                color: Colors.grey.shade400,
                                              ),
                                              suffixIcon: _isCaptchaValid
                                                  ? const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20)
                                                  : null,
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                borderSide: BorderSide(color: Colors.green.shade200),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                borderSide: BorderSide(color: Colors.green.shade200),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                borderSide: BorderSide(color: _vibrantGreen, width: 2),
                                              ),
                                              filled: true,
                                              fillColor: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // ------------------------------------

                            const SizedBox(height: 24),
                            SizedBox(
                              height: 56,
                              child: _isLoading
                                  ? Center(
                                child: CircularProgressIndicator(
                                  color: _vibrantGreen,
                                  strokeWidth: 3,
                                ),
                              )
                                  : ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _vibrantGreen,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: Colors.grey.shade300,
                                  disabledForegroundColor: Colors.grey.shade600,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  elevation: _isCaptchaValid ? 6 : 0,
                                  shadowColor: _vibrantGreen.withValues(alpha: 0.4),
                                ),
                                // Button is disabled (null) if CAPTCHA is invalid
                                onPressed: _isCaptchaValid ? _handleLogin : null,
                                child: const Text(
                                  'Log In',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Don't have an account? ",
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.pushReplacementNamed(
                                      context,
                                      '/signup',
                                    );
                                  },
                                  child: Text(
                                    'Sign Up',
                                    style: TextStyle(
                                      color: _vibrantGreen,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}