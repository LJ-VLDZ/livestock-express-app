import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class FaceCameraScreen extends StatefulWidget {
  final CameraDescription camera;
  const FaceCameraScreen({super.key, required this.camera});

  @override
  State<FaceCameraScreen> createState() => _FaceCameraScreenState();
}

class _FaceCameraScreenState extends State<FaceCameraScreen> with SingleTickerProviderStateMixin {
  late CameraController _controller;
  bool _isProcessing = false;
  String _statusMessage = "Position your face clearly inside the circle";

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  final Color _deepForestGreen = const Color(0xFF0A3622);
  final Color _vibrantGreen = const Color(0xFF1B5E20);

  @override
  void initState() {
    super.initState();
    _initializeCamera();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  Future<void> _initializeCamera() async {
    // Use front-facing camera if available for selfie/facial capture
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    try {
      await _controller.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Camera initialization error: $e");
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _captureFace() async {
    if (_isProcessing || !_controller.value.isInitialized) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = "Processing facial capture...";
    });

    try {
      final XFile image = await _controller.takePicture();
      if (mounted) {
        Navigator.pop(context, image.path);
      }
    } catch (e) {
      debugPrint("Face capture error: $e");
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusMessage = "Capture error occurred. Try again.";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            Positioned.fill(child: CameraPreview(_controller)),
            Container(color: Colors.black.withValues(alpha: 0.5)),

            // Top Status Banner
            Positioned(
              top: 60,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.greenAccent, width: 1.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.face_rounded, color: Colors.greenAccent, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _statusMessage,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Circular Face Guide Frame
            Center(
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.greenAccent, width: 3),
                ),
              ),
            ),

            // Bottom Action Panel
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: Column(
                children: [
                  const Text(
                    "Ensure good lighting and remove sunglasses or hats.",
                    style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _vibrantGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                      ),
                      onPressed: _isProcessing ? null : _captureFace,
                      child: _isProcessing
                          ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                          : const Text(
                        "Capture Selfie",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
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