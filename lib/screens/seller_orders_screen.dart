import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:livestock_app/services/cloudinary_service.dart';
import '../utils/format_helper.dart';

class SellerOrdersScreen extends StatefulWidget {
  const SellerOrdersScreen({super.key});

  @override
  State<SellerOrdersScreen> createState() => _SellerOrdersScreenState();
}

class _SellerOrdersScreenState extends State<SellerOrdersScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  final Color _deepForestGreen = const Color(0xFF062314);
  final Color _vibrantGreen = const Color(0xFF134E27);
  final Color _surfaceBg = const Color(0xFFF1F6F2);

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

  // Opens camera picker to submit multi-angle inspection photos
  Future<void> _showInspectionUploadDialog(BuildContext context, String orderId) async {
    List<File> inspectionImages = [];
    final ImagePicker picker = ImagePicker();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text("Livestock Inspection", style: TextStyle(fontWeight: FontWeight.w900, color: _deepForestGreen)),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Upload photos of all sides of the livestock body for online municipal inspection before dispatch.",
                      style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 100,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          ...inspectionImages.map((img) => Container(
                            width: 90,
                            height: 90,
                            margin: const EdgeInsets.only(right: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(img, fit: BoxFit.cover),
                            ),
                          )),
                          if (inspectionImages.length < 4)
                            GestureDetector(
                              onTap: () async {
                                final XFile? photo = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
                                if (photo != null) {
                                  setDialogState(() {
                                    inspectionImages.add(File(photo.path));
                                  });
                                }
                              },
                              child: Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.green.shade300, style: BorderStyle.solid),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.camera_alt, color: _vibrantGreen),
                                    const SizedBox(height: 4),
                                    const Text("Add Side", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _vibrantGreen, foregroundColor: Colors.white),
                  onPressed: inspectionImages.isEmpty
                      ? null
                      : () async {
                    Navigator.pop(dialogContext);
                    _submitInspectionPhotos(orderId, inspectionImages);
                  },
                  child: const Text("Submit for Review"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submitInspectionPhotos(String orderId, List<File> images) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Center(child: CircularProgressIndicator(color: _vibrantGreen)),
      );

      List<String> uploadedUrls = [];
      for (File img in images) {
        String? url = await CloudinaryService.uploadImage(img);
        if (url != null) uploadedUrls.add(url);
      }

      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'inspectionPhotos': uploadedUrls,
        'orderStatus': 'Pending Online Inspection Review',
        'inspectionSubmittedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context); // Pop loading
        _showSnackBar("Inspection photos submitted to admin successfully!");
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showSnackBar("Failed to upload photos: $e", isError: true);
      }
    }
  }

  Future<void> _updateOrderStatus(BuildContext context, String orderId, String newStatus, {String? livestockId, double? totalAmount}) async {
    try {
      final firestore = FirebaseFirestore.instance;
      Map<String, dynamic> orderUpdateData = {'orderStatus': newStatus};

      if (newStatus.toLowerCase() == 'dispatched') {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }
          if (permission != LocationPermission.deniedForever) {
            Position position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
            );
            orderUpdateData['deliveryLatitude'] = position.latitude;
            orderUpdateData['deliveryLongitude'] = position.longitude;
            orderUpdateData['lastLocationUpdate'] = FieldValue.serverTimestamp();
          }
        }
      }

      // Firestore Transaction to safely handle inventory and financial logs
      await firestore.runTransaction((transaction) async {
        DocumentReference orderRef = firestore.collection('orders').doc(orderId);
        transaction.update(orderRef, orderUpdateData);

        if (newStatus.toLowerCase() == 'delivered' && livestockId != null && livestockId.isNotEmpty) {
          DocumentReference livestockRef = firestore.collection('livestock').doc(livestockId);
          transaction.update(livestockRef, {
            'status': 'Sold',
            'isAvailable': false,
          });

          // Log transaction for Laravel Admin panel summary (`transactions.blade.php`)
          DocumentReference transactionRef = firestore.collection('transactions').doc();
          transaction.set(transactionRef, {
            'orderId': orderId,
            'livestockId': livestockId,
            'totalAmount': totalAmount ?? 0.0,
            'status': 'Completed',
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      });

      if (context.mounted) {
        _showSnackBar("Order updated to: $newStatus");
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar("Failed to update status: $e", isError: true);
      }
    }
  }

  Future<void> _openMapRoute(BuildContext context, double? lat, double? lng, String barangay) async {
    final Uri mapUrl;
    if (lat != null && lng != null && lat != 0.0 && lng != 0.0) {
      mapUrl = Uri.parse("https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving");
    } else {
      String destination = "Barangay $barangay, Alaminos City, Pangasinan";
      mapUrl = Uri.parse("https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(destination)}");
    }

    if (await canLaunchUrl(mapUrl)) {
      await launchUrl(mapUrl, mode: LaunchMode.externalApplication);
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
    final User? seller = FirebaseAuth.instance.currentUser;

    if (seller == null) {
      return Scaffold(
        backgroundColor: _surfaceBg,
        body: Center(child: Text("Please log in as a seller.", style: TextStyle(fontWeight: FontWeight.w700, color: _deepForestGreen, fontSize: 16))),
      );
    }

    return Scaffold(
      backgroundColor: _surfaceBg,
      appBar: AppBar(
        title: const Text("Incoming Buyer Orders", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: -0.5)),
        backgroundColor: _deepForestGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('orders')
              .where('sellerId', isEqualTo: seller.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: _vibrantGreen, strokeWidth: 3));
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(child: Text("No incoming orders yet", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _deepForestGreen)));
            }

            final orders = snapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final status = (data['orderStatus'] ?? data['status'] ?? '').toString().toLowerCase();
              return !status.contains('delivered') && !status.contains('completed') && !status.contains('cancelled');
            }).toList();

            if (orders.isEmpty) {
              return Center(child: Text("All orders fulfilled!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _deepForestGreen)));
            }

            return ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final doc = orders[index];
                final data = doc.data() as Map<String, dynamic>;
                final String orderId = doc.id;
                final String livestockName = data['livestockName'] ?? 'Livestock Item';
                final String livestockId = data['livestockId'] ?? data['productId'] ?? '';
                final double totalAmount = (data['totalAmount'] ?? 0.0).toDouble();
                final String barangay = data['deliveryBarangay'] ?? data['barangay'] ?? 'Poblacion';
                final String phone = data['buyerPhone'] ?? 'N/A';
                final String status = data['orderStatus'] ?? data['status'] ?? 'Pending';
                final double? deliveryLat = data['deliveryLatitude'];
                final double? deliveryLng = data['deliveryLongitude'];
                String statusLower = status.toLowerCase();

                return Container(
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.green.shade100, width: 1.5),
                    boxShadow: [BoxShadow(color: _deepForestGreen.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(22.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(livestockName, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: _deepForestGreen))),
                            Text("₱${FormatHelper.formatCurrency(totalAmount)}", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: _vibrantGreen)),
                          ],
                        ),
                        Divider(height: 28, color: Colors.grey.shade100),
                        Row(
                          children: [
                            Icon(Icons.location_on_rounded, size: 16, color: _vibrantGreen),
                            const SizedBox(width: 12),
                            Expanded(child: Text("Brgy. $barangay, Alaminos City", style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w700))),
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                backgroundColor: const Color(0xFFE8F5E9),
                                foregroundColor: _vibrantGreen,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.navigation_rounded, size: 14),
                              label: const Text("Route", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                              onPressed: () => _openMapRoute(context, deliveryLat, deliveryLng, barangay),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.info_outline, size: 16, color: Colors.orange.shade800),
                            const SizedBox(width: 12),
                            Expanded(child: Text("Status: $status", style: TextStyle(fontSize: 13, color: Colors.orange.shade800, fontWeight: FontWeight.w700))),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          alignment: WrapAlignment.end,
                          children: [
                            if (statusLower == 'pending' || statusLower == 'pending verification & dispatch')
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.orange.shade800,
                                  side: BorderSide(color: Colors.orange.shade300, width: 1.5),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                onPressed: () => _showInspectionUploadDialog(context, orderId),
                                child: const Text("Upload Inspection Photos", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
                              ),
                            if (statusLower.contains('inspection approved') || statusLower.contains('city veterinary inspection approved'))
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _vibrantGreen,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                onPressed: () => _updateOrderStatus(context, orderId, 'Dispatched'),
                                child: const Text("Dispatch & Broadcast GPS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
                              ),
                            if (statusLower.contains('dispatched'))
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade700,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                onPressed: () => _updateOrderStatus(context, orderId, 'Delivered', livestockId: livestockId, totalAmount: totalAmount),
                                child: const Text("Delivered", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
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
}