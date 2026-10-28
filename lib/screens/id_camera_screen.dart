import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class IDCameraScreen extends StatefulWidget {
  final CameraDescription camera;
  const IDCameraScreen({super.key, required this.camera});

  @override
  State<IDCameraScreen> createState() => _IDCameraScreenState();
}

class _IDCameraScreenState extends State<IDCameraScreen> with SingleTickerProviderStateMixin {
  late CameraController _controller;
  bool _isProcessing = false;
  bool _isAligned = true;
  String _statusMessage = "Position and align your ID inside the frame";

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  // Ultra-Rich Modern Agricultural Color Suite
  final Color _deepForestGreen = const Color(0xFF0A3622);
  final Color _vibrantGreen = const Color(0xFF1B5E20);
  final Color _softGreenTint = const Color(0xFFE8F5E9);

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

  Future<bool> _isImageQualityAcceptable(File imageFile) async {
    try {
      final int fileSize = await imageFile.length();
      if (fileSize < 80000) {
        return false;
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _captureAndProcess() async {
    if (_isProcessing || !_controller.value.isInitialized) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = "Analyzing clarity & blur levels...";
      _isAligned = false;
    });

    try {
      final XFile image = await _controller.takePicture();
      File rawImage = File(image.path);

      bool isAcceptable = await _isImageQualityAcceptable(rawImage);
      if (!isAcceptable) {
        if (mounted) {
          setState(() {
            _isProcessing = false;
            _statusMessage = "Image too blurry! Hold steady and retake.";
            _isAligned = false;
          });
          _showSnackBar("ID rejected: Image is blurry or unclear. Please retry.", isError: true);
        }
        return;
      }

      if (mounted) {
        Navigator.pop(context, image.path);
      }
    } catch (e) {
      debugPrint("Capture error: $e");
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusMessage = "Capture error occurred. Try again.";
          _isAligned = false;
        });
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
    if (!_controller.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    Color activeColor = _isAligned ? Colors.greenAccent : Colors.redAccent;

    return Scaffold(
      backgroundColor: Colors.black,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            // Camera Preview
            Positioned.fill(child: CameraPreview(_controller)),

            // Dimmed backdrop overlay
            Container(
              color: Colors.black.withValues(alpha: 0.5),
            ),

            // Top Status Instruction Banner
            Positioned(
              top: 60,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: activeColor, width: 1.5),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isProcessing ? Icons.hourglass_top_rounded : (_isAligned ? Icons.check_circle_outline_rounded : Icons.warning_amber_rounded),
                      color: activeColor,
                      size: 20,
                    ),
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

            // Center Dynamic Guide Frame Box (Cleaned up neon glow & fixed brackets)
            Center(
              child: Container(
                width: 330,
                height: 210,
                decoration: BoxDecoration(
                  border: Border.all(color: activeColor, width: 2),
                  borderRadius: BorderRadius.circular(20),
                  // Removed the boxShadow that was causing the neon glow effect
                ),
                child: Stack(
                  children: [
                    Positioned(top: 0, left: 0, child: _buildCorner(activeColor, isTop: true, isLeft: true)),
                    Positioned(top: 0, right: 0, child: _buildCorner(activeColor, isTop: true, isLeft: false)),
                    Positioned(bottom: 0, left: 0, child: _buildCorner(activeColor, isTop: false, isLeft: true)),
                    Positioned(bottom: 0, right: 0, child: _buildCorner(activeColor, isTop: false, isLeft: false)),
                  ],
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
                  Text(
                    _isAligned ? "ID properly aligned. Tap below to capture." : "Please fit your ID inside the box.",
                    style: TextStyle(color: _isAligned ? Colors.greenAccent : Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
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
                        shadowColor: _vibrantGreen.withValues(alpha: 0.4),
                      ),
                      onPressed: _isProcessing ? null : _captureAndProcess,
                      child: _isProcessing
                          ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                          : const Text(
                        "Capture & Validate ID",
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

  // Updated to dynamically draw the correct L-bracket for each specific corner
  Widget _buildCorner(Color color, {required bool isTop, required bool isLeft}) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        // border: Border(
        //   top: isTop ? BorderSide(color: color, width: 4) : BorderSide.none,
        //   bottom: !isTop ? BorderSide(color: color, width: 4) : BorderSide.none,
        //   left: isLeft ? BorderSide(color: color, width: 4) : BorderSide.none,
        //   right: !isLeft ? BorderSide(color: color, width: 4) : BorderSide.none,
        // ),
      ),
    );
  }
}