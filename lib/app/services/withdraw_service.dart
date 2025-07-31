import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction_model.dart';

class WithdrawService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  // Pul yechish so'rovini yuborish
  Future<bool> requestWithdraw({
    required int amount,
    required String method,
    required String cardNumber,
    required String phoneNumber,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = _auth.currentUser;
      if (user == null) {
        _error = 'Foydalanuvchi tizimga kirmagan';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Withdraw request ni Firestore ga saqlash
      await _firestore.collection('withdraw_requests').add({
        'userId': user.uid,
        'userEmail': user.email,
        'amount': amount,
        'method': method,
        'cardNumber': cardNumber,
        'phoneNumber': phoneNumber,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Tranzaksiya qo'shish
      await _addTransaction(
        userId: user.uid,
        type: TransactionType.withdraw,
        amount: -amount,
        description: 'Pul yechish so\'rovi: $method',
        metadata: {
          'method': method,
          'cardNumber': cardNumber,
          'phoneNumber': phoneNumber,
        },
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Foydalanuvchining withdraw tarixini olish
  Future<List<Map<String, dynamic>>> getWithdrawHistory() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final snapshot = await _firestore
          .collection('withdraw_requests')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  // Withdraw so'rovini bekor qilish
  Future<bool> cancelWithdrawRequest(String requestId) async {
    try {
      await _firestore
          .collection('withdraw_requests')
          .doc(requestId)
          .update({'status': 'cancelled'});

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Tranzaksiya qo'shish funksiyasi
  Future<void> _addTransaction({
    required String userId,
    required TransactionType type,
    required int amount,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final transaction = TransactionModel(
        id: '',
        userId: userId,
        type: type,
        amount: amount,
        description: description,
        timestamp: DateTime.now(),
        metadata: metadata,
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .add(transaction.toMap());
    } catch (e) {
      debugPrint('Tranzaksiya qo\'shishda xatolik: $e');
    }
  }
}
