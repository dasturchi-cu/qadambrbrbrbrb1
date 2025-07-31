import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SupportService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  int _unreadTicketsCount = 0;

  int get unreadTicketsCount => _unreadTicketsCount;

  // Fetch unread tickets count
  Future<void> fetchUnreadTicketsCount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final query = await _firestore
          .collection('support_tickets')
          .where('userId', isEqualTo: user.uid)
          .where('hasUnreadMessages', isEqualTo: true)
          .get();

      _unreadTicketsCount = query.docs.length;
      notifyListeners();
    } catch (e) {
      print('Unread tickets count fetch error: $e');
    }
  }

  // Create new support ticket
  Future<String?> createTicket({
    required String subject,
    required String message,
    required String category,
    bool isPriority = false,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final docRef = await _firestore.collection('support_tickets').add({
        'userId': user.uid,
        'subject': subject,
        'category': category,
        'status': 'yangi',
        'isPriorityPaid': isPriority,
        'hasUnreadMessages': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Add initial message
      await _firestore
          .collection('support_tickets')
          .doc(docRef.id)
          .collection('messages')
          .add({
        'senderId': user.uid,
        'senderType': 'user',
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      print('Create ticket error: $e');
      return null;
    }
  }

  // Send message to ticket
  Future<bool> sendMessage({
    required String ticketId,
    required String message,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      // Add message
      await _firestore
          .collection('support_tickets')
          .doc(ticketId)
          .collection('messages')
          .add({
        'senderId': user.uid,
        'senderType': 'user',
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update ticket status
      await _firestore.collection('support_tickets').doc(ticketId).update({
        'updatedAt': FieldValue.serverTimestamp(),
        'status': 'javob_kutilmoqda',
      });

      return true;
    } catch (e) {
      print('Send message error: $e');
      return false;
    }
  }

  // Mark ticket as read
  Future<void> markTicketAsRead(String ticketId) async {
    try {
      await _firestore.collection('support_tickets').doc(ticketId).update({
        'hasUnreadMessages': false,
      });

      await fetchUnreadTicketsCount();
    } catch (e) {
      print('Mark as read error: $e');
    }
  }

  // Close ticket
  Future<bool> closeTicket(String ticketId) async {
    try {
      await _firestore.collection('support_tickets').doc(ticketId).update({
        'status': 'yechildi',
        'closedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Close ticket error: $e');
      return false;
    }
  }

  // Rate support
  Future<bool> rateSupport({
    required String ticketId,
    required int rating,
    String? feedback,
  }) async {
    try {
      await _firestore.collection('support_ratings').add({
        'ticketId': ticketId,
        'userId': _auth.currentUser?.uid,
        'rating': rating,
        'feedback': feedback,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Mark ticket as rated
      await _firestore.collection('support_tickets').doc(ticketId).update({
        'isRated': true,
        'rating': rating,
      });

      return true;
    } catch (e) {
      print('Rate support error: $e');
      return false;
    }
  }

  // Get ticket messages stream
  Stream<QuerySnapshot> getTicketMessages(String ticketId) {
    return _firestore
        .collection('support_tickets')
        .doc(ticketId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // Get user tickets stream
  Stream<QuerySnapshot> getUserTickets() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('support_tickets')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}