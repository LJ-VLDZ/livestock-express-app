import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'messages_screen.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  GoogleMapController? _mapController;

  // Strict bounding box for Alaminos City, Pangasinan (covers all 39 barangays)
  static final LatLngBounds alaminosBounds = LatLngBounds(
    southwest: const LatLng(16.0800, 119.9000),
    northeast: const LatLng(16.2300, 120.0700),
  );

  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(16.1556, 119.9844), // Alaminos City Center (Poblacion)
    zoom: 13.5,
  );

  final Color _deepForestGreen = const Color(0xFF0A3622);
  final Color _vibrantGreen = const Color(0xFF1B5E20);

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
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _confirmReceived(BuildContext context, String orderId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Confirm Livestock Received", style: TextStyle(fontWeight: FontWeight.bold, color: _deepForestGreen)),
        content: const Text("Are you sure you have received your livestock in good condition? This will complete the order and release funds to the seller."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel", style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _vibrantGreen, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Confirm Received", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('orders').doc(orderId).update({'orderStatus': 'Completed'});
        if (context.mounted) _showSnackBar("Order marked as Completed! Thank you.");
      } catch (e) {
        if (context.mounted) _showSnackBar("Error updating order: $e", isError: true);
      }
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
        title: const Text("Alaminos Delivery Tracking", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: _deepForestGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MessagesScreen())),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('orders').doc(widget.orderId).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: _vibrantGreen));
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(child: Text("Order not found.", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)));
            }

            final data = snapshot.data!.data() as Map<String, dynamic>;
            final String livestockName = data['livestockName'] ?? 'Livestock Item';
            final String status = data['orderStatus'] ?? 'Pending Verification & Dispatch';
            final String barangay = data['deliveryBarangay'] ?? 'Poblacion';
            final double totalAmount = (data['totalAmount'] ?? 0.0).toDouble();

            // Pull live coordinates from seller broadcast if available
            double? lat = data['deliveryLatitude'];
            double? lng = data['deliveryLongitude'];
            LatLng markerPosition = (lat != null && lng != null) ? LatLng(lat, lng) : const LatLng(16.1556, 119.9844);

            final Set<Marker> markers = {
              Marker(
                markerId: const MarkerId('live_delivery'),
                position: markerPosition,
                infoWindow: InfoWindow(title: livestockName, snippet: 'Status: $status'),
              ),
            };

            return ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20.0),
              children: [
                // Google Maps Widget restricted to Alaminos City
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.shade200, width: 1.5),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: GoogleMap(
                      initialCameraPosition: _initialCameraPosition,
                      markers: markers,
                      cameraTargetBounds: CameraTargetBounds(alaminosBounds),
                      minMaxZoomPreference: const MinMaxZoomPreference(11.0, 18.0),
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                      zoomControlsEnabled: false,
                      onMapCreated: (GoogleMapController controller) {
                        _mapController = controller;
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Order Info Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.shade100, width: 1),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(livestockName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: _deepForestGreen))),
                          Text("₱${totalAmount.toStringAsFixed(2)}", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: _vibrantGreen)),
                        ],
                      ),
                      Divider(height: 24, color: Colors.green.shade100),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, color: Colors.grey.shade600, size: 20),
                          const SizedBox(width: 8),
                          Expanded(child: Text("Destination: Barangay $barangay, Alaminos City", style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w500))),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.local_shipping_outlined, color: Colors.grey.shade600, size: 20),
                          const SizedBox(width: 8),
                          Expanded(child: Text("Status: $status", style: TextStyle(fontWeight: FontWeight.bold, color: _vibrantGreen, fontSize: 14))),
                        ],
                      ),
                      if (status == 'Delivered') ...[
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: _vibrantGreen, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                            icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                            label: const Text("Livestock Received & Complete Order", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            onPressed: () => _confirmReceived(context, widget.orderId),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text("Logistics & Inspection Timeline", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _deepForestGreen)),
                const SizedBox(height: 12),
                _buildTimelineTile("Order Placed & Verified", "Buyer confirmed order details.", true),
                _buildTimelineTile("City Veterinary Inspection", "Checking animal health papers for transport.", status != 'Pending Verification & Dispatch'),
                _buildTimelineTile("Dispatched for Delivery", "En route to Alaminos destination.", status == 'Dispatched' || status == 'Delivered' || status == 'Completed'),
                _buildTimelineTile("Delivered & Handed Over", "Transaction completed successfully.", status == 'Delivered' || status == 'Completed'),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTimelineTile(String title, String subtitle, bool isCompleted) {
    return ListTile(
      leading: Icon(
        isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
        color: isCompleted ? _vibrantGreen : Colors.grey.shade400,
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isCompleted ? _deepForestGreen : Colors.grey.shade600)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
    );
  }
}