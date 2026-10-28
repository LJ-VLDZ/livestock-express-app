import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/format_helper.dart';
import 'chat_room_screen.dart';

class DetailsScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> item;

  const DetailsScreen({super.key, required this.docId, required this.item});

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> with SingleTickerProviderStateMixin {
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  final Color _deepForestGreen = const Color(0xFF0A3622);
  final Color _vibrantGreen = const Color(0xFF1B5E20);
  final Color _softGreenTint = const Color(0xFFE8F5E9);

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

  void _showEditDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController(text: widget.item['livestock_name'] ?? '');
    final TextEditingController priceController = TextEditingController(text: (widget.item['price'] ?? 0).toString());
    final TextEditingController descController = TextEditingController(text: widget.item['description'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Edit Listing", style: TextStyle(fontWeight: FontWeight.bold, color: _deepForestGreen)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Name / Breed',
                  labelStyle: TextStyle(color: Colors.grey.shade600),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: _vibrantGreen, width: 2)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                decoration: InputDecoration(
                  labelText: 'Price (₱)',
                  labelStyle: TextStyle(color: Colors.grey.shade600),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: _vibrantGreen, width: 2)),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(color: Colors.grey.shade600),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: _vibrantGreen, width: 2)),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _vibrantGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              try {
                await FirebaseFirestore.instance.collection('livestock').doc(widget.docId).update({
                  'livestock_name': nameController.text.trim(),
                  'price': double.tryParse(priceController.text.trim()) ?? 0,
                  'description': descController.text.trim(),
                });

                if (context.mounted) {
                  Navigator.pop(context);
                  Navigator.pop(context);
                  _showSnackBar('Listing updated successfully!');
                }
              } catch (e) {
                if (context.mounted) {
                  _showSnackBar('Error updating: $e', isError: true);
                }
              }
            },
            child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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
    final String description = widget.item['description'] ?? "";

    final String listingSellerId = widget.item['seller_id'] ?? "";
    final bool isOwner = _currentUserId != null && _currentUserId == listingSellerId;

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
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                    imageUrl,
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
              Container(
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
                      child: Icon(Icons.person_outline_rounded, color: _vibrantGreen),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Listed by", style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                        Text(
                          isOwner ? "You (Owner)" : ownerName,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _deepForestGreen),
                        ),
                      ],
                    ),
                  ],
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
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _vibrantGreen,
                      side: BorderSide(color: _vibrantGreen, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text("Edit", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    onPressed: () => _showEditDialog(context),
                  ),
                ),
                const SizedBox(width: 8),
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