import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int requiredValue;
  final String type;
  final int reward;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.requiredValue,
    required this.type,
    required this.reward,
    this.isUnlocked = false,
    this.unlockedAt,
  });
}

class AchievementService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Achievement> _achievements = [];
  List<String> _unlockedAchievements = [];

  List<Achievement> get achievements => _achievements;
  List<String> get unlockedAchievements => _unlockedAchievements;

  // Initialize achievements
  Future<void> initialize() async {
    await _loadDefaultAchievements();
    await _loadUserAchievements();
  }

  // Load default achievements
  Future<void> _loadDefaultAchievements() async {
    _achievements = [
      Achievement(
        id: 'first_steps',
        title: 'Birinchi qadamlar',
        description: '1000 qadam bosing',
        icon: '👣',
        requiredValue: 1000,
        type: 'steps',
        reward: 10,
      ),
      Achievement(
        id: 'walker',
        title: 'Yuruvchi',
        description: '10,000 qadam bosing',
        icon: '🚶',
        requiredValue: 10000,
        type: 'steps',
        reward: 50,
      ),
      Achievement(
        id: 'runner',
        title: 'Yuguruvchi',
        description: '50,000 qadam bosing',
        icon: '🏃',
        requiredValue: 50000,
        type: 'steps',
        reward: 100,
      ),
      Achievement(
        id: 'marathon',
        title: 'Marathon',
        description: '100,000 qadam bosing',
        icon: '🏆',
        requiredValue: 100000,
        type: 'steps',
        reward: 200,
      ),
      Achievement(
        id: 'coin_collector',
        title: 'Coin yig\'uvchi',
        description: '100 ta coin to\'plang',
        icon: '🪙',
        requiredValue: 100,
        type: 'coins',
        reward: 20,
      ),
      Achievement(
        id: 'coin_master',
        title: 'Coin ustasi',
        description: '1000 ta coin to\'plang',
        icon: '💰',
        requiredValue: 1000,
        type: 'coins',
        reward: 100,
      ),
      Achievement(
        id: 'daily_streak_7',
        title: '7 kunlik ketma-ketlik',
        description: '7 kun ketma-ket login qiling',
        icon: '📅',
        requiredValue: 7,
        type: 'daily_streak',
        reward: 50,
      ),
      Achievement(
        id: 'daily_streak_30',
        title: '30 kunlik ketma-ketlik',
        description: '30 kun ketma-ket login qiling',
        icon: '📆',
        requiredValue: 30,
        type: 'daily_streak',
        reward: 200,
      ),
      Achievement(
        id: 'challenge_master',
        title: 'Challenge ustasi',
        description: '10 ta challenge yakunlang',
        icon: '🎯',
        requiredValue: 10,
        type: 'challenges',
        reward: 150,
      ),
      Achievement(
        id: 'referral_king',
        title: 'Referral qiroli',
        description: '5 ta do\'st taklif qiling',
        icon: '👥',
        requiredValue: 5,
        type: 'referrals',
        reward: 100,
      ),
    ];
    notifyListeners();
  }

  // Load user's unlocked achievements
  Future<void> _loadUserAchievements() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final query = await _firestore
          .collection('user_achievements')
          .where('userId', isEqualTo: user.uid)
          .get();

      _unlockedAchievements = query.docs.map((doc) => doc.data()['achievementId'] as String).toList();

      // Update achievements with unlocked status
      for (int i = 0; i < _achievements.length; i++) {
        if (_unlockedAchievements.contains(_achievements[i].id)) {
          final docData = query.docs.firstWhere(
                (doc) => doc.data()['achievementId'] == _achievements[i].id,
          ).data();

          _achievements[i] = Achievement(
            id: _achievements[i].id,
            title: _achievements[i].title,
            description: _achievements[i].description,
            icon: _achievements[i].icon,
            requiredValue: _achievements[i].requiredValue,
            type: _achievements[i].type,
            reward: _achievements[i].reward,
            isUnlocked: true,
            unlockedAt: docData['unlockedAt'] != null
                ? (docData['unlockedAt'] as Timestamp).toDate()
                : null,
          );
        }
      }

      notifyListeners();
    } catch (e) {
      print('User achievements yuklashda xatolik: $e');
    }
  }

  // Check and unlock achievements
  Future<void> checkAchievements({
    int? totalSteps,
    int? totalCoins,
    int? dailyStreak,
    int? completedChallenges,
    int? referralCount,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    List<Achievement> newlyUnlocked = [];

    for (Achievement achievement in _achievements) {
      if (achievement.isUnlocked) continue;

      bool shouldUnlock = false;

      switch (achievement.type) {
        case 'steps':
          shouldUnlock = totalSteps != null && totalSteps >= achievement.requiredValue;
          break;
        case 'coins':
          shouldUnlock = totalCoins != null && totalCoins >= achievement.requiredValue;
          break;
        case 'daily_streak':
          shouldUnlock = dailyStreak != null && dailyStreak >= achievement.requiredValue;
          break;
        case 'challenges':
          shouldUnlock = completedChallenges != null && completedChallenges >= achievement.requiredValue;
          break;
        case 'referrals':
          shouldUnlock = referralCount != null && referralCount >= achievement.requiredValue;
          break;
      }

      if (shouldUnlock) {
        await _unlockAchievement(achievement);
        newlyUnlocked.add(achievement);
      }
    }

    if (newlyUnlocked.isNotEmpty) {
      await _loadUserAchievements(); // Reload to update UI
      _showAchievementNotifications(newlyUnlocked);
    }
  }

  // Unlock specific achievement
  Future<void> _unlockAchievement(Achievement achievement) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('user_achievements').add({
        'userId': user.uid,
        'achievementId': achievement.id,
        'unlockedAt': FieldValue.serverTimestamp(),
        'reward': achievement.reward,
      });

      // Add reward coins
      await _firestore.collection('coin_transactions').add({
        'userId': user.uid,
        'amount': achievement.reward,
        'type': 'earned',
        'reason': 'Achievement: ${achievement.title}',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update user's coin balance
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final currentCoins = userDoc.data()?['coins'] ?? 0;
        await _firestore.collection('users').doc(user.uid).update({
          'coins': currentCoins + achievement.reward,
        });
      }

    } catch (e) {
      print('Achievement unlock qilishda xatolik: $e');
    }
  }

  // Show achievement notifications
  void _showAchievementNotifications(List<Achievement> achievements) {
    // This would typically show a popup or notification
    // For now, we'll just print to console
    for (Achievement achievement in achievements) {
      print('Achievement unlocked: ${achievement.title} - ${achievement.reward} coins');
    }
  }

  // Get achievement progress
  double getAchievementProgress(Achievement achievement, {
    int? totalSteps,
    int? totalCoins,
    int? dailyStreak,
    int? completedChallenges,
    int? referralCount,
  }) {
    if (achievement.isUnlocked) return 1.0;

    int currentValue = 0;

    switch (achievement.type) {
      case 'steps':
        currentValue = totalSteps ?? 0;
        break;
      case 'coins':
        currentValue = totalCoins ?? 0;
        break;
      case 'daily_streak':
        currentValue = dailyStreak ?? 0;
        break;
      case 'challenges':
        currentValue = completedChallenges ?? 0;
        break;
      case 'referrals':
        currentValue = referralCount ?? 0;
        break;
    }

    return (currentValue / achievement.requiredValue).clamp(0.0, 1.0);
  }

  // Get achievements by category
  List<Achievement> getAchievementsByType(String type) {
    return _achievements.where((achievement) => achievement.type == type).toList();
  }

  // Get unlocked achievements count
  int get unlockedCount => _unlockedAchievements.length;

  // Get total achievements count
  int get totalCount => _achievements.length;

  // Get completion percentage
  double get completionPercentage {
    if (_achievements.isEmpty) return 0.0;
    return unlockedCount / totalCount;
  }

  // Get total rewards earned
  int get totalRewardsEarned {
    int total = 0;
    for (Achievement achievement in _achievements) {
      if (achievement.isUnlocked) {
        total += achievement.reward;
      }
    }
    return total;
  }

  // Check if achievement is unlocked
  bool isAchievementUnlocked(String achievementId) {
    return _unlockedAchievements.contains(achievementId);
  }

  // Get achievement by ID
  Achievement? getAchievementById(String id) {
    try {
      return _achievements.firstWhere((achievement) => achievement.id == id);
    } catch (e) {
      return null;
    }
  }

  // Reset all achievements (for testing)
  Future<void> resetAchievements() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final query = await _firestore
          .collection('user_achievements')
          .where('userId', isEqualTo: user.uid)
          .get();

      for (var doc in query.docs) {
        await doc.reference.delete();
      }

      _unlockedAchievements.clear();
      await _loadDefaultAchievements();
      notifyListeners();
    } catch (e) {
      print('Achievement reset qilishda xatolik: $e');
    }
  }
}