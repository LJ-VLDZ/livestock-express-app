import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Sends a push notification document to a specific user's Firestore inbox
  static Future<void> sendNotification({
    required String recipientUid,
    required String title,
    required String body,
    String? type, // e.g., 'order', 'inquiry', 'system', 'message'
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(recipientUid)
          .collection('notifications')
          .add({
        'title': title,
        'body': body,
        'type': type ?? 'general',
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Failed to send notification: $e");
    }
  }
}