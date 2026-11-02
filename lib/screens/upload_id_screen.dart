import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dashboard_screen.dart';
import 'id_camera_screen.dart';
import 'face_camera_screen.dart';
import 'package:livestock_app/services/cloudinary_service.dart';

class UploadIDScreen extends StatefulWidget {
  final String idType;
  const UploadIDScreen({super.key, required this.idType});

  @override
  State<UploadIDScreen> createState() => _UploadIDScreenState();
}

class _UploadIDScreenState extends State<UploadIDScreen> with SingleTickerProviderStateMixin {
  File? _frontImage;
  File? _backImage;
  File? _faceImage;
  bool _frontCaptured = false;
  bool _backCaptured = false;
  bool _isUploading = false;
  String _extractedInfoText = "OCR ID Scanner Ready";

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

  Future<void> _handleImageSelection(bool isFront) async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        final String? path = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => IDCameraScreen(camera: cameras.first)),
        );
        if (path != null) {
          setState(() {
            if (isFront) {
              _frontImage = File(path);
              _frontCaptured = true;
            } else {
              _backImage = File(path);
              _backCaptured = true;
            }
          });

          if (isFront) {
            _parseIDCard(_frontImage!);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Camera error: $e', isError: true);
      }
    }
  }

  Future<void> _handleFaceSelection() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        CameraDescription selectedCamera = cameras.first;
        for (var camera in cameras) {
          if (camera.lensDirection == CameraLensDirection.front) {
            selectedCamera = camera;
            break;
          }
        }

        final String? path = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => FaceCameraScreen(camera: selectedCamera)),
        );
        if (path != null) {
          setState(() {
            _faceImage = File(path);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Face camera error: $e', isError: true);
      }
    }
  }

  Future<String?> _parseIDCard(File imageFile) async {
    setState(() {
      _extractedInfoText = "Scanning ID text for Alaminos address...";
    });

    final inputImage = InputImage.fromFile(imageFile);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      String fullText = recognizedText.text;
      String detectedBarangay = "";

      for (String barangay in _alaminosBarangays) {
        if (fullText.toLowerCase().contains(barangay.toLowerCase())) {
          detectedBarangay = barangay;
          break;
        }
      }

      if (detectedBarangay.isNotEmpty) {
        setState(() {
          _extractedInfoText = "Detected Barangay: $detectedBarangay (Auto-matched!)";
        });
        return detectedBarangay;
      } else {
        setState(() {
          _extractedInfoText = "ID scanned successfully. Address verification pending review.";
        });
      }
    } catch (e) {
      debugPrint("OCR Error: $e");
      setState(() {
        _extractedInfoText = "ID captured successfully.";
      });
    } finally {
      textRecognizer.close();
    }
    return null;
  }

  Future<void> _uploadID() async {
    if (_frontImage == null || _backImage == null || _faceImage == null) return;
    setState(() => _isUploading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('No logged-in user found.');
      final uid = currentUser.uid;

      String? parsedBarangay = await _parseIDCard(_frontImage!);

      final String? frontUrl = await CloudinaryService.uploadImage(_frontImage!);
      final String? backUrl = await CloudinaryService.uploadImage(_backImage!);
      final String? faceUrl = await CloudinaryService.uploadImage(_faceImage!);

      if (frontUrl == null || backUrl == null || faceUrl == null) {
        throw Exception('Failed to upload verification assets to Cloudinary storage.');
      }

      Map<String, dynamic> updateData = {
        'idFrontUrl': frontUrl,
        'idBackUrl': backUrl,
        'faceUrl': faceUrl,
        'profileImageUrl': faceUrl, // Set face capture as profile picture
        'idUrl': frontUrl,
        'idType': widget.idType,
        'verificationStatus': 'pending',
        'verifiedAt': FieldValue.serverTimestamp(),
      };

      if (parsedBarangay != null) {
        updateData['barangay'] = parsedBarangay;
        updateData['extractedFromId'] = true;
      }

      await FirebaseFirestore.instance.collection('users').doc(uid).set(updateData, SetOptions(merge: true));
      await currentUser.updatePhotoURL(faceUrl);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
        _showSnackBar('Verification Assets Submitted Successfully!');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
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

  Widget _buildImageSlot(String label, File? image, VoidCallback onTapAction) {
    return GestureDetector(
      onTap: onTapAction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _deepForestGreen)),
          const SizedBox(height: 8),
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: image != null ? _vibrantGreen : Colors.green.shade200,
                width: image != null ? 2 : 1.5,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: image == null
                ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _softGreenTint,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.camera_alt_outlined, size: 26, color: _vibrantGreen),
                ),
                const SizedBox(height: 10),
                Text("Tap to capture $label", style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            )
                : ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(image, fit: BoxFit.cover),
                  Container(
                    color: Colors.black.withValues(alpha: 0.35),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_rounded, color: Colors.white, size: 36),
                        SizedBox(height: 4),
                        Text("Captured Successfully", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        Text("Tap to retake", style: TextStyle(color: Colors.white70, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF8),
      appBar: AppBar(
        title: Text("Verify ${widget.idType}", style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: _deepForestGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Complete the ID capture (strict anti-blur checks) and blink-verified facial scan for your ${widget.idType}.",
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.4),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _softGreenTint,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.document_scanner_rounded, color: _vibrantGreen),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _extractedInfoText,
                        style: TextStyle(color: _deepForestGreen, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildImageSlot("Front Side ID", _frontImage, () => _handleImageSelection(true)),
              const SizedBox(height: 20),
              if (_frontCaptured) ...[
                _buildImageSlot("Back Side ID", _backImage, () => _handleImageSelection(false)),
                const SizedBox(height: 20),
              ],
              if (_backCaptured) ...[
                _buildImageSlot("Facial Verification (Selfie PFP)", _faceImage, _handleFaceSelection),
                const SizedBox(height: 24),
              ],
              SizedBox(
                width: double.infinity,
                height: 54,
                child: _isUploading
                    ? Center(child: CircularProgressIndicator(color: _vibrantGreen, strokeWidth: 3))
                    : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _vibrantGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    shadowColor: _vibrantGreen.withValues(alpha: 0.4),
                  ),
                  onPressed: (_frontImage != null && _backImage != null && _faceImage != null) ? _uploadID : null,
                  child: const Text("Submit Verification Assets", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}