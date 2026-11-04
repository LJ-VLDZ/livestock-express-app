import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'otp_verify_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  final List<String> _barangays = [
    'Alos', 'Amandiego', 'Amangbangan', 'Balangobong', 'Balayang', 'Baleyadaan', 'Bolaney', 'Bued', 'Cabatuan', 'Cayucay',
    'Dulacac', 'Inerangan', 'Landoc', 'Linmansangan', 'Lucap', 'Maawi', 'Macatiw', 'Magsaysay', 'Mona', 'Palamis', 'Pandan',
    'Pangapisan', 'Poblacion', 'Pocal-pocal', 'Pogo', 'Polo', 'Quibuar', 'Sabangan', 'San Antonio', 'San Jose', 'San Roque',
    'San Vicente', 'Sta. Maria', 'Tanaytay', 'Tangcarang', 'Tawin-tawin', 'Telbang', 'Victoria',
  ];

  String? _selectedBarangay;
  DateTime? _birthday;
  bool _loading = false;
  bool _hidePassword = true;
  bool _hideConfirmPassword = true;
  bool _agreedToTerms = false;

  final Color _green = const Color(0xFF1B5E20);
  final Color _darkGreen = const Color(0xFF0A3622);

  int? get _age {
    if (_birthday == null) return null;
    final now = DateTime.now();
    var years = now.year - _birthday!.year;
    if (now.month < _birthday!.month ||
        (now.month == _birthday!.month && now.day < _birthday!.day)) {
      years--;
    }
    return years;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  // --- UPDATED PASSWORD VALIDATOR ---
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Please enter a password';
    if (value.length < 8) return 'Use at least 8 characters';
    if (!value.contains(RegExp(r'[A-Z]'))) return 'Add at least one uppercase letter';
    if (!value.contains(RegExp(r'[0-9]'))) return 'Add at least one number';
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Add at least one special character (e.g. @, #, !, \$)';
    }
    return null;
  }

  // Strict Philippine Mobile Number Validator (09XXXXXXXXX or 9XXXXXXXXX)
  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter your mobile number';
    }
    final cleanPhone = value.trim();
    // Matches 11 digits starting with 09 OR 10 digits starting with 9
    final phPhoneRegExp = RegExp(r'^(09\d{9}|9\d{9})$');
    if (!phPhoneRegExp.hasMatch(cleanPhone)) {
      return 'Enter valid PH number (e.g. 09123456789 or 9123456789)';
    }
    return null;
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Select your birthdate',
    );
    if (selected != null && mounted) setState(() => _birthday = selected);
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Terms & Conditions", style: TextStyle(fontWeight: FontWeight.bold, color: _darkGreen)),
        content: const SingleChildScrollView(
          child: Text(
            "Welcome to Livestock Express!\n\n"
                "1. Platform Purpose: Livestock Express serves as a digital trading and logistics marketplace connecting farmers, buyers, and livestock traders within Alaminos City and surrounding regions.\n\n"
                "2. Verified Transactions: All listings, trade offers, and transport fees must comply with local agricultural guidelines. Misrepresentation of livestock breed, health status, or pricing may result in account suspension.\n\n"
                "3. Delivery & Transport Fees: Transport fee calculations are estimates based on distance mapping from the seller's location to the delivery address within Pangasinan.\n\n"
                "4. User Responsibility: Users are solely responsible for verifying livestock conditions upon meetup or delivery. Livestock Express is not liable for private agreements made outside official app protocols.",
            style: TextStyle(fontSize: 13, height: 1.4),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close", style: TextStyle(color: _green, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _signUp() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;
    if (_birthday == null) {
      _message('Please select your birthdate.');
      return;
    }
    if (_age! < 18) {
      _message('You must be at least 18 years old to register.');
      return;
    }
    if (_selectedBarangay == null) {
      _message('Please select your barangay.');
      return;
    }
    if (!_agreedToTerms) {
      _message('Please agree to the Terms and Conditions to register.');
      return;
    }

    setState(() => _loading = true);

    try {
      final response = await http.post(
        Uri.parse('https://adminlivestockexpress.site/api/register/pending'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'name': _name.text.trim(),
          'email': _email.text.trim(),
          'phone': _phone.text.trim(),
          'password': _password.text,
          'barangay': _selectedBarangay,
          'birthday': _birthday!.toIso8601String().split('T')[0],
          'age': _age,
        }),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpVerifyScreen(
              email: _email.text.trim(),
              password: _password.text,
            ),
          ),
        );
      }else {
        final data = jsonDecode(response.body);
        _message(data['message'] ?? 'Registration failed.');
      }
    } catch (e) {
      _message('Connection error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(value), behavior: SnackBarBehavior.floating),
    );
  }

  InputDecoration _decoration(String label, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _green),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.green.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: _green, width: 2),
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
                  const Icon(Icons.pets, color: Colors.white, size: 32),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Livestock Express',
                          style: TextStyle(color: Colors.white, fontSize: 24,
                              fontWeight: FontWeight.w900)),
                      Text('Create your account',
                          style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FBF8),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      Text('Sign Up',
                          style: TextStyle(color: _darkGreen, fontSize: 24,
                              fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      const Text('Enter your details to join the marketplace.'),
                      const SizedBox(height: 22),
                      TextFormField(
                        controller: _name,
                        textCapitalization: TextCapitalization.words,
                        decoration: _decoration('Full Name', Icons.person_outline),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Enter your full name' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _decoration('Email Address', Icons.email_outlined),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Enter your email';
                          if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        maxLength: 11,
                        decoration: _decoration('Mobile Number (09... or 9...)', Icons.phone_outlined).copyWith(
                          counterText: '',
                        ),
                        validator: _validatePhone,
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: _selectedBarangay,
                        isExpanded: true,
                        decoration: _decoration('Barangay in Alaminos City',
                            Icons.location_on_outlined),
                        items: _barangays.map((b) =>
                            DropdownMenuItem(value: b, child: Text(b))).toList(),
                        onChanged: (v) => setState(() => _selectedBarangay = v),
                        validator: (v) => v == null ? 'Select your barangay' : null,
                      ),
                      const SizedBox(height: 14),
                      InkWell(
                        onTap: _pickBirthday,
                        child: InputDecorator(
                          decoration: _decoration('Birthdate',
                              Icons.calendar_month_outlined,
                              suffix: const Icon(Icons.arrow_drop_down)),
                          child: Text(_birthday == null
                              ? 'Choose your birthdate'
                              : '${_birthday!.month.toString().padLeft(2, '0')}/${_birthday!.day.toString().padLeft(2, '0')}/${_birthday!.year}'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.cake_outlined, color: _green),
                            const SizedBox(width: 10),
                            Text(_age == null ? 'Age is calculated from birthdate'
                                : 'Age: $_age years old',
                                style: TextStyle(color: _darkGreen,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _password,
                        obscureText: _hidePassword,
                        decoration: _decoration('Password (Min 8 chars, 1 uppercase, 1 number, 1 symbol)', Icons.lock_outline,
                            suffix: IconButton(
                              onPressed: () => setState(() => _hidePassword = !_hidePassword),
                              icon: Icon(_hidePassword ? Icons.visibility_off : Icons.visibility),
                            )),
                        validator: _validatePassword,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _confirmPassword,
                        obscureText: _hideConfirmPassword,
                        decoration: _decoration('Confirm Password', Icons.lock_reset,
                            suffix: IconButton(
                              onPressed: () => setState(() =>
                              _hideConfirmPassword = !_hideConfirmPassword),
                              icon: Icon(_hideConfirmPassword
                                  ? Icons.visibility_off : Icons.visibility),
                            )),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Confirm your password';
                          if (v != _password.text) return 'Passwords do not match';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Checkbox(
                            value: _agreedToTerms,
                            activeColor: _green,
                            onChanged: (val) => setState(() => _agreedToTerms = val ?? false),
                          ),
                          Expanded(
                            child: Wrap(
                              children: [
                                const Text("I agree to the ", style: TextStyle(fontSize: 13, color: Colors.black87)),
                                GestureDetector(
                                  onTap: _showTermsDialog,
                                  child: Text(
                                    "Terms and Conditions",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: _green,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _signUp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          child: _loading
                              ? const SizedBox(height: 22, width: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                              : const Text('Continue to Verification',
                              style: TextStyle(fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextButton(
                        onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                        child: Text('Already have an account? Log in',
                            style: TextStyle(color: _green)),
                      ),
                    ],
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