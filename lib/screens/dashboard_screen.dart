import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'livestock_list_screen.dart';
import 'messages_screen.dart';
import 'my_listings_screen.dart';
import 'account_screen.dart';
import 'add_listing_screen.dart';
import 'verification_guide_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  static _DashboardScreenState? of(BuildContext context) =>
      context.findAncestorStateOfType<_DashboardScreenState>();

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  void setIndex(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  final List<Widget> _screens = [
    const LivestockListScreen(),
    const MessagesScreen(),
    const MyListingsScreen(),
    const AccountScreen(),
  ];

  Future<void> _checkVerificationAndAddListing() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final verificationStatus = userDoc.data()?['verificationStatus'] ?? 'unverified';

      if (verificationStatus != 'verified') {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text("Verification Required", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0A3622))),
              content: const Text(
                "To ensure secure livestock trading in Alaminos City, posting listings requires ID verification approved by administrators.",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const VerificationGuideScreen()),
                    );
                  },
                  child: const Text("Verify Now", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }
        return;
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddListingScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF8),
      body: Stack(
        children: [
          // Current Active Screen
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),

          // Custom Floating Bottom Navigation Bar
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: Container(
              height: 72,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(36),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(color: Colors.green.shade100, width: 1),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildNavItem(0, Icons.home_outlined, Icons.home_rounded, "Home"),
                        _buildNavItem(1, Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded, "Messages"),
                      ],
                    ),
                  ),
                  const SizedBox(width: 60), // Center gap for FAB
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildNavItem(2, Icons.assignment_outlined, Icons.assignment_rounded, "Listings"),
                        _buildNavItem(3, Icons.person_outline_rounded, Icons.person_rounded, "Account"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Center Floating Action Button (+)
          Positioned(
            left: (screenWidth / 2) - 30,
            bottom: 40,
            child: Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0A3622),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0A3622).withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _checkVerificationAndAddListing,
                  child: const Center(
                    child: Icon(Icons.add_rounded, color: Colors.white, size: 30),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F5E9) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? const Color(0xFF1B5E20) : Colors.grey.shade500,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF1B5E20) : Colors.transparent,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}