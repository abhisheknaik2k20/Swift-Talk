// Notification model class for Firebase data
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationClass {
  String? id;
  final String message;
  final String reciverId;
  final String senderId;
  final String senderName;
  final Timestamp timestamp;
  final String type;

  NotificationClass(
      {this.id,
      required this.message,
      required this.reciverId,
      required this.senderId,
      required this.senderName,
      required this.timestamp,
      required this.type});
  factory NotificationClass.fromMap(Map<String, dynamic> map, String docId) {
    return NotificationClass(
        id: docId,
        message: map['message'] ?? '',
        reciverId: map['reciverId'] ?? '',
        senderId: map['senderId'] ?? '',
        senderName: map['senderName'] ?? '',
        timestamp: map['timestamp'],
        type: map['type'] ?? '');
  }
  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'reciverId': reciverId,
      'senderId': senderId,
      'senderName': senderName,
      'timestamp': timestamp,
      'type': type
    };
  }

  NotificationClass copyWith(
      {String? id,
      String? message,
      String? reciverId,
      String? senderId,
      String? senderName,
      Timestamp? timestamp,
      String? type}) {
    return NotificationClass(
        id: id ?? this.id,
        message: message ?? this.message,
        reciverId: reciverId ?? this.reciverId,
        senderId: senderId ?? this.senderId,
        senderName: senderName ?? this.senderName,
        timestamp: timestamp ?? this.timestamp,
        type: type ?? this.type);
  }
}

class NotificationRepository {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  Future<void> addNotification(NotificationClass notification) async {
    await _firestore
        .collection('users')
        .doc(notification.reciverId)
        .collection('noti_Info')
        .add(notification.toMap());
  }

  Future<void> updateNotifications(
      {required String reciverId,
      required String message,
      required String type}) async {
    final notification = NotificationClass(
        id: '',
        message: message,
        reciverId: reciverId,
        senderId: _auth.currentUser?.uid ?? 'null',
        senderName: _auth.currentUser?.displayName ?? 'unknown',
        timestamp: Timestamp.now(),
        type: type);
    await addNotification(notification);
  }

  Stream<List<NotificationClass>> getNotifications(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('noti_Info')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationClass.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<NotificationClass>> getNotificationsByType(
      String userId, String type) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('noti_Info')
        .where('type', isEqualTo: type)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationClass.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> deleteNotification(String userId, String notificationId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('noti_Info')
        .doc(notificationId)
        .delete();
  }

  Future<void> markAllNotificationsAsRead(String userId) async {
    final batch = _firestore.batch();
    final notificationsSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('noti_Info')
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in notificationsSnapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }
}
