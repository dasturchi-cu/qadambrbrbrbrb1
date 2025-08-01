import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LevelService extends ChangeNotifier {
  int _currentLevel = 1;
  int _currentXP = 0;
  int _totalSteps = 0;
  int _dailyStreak = 0;
  DateTime? _lastActiveDate;
  
  // Getters
  int get currentLevel => _currentLevel;
  int get currentXP => _currentXP;
  int get totalSteps => _totalSteps;
  int get dailyStreak => _dailyStreak;
  DateTime? get lastActiveDate => _lastActiveDate;
  
  // Level hesablash
  int get xpForNextLevel => _calculateXPForLevel(_currentLevel + 1);
  int get xpForCurrentLevel => _calculateXPForLevel(_currentLevel);
  int get xpProgress => _currentXP - xpForCurrentLevel;
  int get xpNeeded => xpForNextLevel - _currentXP;
  double get levelProgress => xpProgress / (xpForNextLevel - xpForCurrentLevel);
  
  // Level titles
  String get levelTitle => _getLevelTitle(_currentLevel);
  String get nextLevelTitle => _getLevelTitle(_currentLevel + 1);

  Future<void> initialize() async {
    await _loadFromLocal();
    await _syncWithFirestore();
  }

  // XP qo'shish
  Future<void> addXP(int xp, String reason) async {
    final oldLevel = _currentLevel;
    _currentXP += xp;
    
    // Level up check
    while (_currentXP >= _calculateXPForLevel(_currentLevel + 1)) {
      _currentLevel++;
    }
    
    await _saveToLocal();
    await _saveToFirestore();
    
    // Level up notification
    if (_currentLevel > oldLevel) {
      await _handleLevelUp(oldLevel, _currentLevel);
    }
    
    notifyListeners();
  }

  // Qadam uchun XP
  Future<void> addStepsXP(int steps) async {
    _totalSteps += steps;
    final xpGained = (steps / 100).floor(); // 100 qadam = 1 XP
    
    if (xpGained > 0) {
      await addXP(xpGained, 'Qadam tashlash: $steps qadam');
    }
  }

  // Kunlik streak
  Future<void> updateDailyStreak() async {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    
    if (_lastActiveDate == null) {
      _dailyStreak = 1;
    } else {
      final lastDate = DateTime(_lastActiveDate!.year, _lastActiveDate!.month, _lastActiveDate!.day);
      final daysDifference = todayDate.difference(lastDate).inDays;
      
      if (daysDifference == 1) {
        // Ketma-ket kun
        _dailyStreak++;
        
        // Streak bonus XP
        final bonusXP = _dailyStreak * 5; // Har kun uchun 5 XP bonus
        await addXP(bonusXP, 'Kunlik streak bonus: $_dailyStreak kun');
      } else if (daysDifference > 1) {
        // Streak uzildi
        _dailyStreak = 1;
      }
      // daysDifference == 0 bo'lsa, bugun allaqachon faol bo'lgan
    }
    
    _lastActiveDate = today;
    await _saveToLocal();
    await _saveToFirestore();
    notifyListeners();
  }

  // Challenge uchun XP
  Future<void> addChallengeXP(String challengeType, int difficulty) async {
    int xp = 0;
    switch (challengeType) {
      case 'daily':
        xp = 10 * difficulty;
        break;
      case 'weekly':
        xp = 50 * difficulty;
        break;
      case 'special':
        xp = 100 * difficulty;
        break;
    }
    
    if (xp > 0) {
      await addXP(xp, 'Vazifa bajarildi: $challengeType');
    }
  }

  // Achievement uchun XP
  Future<void> addAchievementXP(String achievementType) async {
    int xp = 0;
    switch (achievementType) {
      case 'bronze':
        xp = 25;
        break;
      case 'silver':
        xp = 50;
        break;
      case 'gold':
        xp = 100;
        break;
      case 'platinum':
        xp = 200;
        break;
    }
    
    if (xp > 0) {
      await addXP(xp, 'Yutuq qo\'lga kiritildi: $achievementType');
    }
  }

  // Level up handling
  Future<void> _handleLevelUp(int oldLevel, int newLevel) async {
    debugPrint('Level up! $oldLevel -> $newLevel');
    
    // Level up rewards
    final coinsReward = newLevel * 10; // Har level uchun 10 tanga
    
    // Notification service orqali xabar berish
    // NotificationService().showLevelUp(newLevel, coinsReward);
    
    // Coin service ga tanga qo'shish
    // CoinService().addCoins(coinsReward, description: 'Level $newLevel mukofoti');
  }

  // XP calculation
  int _calculateXPForLevel(int level) {
    if (level <= 1) return 0;
    return ((level - 1) * 100 * (level - 1) * 0.5).round();
  }

  // Level titles
  String _getLevelTitle(int level) {
    if (level >= 100) return 'Afsonaviy Yuruvchi';
    if (level >= 80) return 'Qadam Ustasi';
    if (level >= 60) return 'Marafon Qahramoni';
    if (level >= 40) return 'Yugurish Chempioni';
    if (level >= 30) return 'Faol Sportchi';
    if (level >= 20) return 'Yurish Sevuvchi';
    if (level >= 15) return 'Qadam Hisoblagichi';
    if (level >= 10) return 'Harakat Qiluvchi';
    if (level >= 5) return 'Yangi Boshlovchi';
    return 'Qadam Boshlang\'ich';
  }

  // Local storage
  Future<void> _saveToLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('current_level', _currentLevel);
    await prefs.setInt('current_xp', _currentXP);
    await prefs.setInt('total_steps', _totalSteps);
    await prefs.setInt('daily_streak', _dailyStreak);
    if (_lastActiveDate != null) {
      await prefs.setString('last_active_date', _lastActiveDate!.toIso8601String());
    }
  }

  Future<void> _loadFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLevel = prefs.getInt('current_level') ?? 1;
    _currentXP = prefs.getInt('current_xp') ?? 0;
    _totalSteps = prefs.getInt('total_steps') ?? 0;
    _dailyStreak = prefs.getInt('daily_streak') ?? 0;
    
    final lastActiveDateString = prefs.getString('last_active_date');
    if (lastActiveDateString != null) {
      _lastActiveDate = DateTime.parse(lastActiveDateString);
    }
  }

  // Firestore sync
  Future<void> _saveToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'level': _currentLevel,
        'xp': _currentXP,
        'totalSteps': _totalSteps,
        'dailyStreak': _dailyStreak,
        'lastActiveDate': _lastActiveDate != null ? Timestamp.fromDate(_lastActiveDate!) : null,
        'levelTitle': levelTitle,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Firestore save error: $e');
    }
  }

  Future<void> _syncWithFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final firestoreLevel = data['level'] ?? 1;
        final firestoreXP = data['xp'] ?? 0;
        
        // Firestore da yuqori ma'lumot bo'lsa, uni olish
        if (firestoreXP > _currentXP) {
          _currentLevel = firestoreLevel;
          _currentXP = firestoreXP;
          _totalSteps = data['totalSteps'] ?? _totalSteps;
          _dailyStreak = data['dailyStreak'] ?? _dailyStreak;
          
          final lastActiveTimestamp = data['lastActiveDate'] as Timestamp?;
          if (lastActiveTimestamp != null) {
            _lastActiveDate = lastActiveTimestamp.toDate();
          }
          
          await _saveToLocal();
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Firestore sync error: $e');
    }
  }

  // Leaderboard uchun ma'lumot
  Map<String, dynamic> getLeaderboardData() {
    return {
      'level': _currentLevel,
      'xp': _currentXP,
      'totalSteps': _totalSteps,
      'dailyStreak': _dailyStreak,
      'levelTitle': levelTitle,
    };
  }

  // Reset (test uchun)
  Future<void> resetProgress() async {
    _currentLevel = 1;
    _currentXP = 0;
    _totalSteps = 0;
    _dailyStreak = 0;
    _lastActiveDate = null;
    
    await _saveToLocal();
    await _saveToFirestore();
    notifyListeners();
  }
}
