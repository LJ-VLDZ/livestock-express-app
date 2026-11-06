import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/format_helper.dart';
import '../utils/distance_helper.dart';
import 'order_tracking_screen.dart';
import 'delivery_address_list_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final Map<String, dynamic> listingData;
  final String listingId;

  const CheckoutScreen({
    super.key,
    required this.listingData,
    required this.listingId,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> with SingleTickerProviderStateMixin {
  final User? user = FirebaseAuth.instance.currentUser;

  final Color _deepForestGreen = const Color(0xFF0A3622);
  final Color _vibrantGreen = const Color(0xFF1B5E20);

  bool _isLoading = true;
  bool _isPlacingOrder = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  Map<String, dynamic> _deliveryDetails = {
    'name': '',
    'phone': '',
    'barangay': 'Poblacion',
    'zone': '',
    'landmark': '',
    'latitude': 16.1556,
    'longitude': 119.9881,
  };

  String _paymentMethod = "Cash on Delivery (COD)";
  final List<String> _paymentOptions = [
    "Cash on Delivery (COD)",
    "Municipal Bank Transfer / GCash",
    "Direct Farm Pickup & Cash Payment"
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserDefaultAddress();

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

  Future<void> _fetchUserDefaultAddress() async {
    if (user == null) return;
    try {
      final addressesQuery = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('addresses')
          .where('isDefault', isEqualTo: true)
          .limit(1)
          .get();

      if (addressesQuery.docs.isNotEmpty) {
        final data = addressesQuery.docs.first.data();
        setState(() {
          _deliveryDetails = {
            'name': data['fullName'] ?? data['name'] ?? user?.email ?? 'Customer',
            'phone': data['phoneNumber'] ?? data['phone'] ?? '',
            'barangay': data['barangay'] ?? 'Poblacion',
            'zone': data['zone'] ?? data['addressZone'] ?? '',
            'landmark': data['landmark'] ?? data['addressLandmark'] ?? '',
            'latitude': data['latitude'] ?? 16.1556,
            'longitude': data['longitude'] ?? 119.9881,
          };
        });
        setState(() => _isLoading = false);
        return;
      }

      final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _deliveryDetails = {
            'name': data['fullName'] ?? data['name'] ?? user?.email ?? 'Customer',
            'phone': data['phone'] ?? data['phoneNumber'] ?? '',
            'barangay': data['barangay'] ?? 'Poblacion',
            'zone': data['addressZone'] ?? data['zone'] ?? '',
            'landmark': data['addressLandmark'] ?? data['landmark'] ?? '',
            'latitude': data['latitude'] ?? 16.1556,
            'longitude': data['longitude'] ?? 119.9881,
          };
        });
      }
    } catch (e) {
      debugPrint("Error fetching default address: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _changeAddress() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const DeliveryAddressListScreen(isCheckoutMode: true),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _deliveryDetails = {
          'name': result['fullName'] ?? result['name'] ?? _deliveryDetails['name'],
          'phone': result['phoneNumber'] ?? result['phone'] ?? _deliveryDetails['phone'],
          'barangay': result['barangay'] ?? _deliveryDetails['barangay'],
          'zone': result['zone'] ?? result['addressZone'] ?? _deliveryDetails['zone'],
          'landmark': result['landmark'] ?? result['addressLandmark'] ?? _deliveryDetails['landmark'],
          'latitude': result['latitude'] ?? _deliveryDetails['latitude'],
          'longitude': result['longitude'] ?? _deliveryDetails['longitude'],
        };
      });
    }
  }

  Future<void> _submitOrder() async {
    if (_deliveryDetails['zone'].toString().isEmpty) {
      _showSnackBar("Please complete or select your delivery address zone/street.", isError: true);
      return;
    }

    setState(() => _isPlacingOrder = true);
    try {
      final rawPrice = widget.listingData['price'];
      final double price = rawPrice is int ? rawPrice.toDouble() : (rawPrice ?? 0.0);

      final String sellerBarangay = widget.listingData['sellerBarangay'] ?? 'Poblacion';
      final String buyerBarangay = _deliveryDetails['barangay'];
      final double deliveryFee = DistanceHelper.calculateTransportFee(sellerBarangay, buyerBarangay);

      final double totalPrice = price + deliveryFee;
      final String sellerId = widget.listingData['seller_id'] ?? widget.listingData['sellerId'] ?? '';
      final String title = widget.listingData['livestock_name'] ?? widget.listingData['title'] ?? 'Livestock Item';

      String buyerName = _deliveryDetails['name'];
      if (buyerName.isEmpty) buyerName = user?.email ?? 'Buyer';

      String sellerName = widget.listingData['sellerName'] ?? widget.listingData['seller_name'] ?? 'Seller';
      if (sellerName == 'Seller' || sellerName.isEmpty) {
        final sellerDoc = await FirebaseFirestore.instance.collection('users').doc(sellerId).get();
        if (sellerDoc.exists && sellerDoc.data() != null) {
          sellerName = sellerDoc.data()!['name'] ?? sellerDoc.data()!['fullName'] ?? 'Seller';
        }
      }

      DocumentReference orderRef = await FirebaseFirestore.instance.collection('orders').add({
        'listingId': widget.listingId,
        'livestockName': title,
        'itemPrice': price,
        'deliveryFee': deliveryFee,
        'totalAmount': totalPrice,
        'sellerId': sellerId,
        'sellerName': sellerName,
        'buyerId': user!.uid,
        'buyerName': buyerName,
        'buyerPhone': _deliveryDetails['phone'],
        'deliveryBarangay': _deliveryDetails['barangay'],
        'deliveryZone': _deliveryDetails['zone'],
        'deliveryCity': 'Alaminos City, Pangasinan',
        'deliveryInstructions': _deliveryDetails['landmark'],
        'deliveryLatitude': _deliveryDetails['latitude'],
        'deliveryLongitude': _deliveryDetails['longitude'],
        'latitude': _deliveryDetails['latitude'],
        'longitude': _deliveryDetails['longitude'],
        'paymentMethod': _paymentMethod,
        'orderStatus': 'Pending Verification & Dispatch',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('livestock').doc(widget.listingId).update({
        'isAvailable': false,
        'status': 'Ordered',
      });

      // Record the buyer's order activity separately.
      // A logging failure should not make a successfully-created order appear to fail.
      try {
        await FirebaseFirestore.instance.collection('activity_logs').add({
          'actorType': 'user',
          'user_name': buyerName,
          'user_email': user?.email ?? '',
          'user_id': user!.uid,
          'target_user_id': orderRef.id,
          'action': 'Buyer placed an order: $title',
          'details': 'Order ID: ${orderRef.id}; Seller: $sellerName; Total: ₱${FormatHelper.formatCurrency(totalPrice)}; Payment method: $_paymentMethod',
          'timestamp': FieldValue.serverTimestamp(),
        });
      } catch (logError) {
        debugPrint('Unable to save buyer order activity: $logError');
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OrderTrackingScreen(orderId: orderRef.id),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar("Order submission failed: $e", isError: true);
      }
    } finally {
      if (mounted) setState(() => _isPlacingOrder = false);
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
    final rawPrice = widget.listingData['price'];
    final double price = rawPrice is int ? rawPrice.toDouble() : (rawPrice ?? 0.0);
    final String title = widget.listingData['livestock_name'] ?? widget.listingData['title'] ?? 'Livestock';

    final String sellerBarangay = widget.listingData['sellerBarangay'] ?? 'Poblacion';
    final String buyerBarangay = _deliveryDetails['barangay'];
    final double deliveryFee = DistanceHelper.calculateTransportFee(sellerBarangay, buyerBarangay);
    final double totalPrice = price + deliveryFee;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF8),
      appBar: AppBar(
        title: const Text("Checkout", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: _deepForestGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: _vibrantGreen))
            : SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.shade100, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(Icons.location_pin, color: Color(0xFFE53935), size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _deliveryDetails['name'].isEmpty ? "Delivery Address" : _deliveryDetails['name'],
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _deepForestGreen),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (_deliveryDetails['phone'].isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Text("(+63) ${_deliveryDetails['phone']}", style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500)),
                              ],
                            ],
                          ),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(foregroundColor: _vibrantGreen),
                          onPressed: _changeAddress,
                          child: const Text("Change", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _deliveryDetails['zone'].isEmpty && _deliveryDetails['barangay'].isEmpty
                          ? "No delivery address set. Tap 'Change' to pick location."
                          : "${_deliveryDetails['zone']}, Brgy. ${_deliveryDetails['barangay']}, Alaminos City, Pangasinan",
                      style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4, fontWeight: FontWeight.w500),
                    ),
                    if (_deliveryDetails['landmark'].isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text("Landmark: ${_deliveryDetails['landmark']}", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.shade100, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.local_shipping_outlined, size: 18, color: _vibrantGreen),
                        const SizedBox(width: 8),
                        Text("Fulfilled — Local Livestock Delivery", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _deepForestGreen)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      deliveryFee == 0.0
                          ? "✨ Same-barangay hauling (Brgy. $sellerBarangay): FREE Delivery!"
                          : "Hauling from Brgy. $sellerBarangay to Brgy. $buyerBarangay",
                      style: TextStyle(fontSize: 11, color: deliveryFee == 0.0 ? _vibrantGreen : Colors.grey.shade600, fontWeight: FontWeight.w600),
                    ),
                    Divider(height: 24, color: Colors.green.shade100),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _deepForestGreen))),
                        Text("₱${FormatHelper.formatCurrency(price)}", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: _vibrantGreen)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Municipal Transport & Inspection Fee", style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500)),
                        Text(deliveryFee == 0.0 ? "FREE" : "₱${FormatHelper.formatCurrency(deliveryFee)}", style: TextStyle(fontSize: 13, color: deliveryFee == 0.0 ? _vibrantGreen : Colors.grey.shade800, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.shade100, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Payment Method", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _deepForestGreen)),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: _paymentMethod,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.green.shade200)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.green.shade200)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _vibrantGreen, width: 2)),
                        filled: true,
                        fillColor: const Color(0xFFF8FBF8),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: _paymentOptions.map((opt) => DropdownMenuItem(value: opt, child: Text(opt, style: const TextStyle(fontSize: 14)))).toList(),
                      onChanged: (val) => setState(() => _paymentMethod = val!),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.shade100, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Total Payable", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _deepForestGreen)),
                        Text("₱${FormatHelper.formatCurrency(totalPrice)}", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: _vibrantGreen)),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _vibrantGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 4,
                          shadowColor: _vibrantGreen.withOpacity(0.4),
                        ),
                        onPressed: _isPlacingOrder ? null : _submitOrder,
                        child: _isPlacingOrder
                            ? const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                            : const Text("Place Order", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}