import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:livestock_app/services/cloudinary_service.dart';

class AddListingScreen extends StatefulWidget {
  const AddListingScreen({super.key});

  @override
  State<AddListingScreen> createState() => _AddListingScreenState();
}

class _AddListingScreenState extends State<AddListingScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _colorController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();

  String? _selectedCategory;
  String? _selectedSex;
  String _selectedBarangay = 'Poblacion';

  List<File> _livestockImages = [];
  File? _certificateImage;

  bool _isSubmitting = false;
  String _verificationStatus = 'loading';

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  final List<String> _categories = [
    'Cattle / Cow', 'Carabao', 'Swine / Pig', 'Goat', 'Sheep', 'Poultry',
  ];
  final List<String> _sexOptions = ['Male', 'Female'];
  final List<String> _alaminosBarangays = [
    'Poblacion', 'Lucap', 'Alos', 'San Vicente', 'Telbang', 'Bolaney'
  ];

  final Color _deepForestGreen = const Color(0xFF0A3622);
  final Color _vibrantGreen = const Color(0xFF1B5E20);
  final Color _softGreenTint = const Color(0xFFE8F5E9);

  @override
  void initState() {
    super.initState();
    _checkUserVerification();

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
    _descController.dispose();
    _priceController.dispose();
    _colorController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _checkUserVerification() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && mounted) {
          setState(() {
            _verificationStatus = (doc.data() as Map<String, dynamic>)['verificationStatus'] ?? 'unverified';
          });
        }
      } catch (e) {
        if (mounted) setState(() => _verificationStatus = 'unverified');
      }
    } else {
      if (mounted) setState(() => _verificationStatus = 'unverified');
    }
  }

  Future<void> _pickLivestockImage() async {
    if (_livestockImages.length >= 5) {
      _showSnackBar('You can upload a maximum of 5 pictures.', isError: true);
      return;
    }

    final ImagePicker picker = ImagePicker();
    try {
      final XFile? photo = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
      if (photo != null) {
        setState(() {
          _livestockImages.add(File(photo.path));
        });
      }
    } catch (e) {
      if (mounted) _showSnackBar('Camera error: $e', isError: true);
    }
  }

  Future<void> _pickCertificate() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (image != null) setState(() => _certificateImage = File(image.path));
    } catch (e) {
      if (mounted) _showSnackBar('Error picking certificate: $e', isError: true);
    }
  }

  Future<void> _submitData() async {
    if (_isSubmitting) return;

    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory == null) {
      _showSnackBar('Please select a livestock category.', isError: true);
      return;
    }

    if (_livestockImages.isEmpty) {
      _showSnackBar('Please capture at least 1 photo of the livestock.', isError: true);
      return;
    }

    if (_certificateImage == null) {
      _showSnackBar('Please upload your Certificate of Ownership for admin review.', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() => _isSubmitting = false);
      return;
    }

    try {
      List<String> uploadedImageUrls = [];
      for (File imgFile in _livestockImages) {
        String? url = await CloudinaryService.uploadImage(imgFile);
        if (url != null) {
          uploadedImageUrls.add(url);
        }
      }

      if (uploadedImageUrls.isEmpty) {
        throw Exception('Failed to upload livestock photos to cloud storage.');
      }

      String? certUrl = await CloudinaryService.uploadImage(_certificateImage!);
      if (certUrl == null) throw Exception('Failed to upload ownership certificate to cloud storage.');

      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      String ownerName = (userDoc.exists && userDoc.data() != null)
          ? (userDoc.data() as Map<String, dynamic>)['name'] ?? "User"
          : "User";

      final livestockName = _nameController.text.trim();
      final category = _selectedCategory ?? 'Livestock';

      WriteBatch batch = FirebaseFirestore.instance.batch();

      DocumentReference livestockRef = FirebaseFirestore.instance.collection('livestock').doc();
      batch.set(livestockRef, {
        'livestock_name': livestockName,
        'category': category,
        'breed': livestockName,
        'sex': _selectedSex ?? 'Not Specified',
        'color': _colorController.text.trim(),
        'weight': _weightController.text.trim(),
        'height': _heightController.text.trim(),
        'description': _descController.text.trim(),
        'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
        'sellerBarangay': _selectedBarangay, // Stored for distance calculation
        'imageUrl': uploadedImageUrls.first,
        'imageUrls': uploadedImageUrls,
        'ownershipCertificateUrl': certUrl,
        'status': 'Pending',
        'isAvailable': false,
        'isVerifiedSeller': _verificationStatus == 'verified',
        'seller_id': user.uid,
        'ownerEmail': user.email ?? '',
        'ownerName': ownerName,
        'createdAt': FieldValue.serverTimestamp(),
      });

      DocumentReference logRef = FirebaseFirestore.instance.collection('activity_logs').doc();
      batch.set(logRef, {
        'actorType': 'user',
        'user_name': ownerName,
        'user_email': user.email ?? '',
        'user_id': user.uid,
        'target_user_id': livestockRef.id,
        'action': 'Listed new livestock: $livestockName (Category:$category)',
        'timestamp': DateTime.now().toIso8601String(),
      });

      await batch.commit();

      if (mounted) {
        _showSnackBar('Listing submitted for admin verification!');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) _showSnackBar('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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

  Widget _buildRestrictedView() {
    bool isPending = _verificationStatus == 'pending';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isPending ? Colors.orange.shade50 : Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPending ? Icons.hourglass_empty_rounded : Icons.gpp_maybe_outlined,
                size: 64,
                color: isPending ? Colors.orange.shade700 : Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isPending ? "Verification Pending" : "Account Not Verified",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _deepForestGreen),
            ),
            const SizedBox(height: 10),
            Text(
              isPending
                  ? "Your ID is currently being reviewed by administrators. You can post listings as soon as your account is approved."
                  : "You must verify your identity before you can post livestock. This ensures a secure marketplace for all farmers and buyers in Alaminos City.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
            ),
            const SizedBox(height: 32),
            if (!isPending)
              SizedBox(
                width: 200,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _vibrantGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Return", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF8),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: _deepForestGreen),
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text("New Livestock Listing", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _deepForestGreen)),
                  ],
                ),
              ),

              Expanded(
                child: _verificationStatus == 'loading'
                    ? Center(child: CircularProgressIndicator(color: _vibrantGreen))
                    : _verificationStatus != 'verified'
                    ? _buildRestrictedView()
                    : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.verified_user_outlined, color: Colors.amber.shade800, size: 22),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "To ensure trading authenticity, gallery uploads are restricted for livestock photos. Please capture up to 5 photos using your camera.",
                                  style: TextStyle(color: Colors.brown.shade800, fontSize: 13, height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Livestock Photos Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildFieldLabel("LIVESTOCK PHOTOS (${_livestockImages.length}/5)"),
                            if (_livestockImages.isNotEmpty)
                              Text(
                                "First photo is primary",
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 110,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            children: [
                              ..._livestockImages.asMap().entries.map((entry) {
                                int index = entry.key;
                                File img = entry.value;
                                return Container(
                                  width: 110,
                                  height: 110,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: index == 0 ? _vibrantGreen : Colors.green.shade200, width: index == 0 ? 2 : 1),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Image.file(img, fit: BoxFit.cover),
                                        if (index == 0)
                                          Positioned(
                                            bottom: 0,
                                            left: 0,
                                            right: 0,
                                            child: Container(
                                              color: _vibrantGreen.withOpacity(0.8),
                                              padding: const EdgeInsets.symmetric(vertical: 2),
                                              child: const Text(
                                                "Primary",
                                                textAlign: TextAlign.center,
                                                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          child: GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _livestockImages.removeAt(index);
                                              });
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                              child: const Icon(Icons.close, size: 14, color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),

                              if (_livestockImages.length < 5)
                                GestureDetector(
                                  onTap: _pickLivestockImage,
                                  child: Container(
                                    width: 110,
                                    height: 110,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.green.shade300, style: BorderStyle.solid, width: 1.5),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_a_photo_rounded, color: _vibrantGreen, size: 28),
                                        const SizedBox(height: 6),
                                        Text(
                                          _livestockImages.isEmpty ? "Add Photo" : "Add (${5 - _livestockImages.length} left)",
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _deepForestGreen),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Ownership Certificate Upload Section
                        _buildFieldLabel("PROOF OF OWNERSHIP / CERTIFICATE (REQUIRED)"),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: _pickCertificate,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _certificateImage != null ? _vibrantGreen : Colors.green.shade200,
                                width: _certificateImage != null ? 2 : 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(shape: BoxShape.circle, color: _softGreenTint),
                                  child: Icon(Icons.description_outlined, color: _vibrantGreen, size: 22),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _certificateImage != null ? "Certificate Attached" : "Upload Ownership Document",
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _deepForestGreen),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _certificateImage != null ? "Tap to change file" : "Private • Only visible to administrators",
                                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_certificateImage != null)
                                  Icon(Icons.check_circle, color: _vibrantGreen, size: 22),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        Text("Animal Specifications", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _deepForestGreen)),
                        const SizedBox(height: 16),

                        _buildFieldLabel("CATEGORY"),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          decoration: _inputDecoration(hint: "Select category"),
                          items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                          onChanged: (val) => setState(() => _selectedCategory = val),
                          validator: (val) => val == null ? "Please select a category" : null,
                        ),
                        const SizedBox(height: 16),

                        _buildFieldLabel("SPECIFIC BREED / NAME"),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _nameController,
                          decoration: _inputDecoration(hint: 'e.g. Brahman, Landrace, Native Goat'),
                          validator: (val) => val == null || val.trim().isEmpty ? "Please enter breed or name" : null,
                        ),
                        const SizedBox(height: 16),

                        // Seller Barangay Location Picker
                        _buildFieldLabel("SELLER BARANGAY (ALAMINOS CITY)"),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _selectedBarangay,
                          decoration: _inputDecoration(hint: "Select origin barangay"),
                          items: _alaminosBarangays.map((b) => DropdownMenuItem(value: b, child: Text("Brgy. $b"))).toList(),
                          onChanged: (val) => setState(() => _selectedBarangay = val ?? 'Poblacion'),
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildFieldLabel("SEX"),
                                  const SizedBox(height: 6),
                                  DropdownButtonFormField<String>(
                                    value: _selectedSex,
                                    decoration: _inputDecoration(hint: "Select sex"),
                                    items: _sexOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                                    onChanged: (val) => setState(() => _selectedSex = val),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildFieldLabel("COLOR / MARKINGS"),
                                  const SizedBox(height: 6),
                                  TextFormField(controller: _colorController, decoration: _inputDecoration(hint: 'e.g. Brown & White')),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildFieldLabel("EST. WEIGHT (KG)"),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _weightController,
                                    keyboardType: TextInputType.number,
                                    decoration: _inputDecoration(hint: '0'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildFieldLabel("EST. HEIGHT (CM)"),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _heightController,
                                    keyboardType: TextInputType.number,
                                    decoration: _inputDecoration(hint: '0'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        _buildFieldLabel("DESCRIPTION / HEALTH DETAILS"),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _descController,
                          maxLines: 3,
                          decoration: _inputDecoration(hint: 'Enter vaccination records, health status, or notes...'),
                        ),
                        const SizedBox(height: 16),

                        _buildFieldLabel("ASKING PRICE (₱)"),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: _inputDecoration(hint: '0.00').copyWith(fillColor: _softGreenTint),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return "Please enter a price";
                            if (double.tryParse(val.trim()) == null) return "Please enter a valid amount";
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),

                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: _isSubmitting
                              ? Center(child: CircularProgressIndicator(color: _vibrantGreen, strokeWidth: 3))
                              : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _vibrantGreen,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 4,
                              shadowColor: _vibrantGreen.withOpacity(0.4),
                            ),
                            onPressed: _submitData,
                            child: const Text('Publish Listing', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade700, letterSpacing: 0.8));
  }

  InputDecoration _inputDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.green.shade200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.green.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: _vibrantGreen, width: 2)),
    );
  }
}