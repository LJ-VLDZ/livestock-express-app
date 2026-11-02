import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/format_helper.dart';
import 'edit_listing_screen.dart';
import 'seller_orders_screen.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  final Color _deepForestGreen = const Color(0xFF062314);
  final Color _vibrantGreen = const Color(0xFF134E27);
  final Color _surfaceBg = const Color(0xFFF1F6F2);

  String _selectedTab = "Active"; // "Active", "Pending", "Sold", or "Rejected"

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeOutExpo);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _deleteListing(BuildContext context, String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Delete Listing', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.red.shade700)),
        content: const Text('Are you sure you want to remove this livestock listing? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('livestock').doc(docId).delete();
        if (context.mounted) {
          _showSnackBar('Listing deleted successfully.');
        }
      } catch (e) {
        if (context.mounted) {
          _showSnackBar('Failed to delete: $e', isError: true);
        }
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: isError ? Colors.red.shade700 : _vibrantGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      return Scaffold(
        backgroundColor: _surfaceBg,
        body: Center(
          child: Text("Please log in to view your listings.", style: TextStyle(fontWeight: FontWeight.w700, color: _deepForestGreen)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _surfaceBg,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Custom Futuristic Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "My Activity",
                      style: TextStyle(
                        color: _deepForestGreen,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Manage inventory and monitor incoming orders",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Futuristic Seller Sales Shortcut Banner
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SellerOrdersScreen()),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_deepForestGreen, _vibrantGreen],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: _vibrantGreen.withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.storefront_rounded, color: Color(0xFF00FF88), size: 24),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "View Incoming Sales & Orders",
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15),
                              ),
                              SizedBox(height: 2),
                              Text(
                                "Check buyer orders, inspect requests, & dispatch",
                                style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // 4-Way Filter Tabs: Active, Pending, Sold, Rejected
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.green.shade100, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      _buildTabButton("Active"),
                      _buildTabButton("Pending"),
                      _buildTabButton("Sold"),
                      _buildTabButton("Rejected"),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Listings Stream with Correct Filtering
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('livestock')
                      .where('seller_id', isEqualTo: currentUserId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator(color: _vibrantGreen, strokeWidth: 3));
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: _deepForestGreen.withOpacity(0.06), blurRadius: 20)],
                              ),
                              child: Icon(Icons.inventory_2_outlined, size: 48, color: _vibrantGreen),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              "No listings posted yet",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _deepForestGreen),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Tap the (+) button on the dashboard to add livestock",
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      );
                    }

                    final docs = snapshot.data!.docs.where((doc) {
                      final item = doc.data() as Map<String, dynamic>;
                      final status = (item['status'] ?? 'available').toString().trim().toLowerCase();
                      final isAvailable = item['isAvailable'];

                      bool isRejected = status == 'rejected' || status == 'declined';
                      bool isPending = !isRejected && (status == 'pending' || status == 'unapproved' || status == 'under review');
                      bool isOrdered = status == 'ordered';
                      bool isSold = !isRejected && (status == 'sold' || status == 'completed' || (isAvailable == false && !isPending && !isOrdered));

                      if (_selectedTab == "Rejected") {
                        return isRejected;
                      } else if (_selectedTab == "Pending") {
                        return isPending;
                      } else if (_selectedTab == "Sold") {
                        return isSold || isOrdered;
                      } else {
                        return !isRejected && !isPending && !isSold && !isOrdered;
                      }
                    }).toList();

                    if (docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _selectedTab == "Active"
                                  ? Icons.check_circle_outline_rounded
                                  : _selectedTab == "Pending"
                                  ? Icons.hourglass_empty_rounded
                                  : _selectedTab == "Sold"
                                  ? Icons.history_rounded
                                  : Icons.cancel_outlined,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              "No $_selectedTab listings found",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final item = doc.data() as Map<String, dynamic>;

                        final String status = item['status'] ?? 'Available';
                        final String? rejectionReason = item['rejectionReason'];
                        final rawPrice = item['price'];
                        final double price = rawPrice is int ? rawPrice.toDouble() : (rawPrice ?? 0.0);

                        Color statusColor = _vibrantGreen;
                        Color statusBg = const Color(0xFFE8F5E9);
                        if (status.toLowerCase() == 'sold' || status.toLowerCase() == 'completed' || status.toLowerCase() == 'ordered') {
                          statusColor = Colors.green;
                          statusBg = Colors.greenAccent;
                        } else if (status.toLowerCase() == 'pending' || status.toLowerCase() == 'unapproved') {
                          statusColor = Colors.orange.shade800;
                          statusBg = Colors.orange.shade50;
                        } else if (status.toLowerCase() == 'rejected' || status.toLowerCase() == 'declined') {
                          statusColor = Colors.red.shade700;
                          statusBg = Colors.red.shade50;
                        }

                        // Determine whether editing is permitted (disabled for rejected items)
                        final bool isRejectedStatus = status.toLowerCase() == 'rejected' || status.toLowerCase() == 'declined';
                        final bool isSoldStatus = status.toLowerCase() == 'sold' || status.toLowerCase() == 'completed' || status.toLowerCase() == 'ordered';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.green.shade100.withOpacity(0.6), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: _deepForestGreen.withOpacity(0.04),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Row: Status badge & Price Badge
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: statusBg,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      status.toUpperCase(),
                                      style: TextStyle(
                                        color: statusColor,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 11,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F5E9),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      "₱${FormatHelper.formatCurrency(price)}",
                                      style: TextStyle(
                                        color: _vibrantGreen,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              // Livestock Name
                              Text(
                                item['livestock_name'] ?? "Unnamed Listing",
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 17,
                                  color: _deepForestGreen,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Category: ${item['category'] ?? 'Livestock'} • Brgy. ${item['barangay'] ?? 'Alaminos'}",
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w600),
                              ),

                              // Rejection Reason Banner if rejected
                              if (isRejectedStatus && rejectionReason != null && rejectionReason.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.red.shade200, width: 1),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Reason for Rejection:",
                                        style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.bold, fontSize: 11),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        rejectionReason,
                                        style: TextStyle(color: Colors.red.shade900, fontSize: 12, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 14),
                              Divider(height: 1, color: Colors.grey.shade100, thickness: 1.5),
                              const SizedBox(height: 10),
                              // Bottom Action Row (Edit hidden if sold or rejected)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (!isSoldStatus && !isRejectedStatus) ...[
                                    TextButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => EditListingScreen(docId: doc.id, currentData: item),
                                          ),
                                        );
                                      },
                                      icon: Icon(Icons.edit_outlined, color: _vibrantGreen, size: 18),
                                      label: Text(
                                        "Edit",
                                        style: TextStyle(color: _vibrantGreen, fontWeight: FontWeight.w900),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  TextButton.icon(
                                    onPressed: () => _deleteListing(context, doc.id),
                                    icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade600, size: 18),
                                    label: Text(
                                      "Delete",
                                      style: TextStyle(color: Colors.red.shade600, fontWeight: FontWeight.w900),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper builder for the 4 filter tabs
  Widget _buildTabButton(String title) {
    final bool isSelected = _selectedTab == title;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = title),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? _deepForestGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade600,
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
            ),
          ),
        ),
      ),
    );
  }
}