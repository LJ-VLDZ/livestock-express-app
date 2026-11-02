import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';
import '../utils/format_helper.dart';
import '../services/notification_helper.dart';
import 'chat_room_screen.dart';
import 'seller_profile_screen.dart';

class DetailsScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> item;

  const DetailsScreen({super.key, required this.docId, required this.item});

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> with SingleTickerProviderStateMixin {
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  int _selectedImageIndex = 0;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  final Color _deepForestGreen = const Color(0xFF0A3622);
  final Color _vibrantGreen = const Color(0xFF1B5E20);
  final Color _softGreenTint = const Color(0xFFE8F5E9);
  final Color _mintAccent = const Color(0xFF98FF98);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();

    final String videoUrl = widget.item['videoUrl'] ?? '';
    if (videoUrl.isNotEmpty) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl))
        ..initialize().then((_) {
          if (mounted) {
            setState(() {
              _isVideoInitialized = true;
            });
          }
        });
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _startChatWithSeller() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final String sellerId = widget.item['seller_id'] ?? '';
    if (user.uid == sellerId) {
      _showSnackBar("This is your own livestock listing.", isError: true);
      return;
    }

    String roomId = "${widget.docId}_${user.uid}";
    String livestockName = widget.item['livestock_name'] ?? "Livestock";
    String imageUrl = widget.item['imageUrl'] ?? "";
    num price = widget.item['price'] ?? 0;

    final roomRef = FirebaseFirestore.instance.collection('chat_rooms').doc(roomId);

    await roomRef.set({
      'roomId': roomId,
      'participants': [user.uid, sellerId],
      'livestockId': widget.docId,
      'livestockName': livestockName,
      'imageUrl': imageUrl,
      'price': price,
      'last_message': 'Inquiry regarding $livestockName',
      'last_message_time': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    try {
      final currentUserDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      String buyerName = currentUserDoc.exists ? (currentUserDoc.data()?['name'] ?? 'A buyer') : 'A buyer';

      await NotificationHelper.sendNotification(
        recipientUid: sellerId,
        title: 'New Inquiry! 💬',
        body: '$buyerName is interested in your livestock: $livestockName',
        type: 'inquiry',
      );
    } catch (e) {
      debugPrint("Error sending inquiry notification: $e");
    }

    String sellerName = widget.item['ownerName'] ?? "Trader";
    try {
      final sellerDoc = await FirebaseFirestore.instance.collection('users').doc(sellerId).get();
      if (sellerDoc.exists) {
        sellerName = sellerDoc.data()?['name'] ?? sellerName;
      }
    } catch (_) {}

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatRoomScreen(
            roomId: roomId,
            recipientName: sellerName,
            livestockItem: widget.item,
            docId: widget.docId,
          ),
        ),
      );
    }
  }

  Future<void> _deleteListing(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Listing', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
        content: const Text('Are you sure you want to remove your livestock listing? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('livestock').doc(widget.docId).delete();
      if (mounted) {
        Navigator.pop(context);
        _showSnackBar('Listing deleted successfully.');
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

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: _vibrantGreen),
          const SizedBox(width: 12),
          Text(
            "$label: ",
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.grey.shade700),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'N/A',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _deepForestGreen),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rawPrice = widget.item['price'];
    final double price = rawPrice is int ? rawPrice.toDouble() : (rawPrice ?? 0.0);
    final String ownerName = widget.item['ownerName'] ?? "Unknown";
    final String imageUrl = widget.item['imageUrl'] ?? "";
    final String videoUrl = widget.item['videoUrl'] ?? "";
    final String description = widget.item['description'] ?? "";

    final String listingSellerId = widget.item['seller_id'] ?? "";
    final bool isOwner = _currentUserId != null && _currentUserId == listingSellerId;
    final String saleType = widget.item['sale_type'] ?? 'per_head';

    final List<dynamic> rawImageUrls = widget.item['imageUrls'] ?? [];
    final List<String> images = rawImageUrls.isNotEmpty
        ? rawImageUrls.map((e) => e.toString()).toList()
        : (imageUrl.isNotEmpty ? [imageUrl] : []);

    if (_selectedImageIndex >= images.length) {
      _selectedImageIndex = 0;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF8),
      appBar: AppBar(
        title: Text(widget.item['livestock_name'] ?? "Details", style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: _deepForestGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 260,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: images.isNotEmpty
                      ? Image.network(
                    images[_selectedImageIndex],
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(child: CircularProgressIndicator(color: _vibrantGreen));
                    },
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Icon(Icons.pets_rounded, size: 64, color: Colors.green.shade300),
                    ),
                  )
                      : Center(child: Icon(Icons.pets_rounded, size: 64, color: _vibrantGreen)),
                ),
              ),
              if (images.length > 1) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 70,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: images.length,
                    itemBuilder: (context, index) {
                      final bool isSelected = _selectedImageIndex == index;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedImageIndex = index;
                          });
                        },
                        child: Container(
                          width: 70,
                          height: 70,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? _vibrantGreen : Colors.green.shade200,
                              width: isSelected ? 2.5 : 1.5,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(images[index], fit: BoxFit.cover),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              if (videoUrl.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text("Live Video Preview", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF111827))),
                const SizedBox(height: 10),
                Container(
                  height: 220,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: _isVideoInitialized && _videoController != null
                        ? Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox.expand(
                          child: FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: _videoController!.value.size.width,
                              height: _videoController!.value.size.height,
                              child: VideoPlayer(_videoController!),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _videoController!.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                            size: 64,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                          onPressed: () {
                            setState(() {
                              _videoController!.value.isPlaying
                                  ? _videoController!.pause()
                                  : _videoController!.play();
                            });
                          },
                        ),
                      ],
                    )
                        : Center(child: CircularProgressIndicator(color: _mintAccent)),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.item['livestock_name'] ?? "Unknown",
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: _deepForestGreen),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _softGreenTint,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                widget.item['category'] ?? 'Category',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _vibrantGreen),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: saleType == 'bulk' ? Colors.amber.shade100 : Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                saleType == 'bulk' ? 'Bulk / Batch' : 'Per Head',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: saleType == 'bulk' ? Colors.amber.shade900 : Colors.blue.shade800),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Text(
                    "₱${FormatHelper.formatCurrency(price)}",
                    style: TextStyle(fontSize: 22, color: _vibrantGreen, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Seller Storefront Card (Disabled for own listing)
              InkWell(
                onTap: () {
                  if (listingSellerId.isNotEmpty && !isOwner) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SellerProfileScreen(
                          sellerId: listingSellerId,
                          sellerName: ownerName,
                        ),
                      ),
                    );
                  } else if (isOwner) {
                    _showSnackBar("This is your own listing store profile.");
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.green.shade100),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: _softGreenTint,
                        child: Icon(Icons.storefront_rounded, color: _vibrantGreen),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(isOwner ? "Listed by You" : "Listed by (Tap to view storefront)", style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                            Text(
                              isOwner ? "You (Owner)" : ownerName,
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _deepForestGreen),
                            ),
                          ],
                        ),
                      ),
                      if (!isOwner)
                        Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey.shade400),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              const Text("Specifications", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF111827))),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.shade100),
                ),
                child: Column(
                  children: [
                    _buildDetailRow(Icons.sell_outlined, "Sale Type", saleType == 'bulk' ? 'Bulk / Batch' : 'Per Head'),
                    if (saleType == 'bulk')
                      _buildDetailRow(Icons.inventory_2_outlined, "Available Quantity", "${widget.item['available_quantity'] ?? 1} units"),
                    _buildDetailRow(Icons.male_rounded, "Sex", widget.item['sex'] ?? ''),
                    _buildDetailRow(Icons.color_lens_outlined, "Color", widget.item['color'] ?? ''),
                    _buildDetailRow(Icons.scale_rounded, "Est. Weight", "${widget.item['weight'] ?? ''} kg"),
                    _buildDetailRow(Icons.height_rounded, "Est. Height", "${widget.item['height'] ?? ''} cm"),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text("Description", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF111827))),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.shade100),
                ),
                child: Text(
                  description.isNotEmpty ? description : "No description provided for this livestock.",
                  style: TextStyle(fontSize: 14, height: 1.5, color: Colors.grey.shade800),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, -4)),
            ],
          ),
          child: SizedBox(
            height: 56,
            child: isOwner
                ? Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text("Delete", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    onPressed: () => _deleteListing(context),
                  ),
                ),
              ],
            )
                : SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _vibrantGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 4,
                  shadowColor: _vibrantGreen.withValues(alpha: 0.4),
                ),
                icon: const Icon(Icons.handshake_rounded, size: 20),
                label: const Text("Message / Make Offer", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                onPressed: _startChatWithSeller,
              ),
            ),
          ),
        ),
      ),
    );
  }
}