import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  bool _isSubmitting = false;
  String _selectedCategory = "Account Verification";

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  // Ultra-Rich Modern Agricultural Color Suite
  final Color _deepForestGreen = const Color(0xFF0A3622);
  final Color _vibrantGreen = const Color(0xFF1B5E20);
  final Color _softGreenTint = const Color(0xFFE8F5E9);

  final List<String> _categories = [
    "Account Verification",
    "Livestock Listing Issue",
    "Delivery & Map Tracking",
    "Technical Bug / Error",
    "Other Inquiry"
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitSupportTicket() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance.collection('support_tickets').add({
        'userId': user.uid,
        'userEmail': user.email ?? 'No email',
        'category': _selectedCategory,
        'subject': _subjectController.text.trim(),
        'message': _messageController.text.trim(),
        'status': 'Open',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text("Support Ticket Sent", style: TextStyle(fontWeight: FontWeight.bold, color: _deepForestGreen)),
            content: const Text(
              "Your message has been forwarded to the Alaminos City Livestock Administration. We will reach out to you shortly.",
              style: TextStyle(height: 1.4),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _vibrantGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text("OK", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar("Failed to submit ticket: $e", isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w500)),
        backgroundColor: isError ? Colors.red.shade700 : _vibrantGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF8),
      appBar: AppBar(
        title: const Text("Help & Support", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: _deepForestGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _softGreenTint,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.support_agent_rounded, size: 36, color: _vibrantGreen),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          "Need assistance with verification, listings, or deliveries? Send a direct message to our support team.",
                          style: TextStyle(fontSize: 13, color: _deepForestGreen, fontWeight: FontWeight.w600, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text("Issue Category", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _deepForestGreen)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.green.shade200)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.green.shade200)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: _vibrantGreen, width: 2)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat, style: const TextStyle(fontSize: 14)))).toList(),
                  onChanged: (val) => setState(() => _selectedCategory = val!),
                ),
                const SizedBox(height: 18),
                Text("Subject", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _deepForestGreen)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _subjectController,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: "Brief summary of your concern",
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.green.shade200)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.green.shade200)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: _vibrantGreen, width: 2)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? "Please enter a subject" : null,
                ),
                const SizedBox(height: 18),
                Text("Message Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _deepForestGreen)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _messageController,
                  maxLines: 5,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: "Describe your issue or question in detail...",
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.green.shade200)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.green.shade200)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: _vibrantGreen, width: 2)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? "Please provide message details" : null,
                ),
                const SizedBox(height: 36),
                SizedBox(
                  height: 54,
                  child: _isSubmitting
                      ? Center(child: CircularProgressIndicator(color: _vibrantGreen, strokeWidth: 3))
                      : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _vibrantGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                      shadowColor: _vibrantGreen.withValues(alpha: 0.4),
                    ),
                    onPressed: _submitSupportTicket,
                    child: const Text("Submit Support Ticket", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}