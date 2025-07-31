import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/transaction_model.dart';

class TransactionService extends ChangeNotifier {
  List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  String? _error;

  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchTransactions(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .orderBy('timestamp', descending: true)
          .get();
      _transactions = snapshot.docs
          .map((doc) => TransactionModel.fromMap(doc.data(), doc.id))
          .toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Tranzaksiya qo'shish
  Future<void> addTransaction({
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

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .add(transaction.toMap());

      // Local list ni yangilash
      _transactions.insert(0, transaction);
      notifyListeners();
    } catch (e) {
      print('Tranzaksiya qo\'shishda xatolik: $e');
    }
  }

  Future<bool> sendWithdrawRequest(String userId, int amount) async {
    try {
      await FirebaseFirestore.instance.collection('withdraw_requests').add({
        'userId': userId,
        'amount': amount,
        'status': 'accepted',
        'date': FieldValue.serverTimestamp(),
      });
      final userDoc =
          FirebaseFirestore.instance.collection('users').doc(userId);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(userDoc);
        final currentCoins = snapshot.data()?['coins'] ?? 0;
        if (currentCoins >= amount) {
          transaction.update(userDoc, {
            'coins': currentCoins - amount,
          });
        } else {
          throw Exception("Balansda yetarli mablag' yo'q");
        }
      });
      return true;
    } catch (e) {
      print("Pul yechish so'rovida xatolik: $e");
      return false;
    }
  }
}
