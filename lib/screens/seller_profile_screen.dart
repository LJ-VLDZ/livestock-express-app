import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/format_helper.dart';
import 'details_screen.dart';

class SellerProfileScreen extends StatelessWidget {
  final String sellerId;
  final String sellerName;

  const SellerProfileScreen({
    super.key,
    required this.sellerId,
    required this.sellerName,
  });

  Future<void> _makePhoneCall(BuildContext context, String phoneNumber) async {
    final cleanedNumber = phoneNumber.trim();
    if (cleanedNumber.isEmpty || cleanedNumber == 'N/A') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number is not available.'), backgroundColor: Colors.red),
      );
      return;
    }

    final Uri launchUri = Uri(scheme: 'tel', path: cleanedNumber);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open phone dialer app.'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      debugPrint("Error launching dialer: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final bool isOwnProfile = currentUserId != null && currentUserId == sellerId;

    final Color deepForestGreen = const Color(0xFF0A3622);
    final Color vibrantGreen = const Color(0xFF1B5E20);
    final Color softGreenTint = const Color(0xFFE8F5E9);

    if (isOwnProfile) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F9F4),
        appBar: AppBar(
          title: const Text("Seller Storefront", style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: deepForestGreen,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.storefront_rounded, size: 64, color: vibrantGreen),
                const SizedBox(height: 16),
                Text("This is your own seller account profile.", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: deepForestGreen), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text("You can manage your listings and sales via 'My Sales' in your dashboard.", style: TextStyle(fontSize: 13, color: Colors.grey.shade600), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F4),
      appBar: AppBar(
        title: const Text("Seller Storefront", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: deepForestGreen,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(sellerId).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                    child: Center(child: Text(sellerName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: deepForestGreen))),
                  );
                }

                final data = snapshot.data!.data() as Map<String, dynamic>;
                final String name = data['name'] ?? data['fullName'] ?? sellerName;
                final String phone = data['phone'] ?? 'N/A';
                final String barangay = data['barangay'] ?? 'Poblacion';
                final double rating = (data['rating'] ?? 5.0).toDouble();
                final int ratingCount = (data['ratingCount'] ?? 0).toInt();
                final bool isVerified = (data['verificationStatus'] ?? '') == 'verified';

                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: deepForestGreen.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 6))],
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: softGreenTint,
                        child: Icon(Icons.storefront_rounded, size: 40, color: vibrantGreen),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: deepForestGreen)),
                          if (isVerified) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.verified_rounded, color: Colors.blue, size: 20),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.star_rounded, size: 18, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            "${rating.toStringAsFixed(1)} ($ratingCount buyer reviews)",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.location_on_rounded, size: 16, color: vibrantGreen),
                          const SizedBox(width: 4),
                          Text("Brgy. $barangay, Alaminos City", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (phone != 'N/A' && phone.isNotEmpty)
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: vibrantGreen,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            icon: const Icon(Icons.phone_rounded, size: 18),
                            label: Text("Call Seller: $phone", style: const TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: () => _makePhoneCall(context, phone),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Firestore Stream for all listings
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('livestock')
                  .where('seller_id', isEqualTo: sellerId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: CircularProgressIndicator(color: vibrantGreen),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text("This seller has no listings right now.", style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                    ),
                  );
                }

                final docs = snapshot.data!.docs;

                final activeDocs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final bool isAvailable = data['isAvailable'] ?? true;
                  final String status = (data['status'] ?? '').toString().toLowerCase();
                  return isAvailable && status != 'sold' && status != 'reserved';
                }).toList();

                final soldDocs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final bool isAvailable = data['isAvailable'] ?? true;
                  final String status = (data['status'] ?? '').toString().toLowerCase();
                  return !isAvailable || status == 'sold' || status == 'reserved';
                }).toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // SECTION 1: Active Listings (Clickable)
                    Text("Active Listings (${activeDocs.length})", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: deepForestGreen)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: deepForestGreen.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: activeDocs.isEmpty
                          ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: Text("No active listings available right now.", style: TextStyle(color: Colors.grey, fontSize: 13))),
                      )
                          : GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.65,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: activeDocs.length,
                        itemBuilder: (context, index) {
                          final doc = activeDocs[index];
                          final item = doc.data() as Map<String, dynamic>;
                          final String imageUrl = item['imageUrl'] ?? '';
                          final double price = (item['price'] ?? 0.0).toDouble();

                          return InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailsScreen(docId: doc.id, item: item))),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.green.shade100),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                                      child: imageUrl.isNotEmpty
                                          ? Image.network(imageUrl, fit: BoxFit.cover, width: double.infinity)
                                          : Container(color: Colors.green.shade50, child: Icon(Icons.pets, color: vibrantGreen)),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['livestock_name'] ?? 'Livestock',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: deepForestGreen),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "₱${FormatHelper.formatCurrency(price)}",
                                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: vibrantGreen),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 28),

                    // SECTION 2: Sold & Reserved Listings (Non-Clickable)
                    Text("Sold & Reserved Listings (${soldDocs.length})", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: deepForestGreen)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: soldDocs.isEmpty
                          ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: Text("No sold items recorded yet.", style: TextStyle(color: Colors.grey, fontSize: 13))),
                      )
                          : GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.65,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: soldDocs.length,
                        itemBuilder: (context, index) {
                          final doc = soldDocs[index];
                          final item = doc.data() as Map<String, dynamic>;
                          final String imageUrl = item['imageUrl'] ?? '';
                          final double price = (item['price'] ?? 0.0).toDouble();

                          // Replaced InkWell with a standard Container so sold items are not clickable
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Stack(
                                    children: [
                                      Positioned.fill(
                                        child: ClipRRect(
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                                          child: ColorFiltered(
                                            colorFilter: const ColorFilter.matrix(<double>[
                                              0.2126, 0.7152, 0.0722, 0, 0,
                                              0.2126, 0.7152, 0.0722, 0, 0,
                                              0.2126, 0.7152, 0.0722, 0, 0,
                                              0,      0,      0,      1, 0,
                                            ]),
                                            child: imageUrl.isNotEmpty
                                                ? Image.network(imageUrl, fit: BoxFit.cover, width: double.infinity)
                                                : Container(color: Colors.grey.shade200, child: const Icon(Icons.pets, color: Colors.grey)),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade800,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            "SOLD",
                                            style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['livestock_name'] ?? 'Livestock',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey.shade700),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "₱${FormatHelper.formatCurrency(price)}",
                                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}