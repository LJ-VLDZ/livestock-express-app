import 'package:flutter/material.dart';
import 'upload_id_screen.dart';

class VerificationGuideScreen extends StatefulWidget {
  const VerificationGuideScreen({super.key});

  @override
  State<VerificationGuideScreen> createState() => _VerificationGuideScreenState();
}

class _VerificationGuideScreenState extends State<VerificationGuideScreen> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String? _selectedIdType;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  // Ultra-Rich Modern Agricultural Color Suite
  final Color _deepForestGreen = const Color(0xFF0A3622);
  final Color _vibrantGreen = const Color(0xFF1B5E20);
  final Color _softGreenTint = const Color(0xFFE8F5E9);

  final List<String> _idTypes = [
    'Driver\'s License',
    'Passport',
    'Voter\'s ID',
    'National ID'
  ];

  final List<Map<String, dynamic>> _guidePages = [
    {
      "icon": Icons.credit_card_rounded,
      "title": "Prepare Your ID",
      "desc": "Make sure your official government or school ID is valid and ready.",
      "color": Colors.blueAccent
    },
    {
      "icon": Icons.wb_sunny_rounded,
      "title": "Clear Lighting",
      "desc": "Find a well-lit area to avoid shadows or glare on the card surface.",
      "color": Colors.orangeAccent
    },
    {
      "icon": Icons.camera_front_rounded,
      "title": "Align & Capture",
      "desc": "Center your ID clearly inside the live camera frame to proceed.",
      "color": const Color(0xFF1B5E20)
    },
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
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF8),
      appBar: AppBar(
        title: const Text("Verification Guide", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: _deepForestGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Horizontal Scrolling Guide Pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (int page) => setState(() => _currentPage = page),
                itemCount: _guidePages.length,
                itemBuilder: (context, index) {
                  final pageItem = _guidePages[index];
                  final Color itemColor = pageItem["color"];

                  return Padding(
                    padding: const EdgeInsets.all(28.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: itemColor.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            pageItem["icon"],
                            size: 68,
                            color: itemColor,
                          ),
                        ),
                        const SizedBox(height: 36),
                        Text(
                          pageItem["title"],
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: _deepForestGreen,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          pageItem["desc"],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Page Indicator Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _guidePages.length,
                    (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: _currentPage == index ? 24 : 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index ? _vibrantGreen : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action Area: Dropdown on last page, Next button otherwise
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: _currentPage == _guidePages.length - 1
                  ? Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedIdType,
                    decoration: InputDecoration(
                      labelText: "Select Valid ID Type",
                      labelStyle: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      prefixIcon: Icon(Icons.badge_outlined, color: _vibrantGreen, size: 20),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.green.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.green.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: _vibrantGreen, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    items: _idTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                    onChanged: (val) => setState(() => _selectedIdType = val),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _vibrantGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        shadowColor: _vibrantGreen.withValues(alpha: 0.4),
                      ),
                      onPressed: _selectedIdType == null
                          ? null
                          : () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => UploadIDScreen(idType: _selectedIdType!)),
                        );
                      },
                      child: const Text("Proceed to Capture", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    ),
                  ),
                ],
              )
                  : SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _vibrantGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    shadowColor: _vibrantGreen.withValues(alpha: 0.4),
                  ),
                  onPressed: () => _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                  child: const Text("Next Step", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}