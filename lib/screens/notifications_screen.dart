import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatelessWidget {
  NotificationsScreen({super.key});

  final Color _deepForestGreen = const Color(0xFF0A3622);
  final Color _vibrantGreen = const Color(0xFF1B5E20);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F4),
      appBar: AppBar(
        title: const Text("Notifications", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: _deepForestGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: user == null
          ? const Center(child: Text("Please log in to view notifications."))
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .orderBy('timestamp', descending: true)
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
                  Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text("No notifications yet", style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final title = data['title'] ?? 'Update';
              final body = data['body'] ?? '';
              final timestamp = data['timestamp'] as Timestamp?;
              final isRead = data['isRead'] ?? false;

              String timeFormatted = '';
              if (timestamp != null) {
                timeFormatted = DateFormat('MMM dd, yyyy • hh:mm a').format(timestamp.toDate());
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: isRead ? Colors.white : const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2))],
                  border: Border.all(color: isRead ? Colors.transparent : _vibrantGreen.withValues(alpha: 0.3)),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _vibrantGreen.withValues(alpha: 0.1),
                    child: Icon(Icons.notifications_active_rounded, color: _vibrantGreen),
                  ),
                  title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _deepForestGreen)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(body, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                      const SizedBox(height: 6),
                      Text(timeFormatted, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                    ],
                  ),
                  onTap: () {
                    docs[index].reference.update({'isRead': true});
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}