import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_delivery_address_screen.dart';

class DeliveryAddressListScreen extends StatefulWidget {
  final bool isCheckoutMode;

  const DeliveryAddressListScreen({super.key, this.isCheckoutMode = false});

  @override
  State<DeliveryAddressListScreen> createState() => _DeliveryAddressListScreenState();
}

class _DeliveryAddressListScreenState extends State<DeliveryAddressListScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  final Color _deepForestGreen = const Color(0xFF0A3622);
  final Color _vibrantGreen = const Color(0xFF1B5E20);
  final Color _softGreenTint = const Color(0xFFE8F5E9);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _deleteAddress(String addressId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('addresses')
            .doc(addressId)
            .delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Address deleted successfully")),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error deleting address: $e"), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF8),
      appBar: AppBar(
        title: const Text("My Delivery Addresses", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: _deepForestGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: user == null
            ? Center(
          child: Text("Please log in to view addresses.", style: TextStyle(fontWeight: FontWeight.w500, color: _deepForestGreen)),
        )
            : StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('addresses')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: _vibrantGreen));
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyState(context);
            }

            final addressDocs = snapshot.data!.docs;

            // Sort addresses so that the default address appears at the top
            addressDocs.sort((a, b) {
              final aData = a.data() as Map<String, dynamic>;
              final bData = b.data() as Map<String, dynamic>;
              bool aIsDefault = aData['isDefault'] ?? false;
              bool bIsDefault = bData['isDefault'] ?? false;
              if (aIsDefault == bIsDefault) return 0;
              return aIsDefault ? -1 : 1;
            });

            return ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Saved Delivery Locations (${addressDocs.length})",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _deepForestGreen),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...addressDocs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final addressId = doc.id;
                  final String barangay = data['barangay'] ?? '';
                  final String zone = data['zone'] ?? '';
                  final String name = data['fullName'] ?? 'Verified Customer';
                  final String phone = data['phoneNumber'] ?? 'No phone provided';
                  final String landmark = data['landmark'] ?? '';
                  final bool isDefault = data['isDefault'] ?? false;
                  final String label = data['label'] ?? 'Home';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDefault ? _vibrantGreen : Colors.green.shade100,
                        width: isDefault ? 1.5 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Fixed Layout to prevent overlap using Wrap & Expanded
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _deepForestGreen)),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: Colors.grey.shade300),
                                          ),
                                          child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                                        ),
                                        if (isDefault)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: _softGreenTint,
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: _vibrantGreen),
                                            ),
                                            child: Text("Default", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _vibrantGreen)),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.symmetric(horizontal: 6),
                                    icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blue),
                                    tooltip: "Edit Address",
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => AddDeliveryAddressScreen(
                                            isCheckoutMode: widget.isCheckoutMode,
                                            addressIdToEdit: addressId,
                                            existingData: data,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.symmetric(horizontal: 6),
                                    icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red),
                                    tooltip: "Delete Address",
                                    onPressed: () => _deleteAddress(addressId),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(Icons.phone_outlined, size: 16, color: Colors.grey.shade600),
                              const SizedBox(width: 8),
                              Text("(+63) $phone", style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w500)),
                            ],
                          ),
                          Divider(height: 24, color: Colors.green.shade100),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.location_on_outlined, size: 20, color: _vibrantGreen),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "$zone, Brgy. $barangay, Alaminos City, Pangasinan${landmark.isNotEmpty ? '\nLandmark: $landmark' : ''}",
                                  style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (widget.isCheckoutMode)
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _vibrantGreen,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                onPressed: () {
                                  Navigator.pop(context, data);
                                },
                                child: const Text("Deliver to this Address", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 20),
                SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _vibrantGreen,
                      side: BorderSide(color: _vibrantGreen, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.add_location_alt_rounded),
                    label: const Text("Add New Delivery Address", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AddDeliveryAddressScreen()),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: _softGreenTint, shape: BoxShape.circle),
              child: Icon(Icons.location_off_outlined, size: 48, color: _vibrantGreen),
            ),
            const SizedBox(height: 18),
            Text("No Delivery Address Saved", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _deepForestGreen)),
            const SizedBox(height: 6),
            Text("Add your delivery location and contact details to proceed with orders.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _vibrantGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  shadowColor: _vibrantGreen.withOpacity(0.4),
                ),
                icon: const Icon(Icons.add_rounded),
                label: const Text("Add Delivery Address", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddDeliveryAddressScreen()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}