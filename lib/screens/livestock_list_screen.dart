import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'details_screen.dart';
import 'notifications_screen.dart';

class LivestockListScreen extends StatefulWidget {
  const LivestockListScreen({super.key});

  @override
  State<LivestockListScreen> createState() => _LivestockListScreenState();
}

class _LivestockListScreenState extends State<LivestockListScreen> with SingleTickerProviderStateMixin {
  String _searchQuery = "";
  String _selectedCategory = "All";

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  final List<String> _categories = [
    "All",
    "Cattle / Cow",
    "Carabao",
    "Swine / Pig",
    "Goat",
    "Sheep",
    "Poultry",
  ];

  final Color _deepForestGreen = const Color(0xFF0A3622);
  final Color _vibrantGreen = const Color(0xFF1B5E20);
  final Color _mintAccent = const Color(0xFF98FF98);
  final Color _softGreenTint = const Color(0xFFE8F5E9);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeOutExpo);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F4),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_deepForestGreen, _vibrantGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_awesome_rounded, color: _mintAccent, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                "Alaminos Trading Hub",
                                style: TextStyle(color: _mintAccent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      "Livestock Marketplace",
                      style: TextStyle(color: Colors.white, fontSize: 28, height: 1.1, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 6))],
                            ),
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: "Search breeds, locations...",
                                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14, fontWeight: FontWeight.w500),
                                prefixIcon: Icon(Icons.search_rounded, color: _vibrantGreen),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          height: 50,
                          width: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 6))],
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: IconButton(
                                  icon: Icon(Icons.notifications_outlined, color: _deepForestGreen, size: 22),
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => NotificationsScreen()),
                                  ),
                                ),
                              ),
                              if (user != null)
                                StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(user.uid)
                                      .collection('notifications')
                                      .where('isRead', isEqualTo: false)
                                      .snapshots(),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                      return const SizedBox.shrink();
                                    }
                                    return Positioned(
                                      top: 10,
                                      right: 10,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        constraints: const BoxConstraints(minWidth: 10, minHeight: 10),
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Container(
                height: 70,
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isSelected = _selectedCategory == category;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10.0),
                      child: ChoiceChip(
                        label: Text(category),
                        selected: isSelected,
                        selectedColor: _vibrantGreen,
                        backgroundColor: Colors.white,
                        showCheckmark: false,
                        elevation: isSelected ? 4 : 0,
                        shadowColor: _vibrantGreen.withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: isSelected ? _vibrantGreen : Colors.green.shade100, width: 1.5),
                        ),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey.shade700,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                        onSelected: (selected) => setState(() => _selectedCategory = category),
                      ),
                    );
                  },
                ),
              ),

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('livestock').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildLoadingGrid();
                    }

                    final docs = snapshot.hasData ? snapshot.data!.docs.where((doc) {
                      final item = doc.data() as Map<String, dynamic>;

                      final name = (item['livestock_name'] ?? item['name'] ?? "").toString().toLowerCase();
                      final category = (item['category'] ?? "").toString().trim();
                      final status = (item['status'] ?? "").toString().trim().toLowerCase();
                      final rawAvailable = item['isAvailable'];

                      final bool isAvailable = status == "available" || status == "approved" || rawAvailable == true;
                      final bool isNotRejected = status != "rejected";

                      final bool matchesCategory = _selectedCategory == "All" ||
                          category.toLowerCase() == _selectedCategory.toLowerCase();

                      return name.contains(_searchQuery) && matchesCategory && isAvailable && isNotRejected;
                    }).toList() : [];

                    if (docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text("No livestock matches your search.", style: TextStyle(color: Colors.grey.shade600, fontSize: 15, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      );
                    }

                    return GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 110),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.58,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final item = doc.data() as Map<String, dynamic>;
                        final String imageUrl = item['imageUrl'] ?? '';
                        final bool isSellerVerified = item['isVerifiedSeller'] ?? false;
                        final String livestockName = item['livestock_name'] ?? item['name'] ?? "Unknown";
                        final String saleType = item['sale_type'] ?? 'per_head';

                        return Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          elevation: 0,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailsScreen(docId: doc.id, item: item))),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: Colors.green.shade50, width: 2),
                                boxShadow: [BoxShadow(color: _deepForestGreen.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 6))],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Stack(
                                      children: [
                                        Positioned.fill(
                                          child: ClipRRect(
                                            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                                            child: imageUrl.isNotEmpty
                                                ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholderIcon())
                                                : _placeholderIcon(),
                                          ),
                                        ),
                                        Positioned(
                                          top: 12,
                                          left: 12,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.95),
                                              borderRadius: BorderRadius.circular(12),
                                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
                                            ),
                                            child: Text(
                                              item['category'] ?? "Livestock",
                                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: _deepForestGreen, letterSpacing: 0.5),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(14.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                livestockName,
                                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: _deepForestGreen),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (isSellerVerified)
                                              const Icon(Icons.verified_rounded, color: Colors.blue, size: 16),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        if (saleType == 'bulk')
                                          Container(
                                            margin: const EdgeInsets.only(bottom: 6),
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(6)),
                                            child: Text(
                                              "Qty: ${item['available_quantity'] ?? 1} units",
                                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                                            ),
                                          ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(color: _softGreenTint, borderRadius: BorderRadius.circular(10)),
                                          child: Text(
                                            "₱${(item['price'] ?? 0).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}",
                                            style: TextStyle(color: _vibrantGreen, fontWeight: FontWeight.w900, fontSize: 13),
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
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingGrid() {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 110),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.58,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 4,
      itemBuilder: (context, index) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.green.shade50, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                ),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: _vibrantGreen, strokeWidth: 2.5),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: 60,
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(4),
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

  Widget _placeholderIcon() => Container(color: Colors.green.shade50, child: Icon(Icons.pets_rounded, size: 36, color: _vibrantGreen.withOpacity(0.5)));
}