import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_room_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> with SingleTickerProviderStateMixin {
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

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
    if (currentUserId == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F9F4),
        body: Center(
          child: Text(
            "Please log in to view messages.",
            style: TextStyle(fontWeight: FontWeight.w600, color: _deepForestGreen),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F4),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
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
                      color: Colors.black.withValues(alpha: 0.1),
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
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
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
                      "Marketplace Inbox",
                      style: TextStyle(color: Colors.white, fontSize: 28, height: 1.1, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('chat_rooms')
                      .where('participants', arrayContains: currentUserId)
                      .orderBy('last_message_time', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator(color: _vibrantGreen));
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20)],
                              ),
                              child: Icon(Icons.forum_rounded, size: 54, color: _mintAccent),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              "No Active Negotiations",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _deepForestGreen),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Your trade inquiries will appear here.",
                              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      );
                    }

                    final chatRooms = snapshot.data!.docs;

                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
                      itemCount: chatRooms.length,
                      itemBuilder: (context, index) {
                        final chatData = chatRooms[index].data() as Map<String, dynamic>;
                        final roomId = chatRooms[index].id;
                        List<dynamic> participants = chatData['participants'] ?? [];
                        String otherUserId = participants.firstWhere((id) => id != currentUserId, orElse: () => "Unknown User");

                        return FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
                          builder: (context, userSnapshot) {
                            String otherUserName = "Trader";
                            if (userSnapshot.hasData && userSnapshot.data!.exists) {
                              final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                              otherUserName = userData['name'] ?? userData['fullName'] ?? userData['email'] ?? "Trader";
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: Colors.green.shade50, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: _deepForestGreen.withValues(alpha: 0.04),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(24),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(24),
                                  onTap: () async {
                                    showDialog(
                                      context: context,
                                      barrierColor: Colors.black.withValues(alpha: 0.1),
                                      barrierDismissible: false,
                                      builder: (_) => Center(child: CircularProgressIndicator(color: _vibrantGreen)),
                                    );

                                    try {
                                      final String livestockId = chatData['livestockId'] ?? '';
                                      final livestockDoc = await FirebaseFirestore.instance.collection('livestock').doc(livestockId).get();
                                      if (context.mounted) Navigator.pop(context);

                                      Map<String, dynamic> itemData = livestockDoc.exists && livestockDoc.data() != null
                                          ? livestockDoc.data() as Map<String, dynamic>
                                          : {
                                        'livestock_name': chatData['livestockName'] ?? 'Unavailable Item',
                                        'imageUrl': chatData['imageUrl'] ?? '',
                                        'price': chatData['price'] ?? 0,
                                        'seller_id': 'unknown',
                                      };

                                      if (context.mounted) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ChatRoomScreen(
                                              roomId: roomId,
                                              recipientName: otherUserName,
                                              docId: livestockId,
                                              livestockItem: itemData,
                                            ),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) Navigator.pop(context);
                                    }
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(18),
                                    child: Row(
                                      children: [
                                        Container(
                                          height: 56,
                                          width: 56,
                                          decoration: BoxDecoration(
                                            color: _deepForestGreen,
                                            borderRadius: BorderRadius.circular(16),
                                            boxShadow: [
                                              BoxShadow(
                                                color: _vibrantGreen.withValues(alpha: 0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            otherUserName.isNotEmpty ? otherUserName[0].toUpperCase() : "T",
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                otherUserName,
                                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: _deepForestGreen),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: _softGreenTint,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  chatData['last_message'] ?? "Tap to start conversation",
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w500),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade50,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(Icons.arrow_forward_ios_rounded, color: _vibrantGreen, size: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
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
}