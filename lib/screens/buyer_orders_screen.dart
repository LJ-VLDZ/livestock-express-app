import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'order_tracking_screen.dart';
import 'seller_orders_screen.dart'; // Ensure you have this file created

class BuyerOrdersScreen extends StatefulWidget {
  final String initialFilter;
  const BuyerOrdersScreen({super.key, this.initialFilter = 'All'});

  @override
  State<BuyerOrdersScreen> createState() => _BuyerOrdersScreenState();
}

class _BuyerOrdersScreenState extends State<BuyerOrdersScreen> with SingleTickerProviderStateMixin {
  final Color _deepForestGreen = const Color(0xFF0A3622);
  final Color _vibrantGreen = const Color(0xFF1B5E20);
  final Color _softGreenTint = const Color(0xFFE8F5E9);

  late String _selectedFilter;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter;
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _confirmReceived(BuildContext context, String orderId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Confirm Livestock Received", style: TextStyle(fontWeight: FontWeight.bold, color: _deepForestGreen)),
        content: const Text("Are you sure you have received your livestock in good condition? This will complete the order and enable rating."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel", style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _vibrantGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Confirm Received", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
          'orderStatus': 'Completed',
        });
        if (context.mounted) {
          _showSnackBar("Order marked as Completed! You can now rate the seller.");
        }
      } catch (e) {
        if (context.mounted) {
          _showSnackBar("Error updating order: $e", isError: true);
        }
      }
    }
  }

  void _showRatingDialog(BuildContext context, String sellerId, String orderId) {
    int rating = 5;
    final TextEditingController commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("Rate Seller & Transaction", style: TextStyle(fontWeight: FontWeight.bold, color: _deepForestGreen)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("How was your experience with this livestock trade?", style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < rating ? Icons.star_rounded : Icons.star_border_rounded,
                      color: Colors.amber,
                      size: 32,
                    ),
                    onPressed: () => setDialogState(() => rating = index + 1),
                  );
                }),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: commentController,
                maxLines: 3,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: "Write a review about the livestock condition...",
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.green.shade200)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.green.shade200)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: _vibrantGreen, width: 2)),
                  filled: true,
                  fillColor: const Color(0xFFF8FBF8),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _vibrantGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
                    'rating': rating,
                    'review': commentController.text.trim(),
                    'isRated': true,
                  });

                  final sellerDocRef = FirebaseFirestore.instance.collection('users').doc(sellerId);
                  await FirebaseFirestore.instance.runTransaction((transaction) async {
                    final sellerSnapshot = await transaction.get(sellerDocRef);
                    if (sellerSnapshot.exists) {
                      final data = sellerSnapshot.data() as Map<String, dynamic>;
                      double currentRating = (data['rating'] ?? 5.0).toDouble();
                      int ratingCount = (data['ratingCount'] ?? 0).toInt();

                      double newRating = ((currentRating * ratingCount) + rating) / (ratingCount + 1);
                      transaction.update(sellerDocRef, {
                        'rating': newRating,
                        'ratingCount': ratingCount + 1,
                      });
                    }
                  });

                  if (context.mounted) {
                    _showSnackBar("Rating submitted successfully! Thank you.");
                  }
                } catch (e) {
                  if (context.mounted) {
                    _showSnackBar("Failed to submit rating: $e", isError: true);
                  }
                }
              },
              child: const Text("Submit Rating", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  bool _matchesFilter(String status) {
    if (_selectedFilter == 'All') return true;
    final lowerStatus = status.toLowerCase();

    if (_selectedFilter == 'To Pay') return lowerStatus.contains('pending') && !lowerStatus.contains('verification');
    if (_selectedFilter == 'To Ship') return lowerStatus.contains('inspection') || lowerStatus.contains('verification') || lowerStatus.contains('processing');
    if (_selectedFilter == 'To Receive') return lowerStatus.contains('dispatched') || lowerStatus.contains('delivered') || lowerStatus.contains('shipped');
    if (_selectedFilter == 'To Rate') return lowerStatus.contains('completed');
    if (_selectedFilter == 'Cancelled') return lowerStatus.contains('cancelled');
    return true;
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
    final User? buyer = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F4),
      appBar: AppBar(
        title: const Text("My Purchases", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
        backgroundColor: _deepForestGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          // Automatically displays the seller sold-items button ONLY if the user has livestock listings[cite: 1]
          const SellerDashboardAction(),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: buyer == null
            ? Center(child: Text("Please log in to view your orders.", style: TextStyle(fontWeight: FontWeight.w600, color: _deepForestGreen)))
            : Column(
          children: [
            // Floating Bento Filter Tabs
            Container(
              margin: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 8))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildFilterTab(title: "To Pay", icon: Icons.account_balance_wallet_rounded, filterKey: 'To Pay'),
                  _buildFilterTab(title: "To Ship", icon: Icons.inventory_2_rounded, filterKey: 'To Ship'),
                  _buildFilterTab(title: "Receive", icon: Icons.local_shipping_rounded, filterKey: 'To Receive'),
                  _buildFilterTab(title: "To Rate", icon: Icons.star_rounded, filterKey: 'To Rate'),
                ],
              ),
            ),

            // Orders List Stream
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('orders')
                    .where('buyerId', isEqualTo: buyer.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator(color: _vibrantGreen));
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          "Error loading orders. Please check your network or Firestore rules.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w600),
                        ),
                      ),
                    );
                  }

                  final allOrders = snapshot.hasData ? snapshot.data!.docs : [];
                  final orders = allOrders.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return _matchesFilter(data['orderStatus'] ?? 'Pending Verification & Dispatch');
                  }).toList();

                  if (orders.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)]),
                            child: Icon(Icons.shopping_bag_rounded, size: 54, color: Colors.grey.shade300),
                          ),
                          const SizedBox(height: 24),
                          Text("No active orders", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _deepForestGreen)),
                          const SizedBox(height: 8),
                          Text("Your purchases will appear here.", style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 110),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final doc = orders[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final String status = data['orderStatus'] ?? 'Pending Verification & Dispatch';

                      // Status Styling Logic
                      Color statusColor = Colors.orange.shade800;
                      Color statusBg = Colors.orange.shade50;
                      if (status.toLowerCase().contains('delivered') || status.toLowerCase().contains('dispatched')) {
                        statusColor = Colors.blue.shade700;
                        statusBg = Colors.blue.shade50;
                      } else if (status.toLowerCase().contains('completed')) {
                        statusColor = _vibrantGreen;
                        statusBg = _softGreenTint;
                      } else if (status.toLowerCase().contains('cancelled')) {
                        statusColor = Colors.red.shade700;
                        statusBg = Colors.red.shade50;
                      }

                      // Safe amount parsing
                      double totalAmount = 0.0;
                      var rawAmount = data['totalAmount'];
                      if (rawAmount is int) {
                        totalAmount = rawAmount.toDouble();
                      } else if (rawAmount is double) {
                        totalAmount = rawAmount;
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(color: _deepForestGreen.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8))],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      data['livestockName'] ?? 'Livestock Item',
                                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: _deepForestGreen),
                                    ),
                                  ),
                                  Text(
                                    "₱${totalAmount.toStringAsFixed(2)}",
                                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: _vibrantGreen),
                                  ),
                                ],
                              ),
                              Divider(height: 32, color: Colors.green.shade50, thickness: 2),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: _softGreenTint, shape: BoxShape.circle),
                                    child: Icon(Icons.location_on_rounded, size: 16, color: _vibrantGreen),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      "Brgy. ${data['deliveryBarangay'] ?? 'Poblacion'}, Alaminos City",
                                      style: TextStyle(fontSize: 14, color: Colors.grey.shade800, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(12)),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.trip_origin_rounded, size: 12, color: statusColor),
                                    const SizedBox(width: 8),
                                    Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Track Order Button
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey.shade50,
                                    foregroundColor: _deepForestGreen,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: BorderSide(color: Colors.grey.shade200),
                                    ),
                                  ),
                                  icon: const Icon(Icons.radar_rounded, size: 20),
                                  label: const Text("Track Order Status", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: doc.id))),
                                ),
                              ),

                              // Conditional Completion Buttons
                              if (status.toLowerCase() == 'delivered') ...[
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _vibrantGreen,
                                      foregroundColor: Colors.white,
                                      elevation: 4,
                                      shadowColor: _vibrantGreen.withOpacity(0.3),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    ),
                                    icon: const Icon(Icons.check_circle_rounded, size: 20),
                                    label: const Text("Mark as Received", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                                    onPressed: () => _confirmReceived(context, doc.id),
                                  ),
                                ),
                              ] else if (status.toLowerCase() == 'completed' && !(data['isRated'] ?? false)) ...[
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.amber.shade400,
                                      foregroundColor: _deepForestGreen,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    ),
                                    icon: const Icon(Icons.star_rounded, size: 20),
                                    label: const Text("Rate Transaction", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                                    onPressed: () => _showRatingDialog(context, data['sellerId'] ?? '', doc.id),
                                  ),
                                ),
                              ],
                            ],
                          ),
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
    );
  }

  Widget _buildFilterTab({required String title, required IconData icon, required String filterKey}) {
    final bool isSelected = _selectedFilter == filterKey;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = isSelected ? 'All' : filterKey),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _softGreenTint : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? _vibrantGreen : Colors.grey.shade400, size: 24),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                color: isSelected ? _vibrantGreen : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper widget that checks if the current user has livestock listings[cite: 1].
/// If yes, displays a storefront button in the AppBar to view sold items.
/// Helper widget that checks if the current user has livestock listings.
/// If yes, displays a storefront button in the AppBar to view sold items.
class SellerDashboardAction extends StatelessWidget {
  const SellerDashboardAction({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Livestock') // Fixed: Capital 'L' to match your Firestore collection
          .where('seller_id', isEqualTo: user.uid) // Fixed: Changed to 'seller_id' with an underscore
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final hasListings = snapshot.data!.docs.isNotEmpty;
        if (!hasListings) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: Center(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SellerOrdersScreen()),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.storefront_rounded, size: 18, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      "My Sales",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
