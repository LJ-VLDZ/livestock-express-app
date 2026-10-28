import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/format_helper.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  // Ultra-Rich Modern Agricultural Color Suite
  final Color _deepForestGreen = const Color(0xFF0A3622);
  final Color _vibrantGreen = const Color(0xFF1B5E20);
  final Color _softGreenTint = const Color(0xFFE8F5E9);

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
    super.dispose();
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
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FBF8),
        body: Center(
          child: Text("Please log in to view your cart.", style: TextStyle(fontWeight: FontWeight.w500, color: _deepForestGreen)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF8),
      appBar: AppBar(
        title: const Text("My Cart & Inquiries", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: _deepForestGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('cart')
              .orderBy('addedAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: _vibrantGreen));
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: _softGreenTint,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.shopping_cart_outlined, size: 48, color: _vibrantGreen),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      "Your cart is empty",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _deepForestGreen),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Explore the marketplace and save livestock listings here",
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              );
            }

            final cartDocs = snapshot.data!.docs;

            return ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: cartDocs.length,
              itemBuilder: (context, index) {
                final doc = cartDocs[index];
                final data = doc.data() as Map<String, dynamic>;

                final String docId = doc.id;
                final String name = data['livestock_name'] ?? 'Livestock';
                final rawPrice = data['price'];
                final double price = rawPrice is int ? rawPrice.toDouble() : (rawPrice ?? 0.0);
                final String imageUrl = data['imageUrl'] ?? '';
                final String barangay = data['barangay'] ?? 'Poblacion';

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.shade100, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Row(
                      children: [
                        // Item Image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: imageUrl.isNotEmpty
                              ? Image.network(
                            imageUrl,
                            width: 75,
                            height: 75,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholderIcon(),
                          )
                              : _placeholderIcon(),
                        ),
                        const SizedBox(width: 14),
                        // Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _deepForestGreen),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text("Barangay $barangay", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                              const SizedBox(height: 8),
                              Text(
                                "₱${FormatHelper.formatCurrency(price)}",
                                style: TextStyle(fontWeight: FontWeight.w900, color: _vibrantGreen, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        // Actions (Checkout or Delete)
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade600, size: 22),
                              onPressed: () async {
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(user.uid)
                                    .collection('cart')
                                    .doc(docId)
                                    .delete();
                                _showSnackBar("Item removed from cart.");
                              },
                            ),
                            const SizedBox(height: 4),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _vibrantGreen,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 0,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CheckoutScreen(
                                      listingData: data,
                                      listingId: data['listingId'] ?? docId,
                                    ),
                                  ),
                                );
                              },
                              child: const Text("Buy", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _placeholderIcon() {
    return Container(
      width: 75,
      height: 75,
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(Icons.pets_rounded, color: _vibrantGreen.withValues(alpha: 0.5)),
    );
  }
}