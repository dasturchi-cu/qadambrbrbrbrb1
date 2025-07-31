import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qadam_app/app/models/challenge_model.dart';

class ChallengeService extends ChangeNotifier {
  List<ChallengeModel> _challenges = [];
  bool _isLoading = false;
  String? _error;

  List<ChallengeModel> get challenges => _challenges;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchChallenges() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;

      // Base challenges
      List<ChallengeModel> baseChallenges = [
        ChallengeModel(
          id: '1',
          title: '1000 qadam',
          description: 'Bugun 1000 qadam yuring',
          targetSteps: 1000,
          reward: 10,
          duration: 1,
          type: 'daily',
        ),
        ChallengeModel(
          id: '2',
          title: '5000 qadam',
          description: 'Bugun 5000 qadam yuring',
          targetSteps: 5000,
          reward: 50,
          duration: 1,
          type: 'daily',
        ),
        ChallengeModel(
          id: '3',
          title: 'Haftalik 30000 qadam',
          description: 'Bu hafta 30000 qadam yuring',
          targetSteps: 30000,
          reward: 200,
          duration: 7,
          type: 'weekly',
        ),
      ];

      // Load user progress if logged in
      if (user != null) {
        final userChallenges = await FirebaseFirestore.instance
            .collection('user_challenges')
            .where('userId', isEqualTo: user.uid)
            .get();

        // Update challenges with user progress
        for (int i = 0; i < baseChallenges.length; i++) {
          final challenge = baseChallenges[i];
          final userChallenge = userChallenges.docs
              .where((doc) => doc.data()['challengeId'] == challenge.id)
              .firstOrNull;

          if (userChallenge != null) {
            final data = userChallenge.data();
            baseChallenges[i] = challenge.copyWith(
              progress: (data['progress'] ?? 0.0).toDouble(),
              isCompleted: data['isCompleted'] ?? false,
              rewardClaimed: data['rewardClaimed'] ?? false,
            );
          }
        }
      }

      _challenges = baseChallenges;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> joinChallenge(String challengeId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('user_challenges')
          .doc('${user.uid}_$challengeId')
          .set({
        'userId': user.uid,
        'challengeId': challengeId,
        'progress': 0.0,
        'isCompleted': false,
        'rewardClaimed': false,
        'joinedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error joining challenge: $e');
    }
  }

  Future<void> updateChallengeProgress(
      String challengeId, double progress) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('user_challenges')
          .doc('${user.uid}_$challengeId')
          .update({
        'progress': progress,
        'isCompleted': progress >= 1.0,
      });
    } catch (e) {
      debugPrint('Error updating challenge progress: $e');
    }
  }

  Future<void> claimChallengeReward(String challengeId, int reward) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Local state'ni avval yangilash
      final challengeIndex = _challenges.indexWhere((c) => c.id == challengeId);
      if (challengeIndex != -1) {
        _challenges[challengeIndex] = _challenges[challengeIndex].copyWith(
          isCompleted: true,
          rewardClaimed: true,
          progress: 1.0,
        );
        notifyListeners();
      }

      // User ma'lumotlarini olish
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final userData = userDoc.data() ?? {};
      final userName =
          userData['name'] ?? userData['displayName'] ?? 'Noma\'lum';
      final userEmail = user.email ?? 'Email yo\'q';

      // Challenge reward claim ma'lumotlarini saqlash
      await FirebaseFirestore.instance
          .collection('user_challenges')
          .doc('${user.uid}_$challengeId')
          .set({
        'userId': user.uid,
        'challengeId': challengeId,
        'rewardClaimed': true,
        'isCompleted': true,
        'progress': 1.0,
        'claimedAt': FieldValue.serverTimestamp(),
        'joinedAt': FieldValue.serverTimestamp(),
        // Qo'shimcha ma'lumotlar
        'rewardAmount': reward,
        'userName': userName,
        'userEmail': userEmail,
        'challengeTitle':
            _challenges.firstWhere((c) => c.id == challengeId).title,
      }, SetOptions(merge: true));

      // Coin transaction'ni ham saqlash
      await FirebaseFirestore.instance.collection('coin_transactions').add({
        'userId': user.uid,
        'userName': userName,
        'userEmail': userEmail,
        'amount': reward,
        'type': 'earned',
        'reason':
            'Challenge reward: ${_challenges.firstWhere((c) => c.id == challengeId).title}',
        'challengeId': challengeId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      print('✅ Challenge reward claimed: $reward coins');
      print('👤 User: $userName ($userEmail)');
      print(
          '🎯 Challenge: ${_challenges.firstWhere((c) => c.id == challengeId).title}');
    } catch (e) {
      debugPrint('Error claiming reward: $e');
      // Xatolik bo'lsa, local state'ni qaytarish
      final challengeIndex = _challenges.indexWhere((c) => c.id == challengeId);
      if (challengeIndex != -1) {
        _challenges[challengeIndex] = _challenges[challengeIndex].copyWith(
          isCompleted: false,
          rewardClaimed: false,
        );
        notifyListeners();
      }
      rethrow;
    }
  }

  void startListening() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Real-time listener
    FirebaseFirestore.instance
        .collection('user_challenges')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .listen((snapshot) {
      print(
          '🔄 Challenge ma\'lumotlari yangilandi: ${snapshot.docs.length} ta challenge');
      fetchChallenges(); // Ma'lumotlarni qayta yuklash
    });
  }
}
