import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'dart:math';
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

      // Real challenges - Professional level
      List<ChallengeModel> baseChallenges = [
        // Daily Challenges
        ChallengeModel(
          id: 'daily_1000',
          title: '🚶 Boshlang\'ich qadam',
          description: 'Bugun 1,000 qadam yuring va sog\'lom hayotni boshlang!',
          targetSteps: 1000,
          reward: 15,
          duration: 1,
          type: 'daily',
        ),
        ChallengeModel(
          id: 'daily_3000',
          title: '🏃 Faol yurish',
          description: 'Bugun 3,000 qadam yuring va energiya to\'plang!',
          targetSteps: 3000,
          reward: 35,
          duration: 1,
          type: 'daily',
        ),
        ChallengeModel(
          id: 'daily_5000',
          title: '💪 Kuchli qadam',
          description:
              'Bugun 5,000 qadam yuring va o\'zingizni yaxshi his qiling!',
          targetSteps: 5000,
          reward: 60,
          duration: 1,
          type: 'daily',
        ),
        ChallengeModel(
          id: 'daily_8000',
          title: '🔥 Yonuvchan qadam',
          description: 'Bugun 8,000 qadam yuring va kalori yoqing!',
          targetSteps: 8000,
          reward: 100,
          duration: 1,
          type: 'daily',
        ),
        ChallengeModel(
          id: 'daily_10000',
          title: '🏆 Oltin qadam',
          description: 'Bugun 10,000 qadam yuring va champion bo\'ling!',
          targetSteps: 10000,
          reward: 150,
          duration: 1,
          type: 'daily',
        ),

        // Weekly Challenges
        ChallengeModel(
          id: 'weekly_20000',
          title: '📅 Haftalik boshlang\'ich',
          description:
              'Bu hafta 20,000 qadam yuring va doimiylikni o\'rganing!',
          targetSteps: 20000,
          reward: 200,
          duration: 7,
          type: 'weekly',
        ),
        ChallengeModel(
          id: 'weekly_50000',
          title: '🎯 Haftalik maqsad',
          description:
              'Bu hafta 50,000 qadam yuring va o\'zingizni sinab ko\'ring!',
          targetSteps: 50000,
          reward: 400,
          duration: 7,
          type: 'weekly',
        ),
        ChallengeModel(
          id: 'weekly_70000',
          title: '🚀 Haftalik raketa',
          description: 'Bu hafta 70,000 qadam yuring va yangi rekord qo\'ying!',
          targetSteps: 70000,
          reward: 600,
          duration: 7,
          type: 'weekly',
        ),

        // Monthly Challenges
        ChallengeModel(
          id: 'monthly_200000',
          title: '🌟 Oylik yulduz',
          description: 'Bu oy 200,000 qadam yuring va yulduz bo\'ling!',
          targetSteps: 200000,
          reward: 1000,
          duration: 30,
          type: 'monthly',
        ),
        ChallengeModel(
          id: 'monthly_300000',
          title: '👑 Oylik qirol',
          description:
              'Bu oy 300,000 qadam yuring va qirol unvonini qo\'lga kiriting!',
          targetSteps: 300000,
          reward: 1500,
          duration: 30,
          type: 'monthly',
        ),

        // Special Challenges
        ChallengeModel(
          id: 'special_streak_7',
          title: '🔥 7 kunlik olov',
          description: 'Ketma-ket 7 kun har kuni 5000+ qadam yuring!',
          targetSteps: 35000,
          reward: 500,
          duration: 7,
          type: 'streak',
        ),
        ChallengeModel(
          id: 'special_weekend',
          title: '🎉 Dam olish kunlari',
          description: 'Shanba va yakshanba kunlari 8000+ qadam yuring!',
          targetSteps: 16000,
          reward: 300,
          duration: 2,
          type: 'weekend',
        ),
        ChallengeModel(
          id: 'special_morning',
          title: '🌅 Erta turuvchi',
          description: 'Ertalab soat 8 gacha 3000 qadam yuring!',
          targetSteps: 3000,
          reward: 200,
          duration: 1,
          type: 'morning',
        ),
        ChallengeModel(
          id: 'special_evening',
          title: '🌙 Kechqurun yuruvchi',
          description: 'Kechqurun soat 18 dan keyin 5000 qadam yuring!',
          targetSteps: 5000,
          reward: 250,
          duration: 1,
          type: 'evening',
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

      debugPrint('✅ Challenge reward claimed: $reward coins');
      debugPrint('👤 User: $userName ($userEmail)');
      debugPrint(
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

  StreamSubscription<QuerySnapshot>? _challengeSubscription;

  void startListening() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Cancel existing subscription
    _challengeSubscription?.cancel();

    // Real-time listener with error handling
    _challengeSubscription = FirebaseFirestore.instance
        .collection('user_challenges')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .listen(
      (snapshot) {
        debugPrint(
            '🔄 Challenge ma\'lumotlari yangilandi: ${snapshot.docs.length} ta challenge');
        fetchChallenges(); // Ma'lumotlarni qayta yuklash
      },
      onError: (error) {
        debugPrint('Challenge listener error: $error');
        // Retry after 30 seconds
        Future.delayed(const Duration(seconds: 30), () {
          startListening();
        });
      },
      cancelOnError: false,
    );
  }

  void stopListening() {
    _challengeSubscription?.cancel();
    _challengeSubscription = null;
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}
