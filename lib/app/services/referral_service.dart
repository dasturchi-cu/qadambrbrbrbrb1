import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/referral_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReferralService extends ChangeNotifier {
  List<ReferralModel> _referrals = [];
  bool _isLoading = false;
  String? _error;

  List<ReferralModel> get referrals => _referrals;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Referral code generatsiyasi (foydalanuvchi ID asosida)
  String getReferralCode(String userId) {
    // Qisqaroq va o'qilishi oson kod
    final shortId = userId.length > 8 ? userId.substring(0, 8) : userId;
    return 'QADAM${shortId.toUpperCase()}';
  }

  // Referral code dan foydalanuvchi ID ni olish
  Future<String?> getUserIdFromReferralCode(String referralCode) async {
    if (referralCode.startsWith('QADAM') && referralCode.length > 5) {
      final shortId = referralCode.substring(5);

      // Qisqa ID dan to'liq foydalanuvchi ID ni topish
      final usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();

      for (var doc in usersSnapshot.docs) {
        final userShortId = doc.id.length > 8 ? doc.id.substring(0, 8) : doc.id;

        if (userShortId.toUpperCase() == shortId.toUpperCase()) {
          return doc.id;
        }
      }
    }
    return null;
  }

  // Referral code mavjudligini tekshirish
  Future<bool> isReferralCodeValid(String referralCode) async {
    try {
      final userId = await getUserIdFromReferralCode(referralCode);
      return userId != null;
    } catch (e) {
      return false;
    }
  }

  // Referal ro'yxatini olish
  Future<void> fetchReferrals(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('referrals')
          .where('referrerId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .get();

      _referrals = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        // Referred user ma'lumotlarini ham olish
        final referredUserDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(data['referredId'])
            .get();

        final referredUserName =
            referredUserDoc.data()?['name'] ?? 'Noma\'lum foydalanuvchi';

        _referrals.add(ReferralModel.fromMap({
          ...data,
          'referredUserName': referredUserName,
        }, doc.id));
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Yangi referal qo'shish
  Future<bool> addReferral(String referrerId, String referredId,
      {int reward = 200}) async {
    try {
      // O'zini o'ziga referral qilishni oldini olish
      if (referrerId == referredId) {
        _error = 'O\'zingizni o\'zingizga taklif qila olmaysiz';
        notifyListeners();
        return false;
      }

      // Bu foydalanuvchi allaqachon referral qilinganligini tekshirish
      final existingRef = await FirebaseFirestore.instance
          .collection('referrals')
          .where('referredId', isEqualTo: referredId)
          .get();

      if (existingRef.docs.isNotEmpty) {
        _error = 'Bu foydalanuvchi allaqachon taklif qilingan';
        notifyListeners();
        return false;
      }

      // Referral qo'shish
      await FirebaseFirestore.instance.collection('referrals').add({
        'referrerId': referrerId,
        'referredId': referredId,
        'date': FieldValue.serverTimestamp(),
        'reward': reward,
        'status': 'completed',
      });

      // Referrer ga tanga qo'shish
      final userDoc =
          FirebaseFirestore.instance.collection('users').doc(referrerId);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(userDoc);
        final currentCoins = snapshot.data()?['coins'] ?? 0;
        transaction.update(userDoc, {
          'coins': currentCoins + reward,
          'totalReferrals': (snapshot.data()?['totalReferrals'] ?? 0) + 1,
        });
      });

      // Referred user ga ham bonus berish
      final referredUserDoc =
          FirebaseFirestore.instance.collection('users').doc(referredId);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(referredUserDoc);
        final currentCoins = snapshot.data()?['coins'] ?? 0;
        transaction.update(referredUserDoc, {
          'coins': currentCoins + 50, // Yangi foydalanuvchi uchun 50 tanga
          'referredBy': referrerId,
        });
      });

      // Referral ro'yxatini yangilash
      await fetchReferrals(referrerId);

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Top 3 referal qilgan foydalanuvchilarni olish
  Future<List<Map<String, dynamic>>> getTopReferrers({int top = 3}) async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('referrals').get();
      final Map<String, int> refCount = {};

      for (var doc in snapshot.docs) {
        final referrerId = doc.data()['referrerId'];
        if (referrerId != null) {
          refCount[referrerId] = (refCount[referrerId] ?? 0) + 1;
        }
      }

      final sorted = refCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final topReferrers = <Map<String, dynamic>>[];

      for (var entry in sorted.take(top)) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(entry.key)
            .get();

        topReferrers.add({
          'referrerId': entry.key,
          'count': entry.value,
          'name': userDoc.data()?['name'] ?? 'Noma\'lum foydalanuvchi',
          'coins': userDoc.data()?['coins'] ?? 0,
        });
      }

      return topReferrers;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  // Referral statistikasini olish
  Future<Map<String, dynamic>> getReferralStats(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('referrals')
          .where('referrerId', isEqualTo: userId)
          .get();

      final totalReferrals = snapshot.docs.length;
      final totalReward = snapshot.docs.fold<int>(
          0, (sum, doc) => sum + ((doc.data()['reward'] as int?) ?? 0));

      return {
        'totalReferrals': totalReferrals,
        'totalReward': totalReward,
        'thisMonth': snapshot.docs.where((doc) {
          final date = doc.data()['date'] as Timestamp?;
          if (date == null) return false;
          final now = DateTime.now();
          final docDate = date.toDate();
          return docDate.year == now.year && docDate.month == now.month;
        }).length,
      };
    } catch (e) {
      return {
        'totalReferrals': 0,
        'totalReward': 0,
        'thisMonth': 0,
      };
    }
  }

  // User ma'lumotlarini Firestore'ga saqlash
  Future<void> _saveUserData(User? user) async {
    if (user != null) {
      await FirebaseFirestore.instance.collection("users").doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'name': user.displayName,
        'created_at': FieldValue.serverTimestamp(),
        'coins': 0,
        'totalReferrals': 0,
        'phone': user.phoneNumber
      }, SetOptions(merge: true));
    }
  }
}
