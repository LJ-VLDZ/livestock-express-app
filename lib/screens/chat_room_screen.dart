import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/format_helper.dart';
import '../services/notification_helper.dart';
import 'checkout_screen.dart';

class ChatRoomScreen extends StatefulWidget {
  final String roomId;
  final String recipientName;
  final Map<String, dynamic> livestockItem;
  final String docId;

  const ChatRoomScreen({
    super.key,
    required this.roomId,
    required this.recipientName,
    required this.livestockItem,
    required this.docId,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  final Color _deepForestGreen = const Color(0xFF0A3622);
  final Color _vibrantGreen = const Color(0xFF1B5E20);
  final Color _softGreenTint = const Color(0xFFE8F5E9);

  Map<String, dynamic>? _roomData;
  late bool _isSeller;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _isSeller = _currentUser?.uid == widget.livestockItem['seller_id'];
    _fetchRoomDetails();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  Future<void> _fetchRoomDetails() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('chat_rooms').doc(widget.roomId).get();
      if (doc.exists && mounted) {
        setState(() {
          _roomData = doc.data();
        });
      }
    } catch (e) {
      debugPrint("Error fetching room: $e");
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage({String text = '', String type = 'text', double? offerAmount}) async {
    final messageText = text.isNotEmpty ? text.trim() : _messageController.text.trim();
    final user = _currentUser;

    if ((messageText.isEmpty && type == 'text') || user == null) return;

    if (type == 'text') _messageController.clear();

    try {
      final Map<String, dynamic> messageData = {
        'senderId': user.uid,
        'text': messageText,
        'type': type,
        'timestamp': FieldValue.serverTimestamp(),
      };

      if (type == 'offer') {
        messageData['offerAmount'] = offerAmount;
        messageData['offerStatus'] = 'pending';
      }

      await FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(widget.roomId)
          .collection('messages')
          .add(messageData);

      await FirebaseFirestore.instance.collection('chat_rooms').doc(widget.roomId).update({
        'last_message': type == 'offer' ? 'Made an offer: ₱${FormatHelper.formatCurrency(offerAmount ?? 0)}' : messageText,
        'last_message_time': FieldValue.serverTimestamp(),
      });

      // Automatically push a notification to the chat recipient using our helper
      List<dynamic> participants = _roomData?['participants'] ?? [user.uid, widget.livestockItem['seller_id']];
      String recipientUid = participants.firstWhere((id) => id != user.uid, orElse: () => widget.livestockItem['seller_id'] ?? '');

      if (recipientUid.isNotEmpty) {
        await NotificationHelper.sendNotification(
          recipientUid: recipientUid,
          title: type == 'offer' ? "New Price Offer Received" : "New Message from ${widget.recipientName}",
          body: type == 'offer' ? "Offered ₱${FormatHelper.formatCurrency(offerAmount ?? 0)}" : messageText,
          type: type == 'offer' ? 'offer' : 'message',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red.shade700),
        );
      }
    }
  }

  void _showMakeOfferDialog() {
    final TextEditingController offerController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Make an Offer", style: TextStyle(fontWeight: FontWeight.bold, color: _deepForestGreen)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Propose a new price for ${widget.livestockItem['livestock_name']}", style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            TextField(
              controller: offerController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Offer Amount (₱)",
                prefixIcon: Icon(Icons.payments_outlined, color: _vibrantGreen),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: _vibrantGreen, width: 2)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _vibrantGreen, foregroundColor: Colors.white),
            onPressed: () {
              final double? amount = double.tryParse(offerController.text.trim());
              if (amount != null && amount > 0) {
                Navigator.pop(context);
                _sendMessage(
                  text: 'I would like to offer ₱${FormatHelper.formatCurrency(amount)}',
                  type: 'offer',
                  offerAmount: amount,
                );
              }
            },
            child: const Text("Submit Offer"),
          ),
        ],
      ),
    );
  }

  Future<void> _updateOfferStatus(String messageId, String newStatus, double amount) async {
    try {
      await FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(widget.roomId)
          .collection('messages')
          .doc(messageId)
          .update({'offerStatus': newStatus});

      if (newStatus == 'accepted') {
        await FirebaseFirestore.instance.collection('livestock').doc(widget.docId).update({
          'isAvailable': false,
          'status': 'Reserved',
        });

        await _sendMessage(text: "I have accepted your offer of ₱${FormatHelper.formatCurrency(amount)}.");
      } else {
        await _sendMessage(text: "I have declined your offer of ₱${FormatHelper.formatCurrency(amount)}.");
      }
    } catch (e) {
      debugPrint("Error updating offer: $e");
    }
  }

  void _proceedToCheckout(double acceptedPrice) {
    Map<String, dynamic> negotiatedItem = Map.from(widget.livestockItem);
    negotiatedItem['price'] = acceptedPrice;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(
          listingData: negotiatedItem,
          listingId: widget.docId,
        ),
      ),
    );
  }

  Widget _buildQuickReplies() {
    final List<String> quickReplies = [
      "Is this still available?",
      "On my way!",
      "Can you offer a discount?",
      "Let's meet at the barangay hall.",
      "Is the health clearance ready?",
    ];

    return Container(
      height: 42,
      margin: const EdgeInsets.only(bottom: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: quickReplies.length,
        itemBuilder: (context, index) {
          String reply = quickReplies[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              backgroundColor: Colors.green.shade50,
              side: BorderSide(color: Colors.green.shade200),
              label: Text(
                reply,
                style: TextStyle(color: _vibrantGreen, fontSize: 11, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                _messageController.text = reply;
                _sendMessage(text: reply, type: 'text');
              },
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String livestockName = _roomData?['livestockName'] ?? widget.livestockItem['livestock_name'] ?? "Livestock Listing";
    final String imageUrl = _roomData?['imageUrl'] ?? widget.livestockItem['imageUrl'] ?? "";
    final num price = _roomData?['price'] ?? widget.livestockItem['price'] ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF8),
      appBar: AppBar(
        title: Text(widget.recipientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: _deepForestGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _softGreenTint,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: imageUrl.isNotEmpty
                          ? Image.network(imageUrl, width: 55, height: 55, fit: BoxFit.cover)
                          : Container(width: 55, height: 55, color: Colors.green.shade100, child: Icon(Icons.pets_rounded, color: _vibrantGreen)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Inquiring about:", style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(livestockName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _deepForestGreen), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text("Asking Price: ₱${FormatHelper.formatCurrency(price.toDouble())}", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: _vibrantGreen)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Divider(height: 1, color: Colors.green.shade100),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('chat_rooms')
                    .doc(widget.roomId)
                    .collection('messages')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: _vibrantGreen));
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return Center(child: Text("Start the negotiation!", style: TextStyle(color: Colors.grey.shade600)));

                  final docs = snapshot.data!.docs;

                  return ListView.builder(
                    reverse: true,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final bool isMe = data['senderId'] == _currentUser?.uid;
                      final String type = data['type'] ?? 'text';

                      if (type == 'offer') {
                        final double offerAmount = (data['offerAmount'] ?? 0).toDouble();
                        final String offerStatus = data['offerStatus'] ?? 'pending';

                        return _buildOfferBubble(doc.id, isMe, offerAmount, offerStatus);
                      }

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                          decoration: BoxDecoration(
                            color: isMe ? _vibrantGreen : Colors.white,
                            borderRadius: BorderRadius.circular(18).copyWith(
                              bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(18),
                              bottomLeft: !isMe ? const Radius.circular(4) : const Radius.circular(18),
                            ),
                            border: isMe ? null : Border.all(color: Colors.green.shade100),
                          ),
                          child: Text(
                            data['text'] ?? '',
                            style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 14, height: 1.4),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, -4))],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildQuickReplies(),
                    Row(
                      children: [
                        if (!_isSeller) ...[
                          IconButton(
                            icon: Icon(Icons.local_offer_rounded, color: Colors.amber.shade700),
                            tooltip: "Make an Offer",
                            onPressed: _showMakeOfferDialog,
                          ),
                        ],
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            decoration: InputDecoration(
                              hintText: "Type a message...",
                              filled: true,
                              fillColor: const Color(0xFFF8FBF8),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: Colors.green.shade200)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: Colors.green.shade200)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: _vibrantGreen, width: 2)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        CircleAvatar(
                          backgroundColor: _vibrantGreen,
                          radius: 22,
                          child: IconButton(
                            icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                            onPressed: () => _sendMessage(type: 'text'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfferBubble(String messageId, bool isMe, double amount, String status) {
    Color statusColor = status == 'pending' ? Colors.orange : (status == 'accepted' ? Colors.green : Colors.red);
    String statusText = status.toUpperCase();

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        width: MediaQuery.of(context).size.width * 0.75,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: statusColor.withValues(alpha: 0.5), width: 1.5),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(isMe ? "You Offered" : "Buyer Offered", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text("₱${FormatHelper.formatCurrency(amount)}", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _deepForestGreen)),
            if (status == 'pending' && _isSeller) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                      onPressed: () => _updateOfferStatus(messageId, 'rejected', amount),
                      child: const Text("Decline"),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: _vibrantGreen, foregroundColor: Colors.white),
                      onPressed: () => _updateOfferStatus(messageId, 'accepted', amount),
                      child: const Text("Accept"),
                    ),
                  ),
                ],
              ),
            ],
            if (status == 'accepted' && !_isSeller) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: _vibrantGreen, foregroundColor: Colors.white),
                  icon: const Icon(Icons.shopping_cart_checkout_rounded, size: 18),
                  label: const Text("Proceed to Checkout"),
                  onPressed: () => _proceedToCheckout(amount),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}