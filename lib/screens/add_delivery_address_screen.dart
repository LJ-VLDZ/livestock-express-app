import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddDeliveryAddressScreen extends StatefulWidget {
  final bool isCheckoutMode;
  final String? addressIdToEdit;
  final Map<String, dynamic>? existingData;

  const AddDeliveryAddressScreen({
    super.key,
    this.isCheckoutMode = false,
    this.addressIdToEdit,
    this.existingData,
  });

  @override
  State<AddDeliveryAddressScreen> createState() => _AddDeliveryAddressScreenState();
}

class _AddDeliveryAddressScreenState extends State<AddDeliveryAddressScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();

  double _selectedLat = 16.1556;
  double _selectedLng = 119.9881;
  String _selectedBarangay = 'Poblacion';
  bool _isDefault = false;
  String _addressLabel = 'Home';
  bool _isSaving = false;
  bool _isReverseGeocoding = false;
  GoogleMapController? _previewMapController;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  final Color _deepForestGreen = const Color(0xFF0A3622);
  final Color _vibrantGreen = const Color(0xFF1B5E20);
  final Color _softGreenTint = const Color(0xFFE8F5E9);

  final List<String> _alaminosBarangays = [
    'Alos', 'Amandiego', 'Amangbangan', 'Balangobong', 'Balayang', 'Baleyadaan', 'Bolaney', 'Bued', 'Cabatuan', 'Cayucay',
    'Dulacac', 'Inerangan', 'Landoc', 'Linmansangan', 'Lucap', 'Maawi', 'Macatiw', 'Magsaysay', 'Mona', 'Palamis', 'Pandan',
    'Pangapisan', 'Poblacion', 'Pocal-pocal', 'Pogo', 'Polo', 'Quibuar', 'Sabangan', 'San Antonio', 'San Jose', 'San Roque',
    'San Vicente', 'Sta. Maria', 'Tanaytay', 'Tangcarang', 'Tawin-tawin', 'Telbang', 'Victoria',
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();

    if (widget.existingData != null) {
      _nameController.text = widget.existingData!['fullName'] ?? '';
      _phoneController.text = widget.existingData!['phoneNumber'] ?? '';
      _streetController.text = widget.existingData!['zone'] ?? '';
      _landmarkController.text = widget.existingData!['landmark'] ?? '';
      _selectedBarangay = widget.existingData!['barangay'] ?? 'Poblacion';
      _isDefault = widget.existingData!['isDefault'] ?? false;
      _addressLabel = widget.existingData!['label'] ?? 'Home';
      _selectedLat = (widget.existingData!['latitude'] ?? 16.1556).toDouble();
      _selectedLng = (widget.existingData!['longitude'] ?? 119.9881).toDouble();
    } else {
      _loadUserProfileData();
    }
  }

  Future<void> _loadUserProfileData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _nameController.text = data['fullName'] ?? data['name'] ?? user.displayName ?? 'Verified Customer';
          _phoneController.text = data['phoneNumber'] ?? data['phone'] ?? data['mobile'] ?? '';
        });
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _landmarkController.dispose();
    _previewMapController?.dispose();
    super.dispose();
  }

  Future<void> _getAddressDetailsFromCoordinates(double lat, double lng) async {
    setState(() => _isReverseGeocoding = true);
    try {
      // Explicitly prefixing with geo to ensure geocoding ^5.0.0 is called properly
      List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        geo.Placemark place = placemarks.first;

        String streetInfo = [place.street, place.subLocality]
            .where((element) => element != null && element.isNotEmpty)
            .join(', ');

        String detectedBarangay = _selectedBarangay;
        String combinedPlacemark = "${place.name} ${place.street} ${place.subLocality} ${place.locality} ${place.subAdministrativeArea}".toLowerCase();

        for (String brgy in _alaminosBarangays) {
          if (combinedPlacemark.contains(brgy.toLowerCase())) {
            detectedBarangay = brgy;
            break;
          }
        }

        setState(() {
          _selectedBarangay = detectedBarangay;
          if (streetInfo.isNotEmpty && !_streetController.text.contains(streetInfo)) {
            _streetController.text = streetInfo;
          }
        });
      }
    } catch (e) {
      // Ignore geocoding errors
    } finally {
      setState(() => _isReverseGeocoding = false);
    }
  }

  void _openMapPicker(BuildContext context) async {
    final LatLng? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _GoogleMapPickerScreen(
          initialLat: _selectedLat,
          initialLng: _selectedLng,
          deepForestGreen: _deepForestGreen,
          vibrantGreen: _vibrantGreen,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedLat = result.latitude;
        _selectedLng = result.longitude;
      });
      _previewMapController?.animateCamera(CameraUpdate.newLatLngZoom(result, 16.0));
      await _getAddressDetailsFromCoordinates(_selectedLat, _selectedLng);
    }
  }

  Future<void> _submitAddress() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final addressData = {
      'fullName': _nameController.text.trim(),
      'phoneNumber': _phoneController.text.trim(),
      'region': 'North Luzon',
      'province': 'Pangasinan',
      'city': 'Alaminos City',
      'barangay': _selectedBarangay,
      'postalCode': '2404',
      'zone': _streetController.text.trim(),
      'landmark': _landmarkController.text.trim(),
      'latitude': _selectedLat,
      'longitude': _selectedLng,
      'isDefault': _isDefault,
      'label': _addressLabel,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (widget.isCheckoutMode) {
      Navigator.pop(context, addressData);
    } else {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final addressesRef = FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('addresses');

          if (_isDefault) {
            final batch = FirebaseFirestore.instance.batch();
            final existingAddresses = await addressesRef.where('isDefault', isEqualTo: true).get();
            for (var doc in existingAddresses.docs) {
              batch.update(doc.reference, {'isDefault': false});
            }
            await batch.commit();
          }

          if (widget.addressIdToEdit != null) {
            await addressesRef.doc(widget.addressIdToEdit).update(addressData);
          } else {
            addressData['createdAt'] = FieldValue.serverTimestamp();
            await addressesRef.add(addressData);
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(widget.addressIdToEdit != null ? "Address updated successfully!" : "Address added successfully!"), backgroundColor: _vibrantGreen),
            );
            Navigator.pop(context);
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to save address: $e"), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deleteAddress() async {
    if (widget.addressIdToEdit == null) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('addresses')
          .doc(widget.addressIdToEdit)
          .delete();
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.addressIdToEdit != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F4),
      appBar: AppBar(
        title: Text(isEditing ? "Edit Address" : "New Address", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: _deepForestGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Contact", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _nameController,
                              readOnly: true,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              decoration: const InputDecoration(
                                labelText: "Full Name",
                                suffixIcon: Icon(Icons.lock_outline_rounded, size: 16, color: Colors.grey),
                                border: UnderlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _phoneController,
                              readOnly: true,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              decoration: const InputDecoration(
                                labelText: "Phone Number",
                                prefixText: "(+63) ",
                                suffixIcon: Icon(Icons.lock_outline_rounded, size: 16, color: Colors.grey),
                                border: UnderlineInputBorder(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      const Text("Address Details", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Region, Province, City, Barangay", style: TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text("North Luzon\nPangasinan\nAlaminos City", style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.3)),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: _selectedBarangay,
                              decoration: const InputDecoration(
                                labelText: "Barangay",
                                border: UnderlineInputBorder(),
                              ),
                              items: _alaminosBarangays.map((brgy) => DropdownMenuItem(value: brgy, child: Text(brgy, style: const TextStyle(fontSize: 14)))).toList(),
                              onChanged: (val) => setState(() => _selectedBarangay = val!),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              initialValue: "2404",
                              readOnly: true,
                              decoration: const InputDecoration(
                                labelText: "Postal Code",
                                border: UnderlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _streetController,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              decoration: const InputDecoration(
                                labelText: "Street Name, Building, House No.",
                                border: UnderlineInputBorder(),
                              ),
                              validator: (val) => val == null || val.trim().isEmpty ? "Please enter street / zone" : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _landmarkController,
                              style: const TextStyle(fontSize: 14),
                              decoration: const InputDecoration(
                                labelText: "Delivery Landmark / Notes (Optional)",
                                border: UnderlineInputBorder(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Map Preview & Picker Card
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: Column(
                          children: [
                            SizedBox(
                              height: 160,
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                child: GoogleMap(
                                  initialCameraPosition: CameraPosition(target: LatLng(_selectedLat, _selectedLng), zoom: 15.0),
                                  markers: {
                                    Marker(markerId: const MarkerId('pin'), position: LatLng(_selectedLat, _selectedLng)),
                                  },
                                  zoomControlsEnabled: false,
                                  scrollGesturesEnabled: false,
                                  rotateGesturesEnabled: false,
                                  tiltGesturesEnabled: false,
                                  onMapCreated: (controller) => _previewMapController = controller,
                                ),
                              ),
                            ),
                            ListTile(
                              title: const Text("Pin Exact Location on Map", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              subtitle: Text("Lat: ${_selectedLat.toStringAsFixed(4)}, Lng: ${_selectedLng.toStringAsFixed(4)}", style: const TextStyle(fontSize: 12)),
                              trailing: Icon(Icons.arrow_forward_ios, size: 16, color: _vibrantGreen),
                              onTap: () => _openMapPicker(context),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Settings & Labels
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: Column(
                          children: [
                            SwitchListTile(
                              title: const Text("Set as Default Address", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                              value: _isDefault,
                              activeColor: _vibrantGreen,
                              onChanged: (val) => setState(() => _isDefault = val),
                            ),
                            const Divider(height: 1),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                children: [
                                  const Text("Label As:", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                                  const SizedBox(width: 16),
                                  ChoiceChip(
                                    label: const Text("Work"),
                                    selected: _addressLabel == 'Work',
                                    selectedColor: _softGreenTint,
                                    labelStyle: TextStyle(color: _addressLabel == 'Work' ? _vibrantGreen : Colors.black87, fontWeight: FontWeight.bold),
                                    onSelected: (selected) => setState(() => _addressLabel = 'Work'),
                                  ),
                                  const SizedBox(width: 10),
                                  ChoiceChip(
                                    label: const Text("Home"),
                                    selected: _addressLabel == 'Home',
                                    selectedColor: _softGreenTint,
                                    labelStyle: TextStyle(color: _addressLabel == 'Home' ? _vibrantGreen : Colors.black87, fontWeight: FontWeight.bold),
                                    onSelected: (selected) => setState(() => _addressLabel = 'Home'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Actions Bar
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                children: [
                  if (isEditing) ...[
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: _deleteAddress,
                        child: const Text("Delete Address", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _vibrantGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      onPressed: _isSaving ? null : _submitAddress,
                      child: _isSaving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("Submit", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Fullscreen Google Map Picker Dialog
class _GoogleMapPickerScreen extends StatefulWidget {
  final double initialLat;
  final double initialLng;
  final Color deepForestGreen;
  final Color vibrantGreen;

  const _GoogleMapPickerScreen({
    required this.initialLat,
    required this.initialLng,
    required this.deepForestGreen,
    required this.vibrantGreen,
  });

  @override
  State<_GoogleMapPickerScreen> createState() => _GoogleMapPickerScreenState();
}

class _GoogleMapPickerScreenState extends State<_GoogleMapPickerScreen> {
  late LatLng _pickedPosition;
  GoogleMapController? _mapController;

  static final LatLngBounds alaminosBounds = LatLngBounds(
    southwest: const LatLng(16.0800, 119.9000),
    northeast: const LatLng(16.2300, 120.0700),
  );

  @override
  void initState() {
    super.initState();
    _pickedPosition = LatLng(widget.initialLat, widget.initialLng);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pin Location", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: widget.deepForestGreen,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _pickedPosition, zoom: 16.0),
            markers: {
              Marker(
                markerId: const MarkerId('picked'),
                position: _pickedPosition,
                draggable: true,
                onDragEnd: (newPos) => setState(() => _pickedPosition = newPos),
              ),
            },
            cameraTargetBounds: CameraTargetBounds(alaminosBounds),
            minMaxZoomPreference: const MinMaxZoomPreference(11.0, 18.0),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            onMapCreated: (controller) => _mapController = controller,
            onTap: (point) => setState(() => _pickedPosition = point),
          ),
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.vibrantGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                ),
                onPressed: () => Navigator.pop(context, _pickedPosition),
                child: const Text("Confirm Location", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}