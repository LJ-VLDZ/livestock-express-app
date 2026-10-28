import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditListingScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> currentData;

  const EditListingScreen({super.key, required this.docId, required this.currentData});

  @override
  State<EditListingScreen> createState() => _EditListingScreenState();
}

class _EditListingScreenState extends State<EditListingScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _descController;

  bool _isLoading = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  // Ultra-Rich Modern Agricultural Color Suite
  final Color _deepForestGreen = const Color(0xFF0A3622);
  final Color _vibrantGreen = const Color(0xFF1B5E20);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentData['livestock_name'] ?? '');
    _priceController = TextEditingController(text: (widget.currentData['price'] ?? '').toString());
    _descController = TextEditingController(text: widget.currentData['description'] ?? '');

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
    _nameController.dispose();
    _priceController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _updateListing() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('livestock').doc(widget.docId).update({
        'livestock_name': _nameController.text.trim(),
        'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
        'description': _descController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        _showSnackBar("Listing updated successfully!");
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar("Failed to update: $e", isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
        title: const Text("Edit Listing", style: TextStyle(fontWeight: FontWeight.bold)),
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
                Text(
                  "Update Details",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _deepForestGreen),
                ),
                const SizedBox(height: 6),
                Text(
                  "Modify your livestock information below",
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),
                // Name Field
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    labelText: "Livestock Name / Breed",
                    labelStyle: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    prefixIcon: Icon(Icons.pets_rounded, color: _vibrantGreen, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.green.shade200)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.green.shade200)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: _vibrantGreen, width: 2)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty ? "Please enter a livestock name" : null,
                ),
                const SizedBox(height: 16),
                // Price Field
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    labelText: "Price (₱)",
                    labelStyle: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    prefixIcon: Icon(Icons.payments_outlined, color: _vibrantGreen, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.green.shade200)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.green.shade200)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: _vibrantGreen, width: 2)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return "Please enter a price";
                    if (double.tryParse(value.trim()) == null) return "Please enter a valid number";
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Description Field
                TextFormField(
                  controller: _descController,
                  maxLines: 4,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    labelText: "Description",
                    labelStyle: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    alignLabelWithHint: true,
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(bottom: 60),
                      child: Icon(Icons.description_outlined, color: _vibrantGreen, size: 20),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.green.shade200)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.green.shade200)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: _vibrantGreen, width: 2)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                ),
                const SizedBox(height: 32),
                // Submit Button
                SizedBox(
                  height: 54,
                  child: _isLoading
                      ? Center(child: CircularProgressIndicator(color: _vibrantGreen, strokeWidth: 3))
                      : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _vibrantGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                      shadowColor: _vibrantGreen.withValues(alpha: 0.4),
                    ),
                    onPressed: _updateListing,
                    child: const Text(
                      "Save Changes",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
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