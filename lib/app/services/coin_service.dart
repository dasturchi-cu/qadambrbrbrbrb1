import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qadam_app/app/models/achievement_model.dart';
import 'package:qadam_app/app/models/transaction_model.dart';
import 'dart:convert';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CoinService extends ChangeNotifier {
  int _coins = 0;
  int _todayEarned = 0;
  int _stepsPerCoin = 100; // 1000 qadam = 10 tanga (100 qadam = 1 tanga)
  int _dailyCoinLimit = 100; // Maximum coins per day
  DateTime? _lastResetDate;
  DateTime? _lastLoginDate;
  int? _lastBonusAmount;
  DateTime? _lastBonusDate;
  SharedPreferences? _prefs;
  bool _isInitialized = false;
  bool _showBonusSnackbar = false;
  final List<AchievementModel> _achievements = [];
  StreamSubscription<DocumentSnapshot>? _coinSubscription;

  CoinService() {
    _initPrefs();
  }
//aa
  int get coins => _coins;
  int get todayEarned => _todayEarned;
  int get stepsPerCoin => _stepsPerCoin;
  int get dailyCoinLimit => _dailyCoinLimit;
  int? get lastBonusAmount => _lastBonusAmount;
  DateTime? get lastBonusDate => _lastBonusDate;
  bool get showBonusSnackbar => _showBonusSnackbar;
  List<AchievementModel> get achievements => _achievements;

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _isInitialized = true;
    await _loadCoins();
    await _loadAchievements();
    await _checkForDailyReset();
    await _checkDailyLoginBonus();
  }

  Future<void> _loadCoins() async {
    if (_prefs == null) return;
    _coins = _prefs!.getInt('coins') ?? 0;
    _todayEarned = _prefs!.getInt('todayEarned') ?? 0;
    _heldCoins = _prefs!.getInt('heldCoins') ?? 0;
    final lastResetString = _prefs!.getString('coinLastResetDate');
    if (lastResetString != null) {
      _lastResetDate = DateTime.parse(lastResetString);
    }
    notifyListeners();
  }

  Future<void> _loadAchievements() async {
    if (_prefs == null) return;
    final achievementsString = _prefs!.getString('achievements');
    if (achievementsString != null) {
      final List decoded = jsonDecode(achievementsString);
      _achievements.clear();
      _achievements
          .addAll(decoded.map((e) => AchievementModel.fromMap(e)).toList());
    }
    notifyListeners();
  }

  Future<void> _saveCoins() async {
    if (_prefs == null) return;
    await _prefs!.setInt('coins', _coins);
    await _prefs!.setInt('todayEarned', _todayEarned);
    await _prefs!
        .setString('coinLastResetDate', DateTime.now().toIso8601String());
  }

  Future<void> _saveAchievements() async {
    if (_prefs == null) return;
    final encoded = jsonEncode(_achievements.map((e) => e.toMap()).toList());
    await _prefs!.setString('achievements', encoded);
  }

  Future<void> _checkForDailyReset() async {
    if (_prefs == null) return;
    if (_lastResetDate == null) {
      _lastResetDate = DateTime.now();
      await _prefs!
          .setString('coinLastResetDate', _lastResetDate!.toIso8601String());
      return;
    }

    final now = DateTime.now();
    final lastMidnight = DateTime(now.year, now.month, now.day);
    final resetMidnight = DateTime(
      _lastResetDate!.year,
      _lastResetDate!.month,
      _lastResetDate!.day,
    );

    if (lastMidnight.isAfter(resetMidnight)) {
      // New day, reset today's earned coins
      _todayEarned = 0;
      _lastResetDate = now;
      await _saveCoins();
      notifyListeners();
    }
  }

  Future<void> _checkDailyLoginBonus() async {
    if (_prefs == null) return;
    final now = DateTime.now();
    final lastLoginString = _prefs!.getString('lastLoginDate');
    if (lastLoginString != null) {
      _lastLoginDate = DateTime.parse(lastLoginString);
    }
    if (_lastLoginDate == null ||
        now.year != _lastLoginDate!.year ||
        now.month != _lastLoginDate!.month ||
        now.day != _lastLoginDate!.day) {
      int bonus;
      if (now.difference(_lastLoginDate ?? now).inDays >= 7) {
        bonus = 20;
      } else {
        bonus = 10;
      }
      _coins += bonus;
      _lastBonusAmount = bonus;
      _lastBonusDate = now;
      _showBonusSnackbar = true;
      await _prefs!.setInt('coins', _coins);
      await _prefs!.setString('lastLoginDate', now.toIso8601String());
      _lastLoginDate = now;
      notifyListeners();
    }
  }

  // Add coins based on steps - called when steps are updated
  Future<int> addCoinsFromSteps(int steps) async {
    if (_todayEarned >= _dailyCoinLimit) {
      return 0; // Daily limit reached
    }

    int earnedCoins = (steps / _stepsPerCoin).floor();

    // Cap to daily limit
    if (_todayEarned + earnedCoins > _dailyCoinLimit) {
      earnedCoins = _dailyCoinLimit - _todayEarned;
    }

    if (earnedCoins > 0) {
      _coins += earnedCoins;
      _todayEarned += earnedCoins;
      await _saveCoins();

      // Tranzaksiya qo'shish
      await _addTransaction(
        type: TransactionType.earned,
        amount: earnedCoins,
        description: '$steps qadam uchun $earnedCoins tanga',
        metadata: {'steps': steps, 'stepsPerCoin': _stepsPerCoin},
      );

      notifyListeners();
    }

    return earnedCoins;
  }

  // Add coins from challenge or referral
  Future<void> addCoins(int amount,
      {String description = '', TransactionType? type}) async {
    _coins += amount;
    await _saveCoins();
    await _saveStatsToFirestore();
    await _syncCoinsToFirestore(); // Real-time sync

    // Tranzaksiya qo'shish
    await _addTransaction(
      type: type ?? TransactionType.earned,
      amount: amount,
      description: description.isEmpty ? 'Tanga qo\'shildi' : description,
    );

    notifyListeners();
  }

  // Tranzaksiya qo'shish funksiyasi
  Future<void> _addTransaction({
    required TransactionType type,
    required int amount,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final transaction = TransactionModel(
        id: '',
        userId: user.uid,
        type: type,
        amount: amount,
        description: description,
        timestamp: DateTime.now(),
        metadata: metadata,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .add(transaction.toMap());
    } catch (e) {
      debugPrint('Tranzaksiya qo\'shishda xatolik: $e');
    }
  }

  Future<void> _saveStatsToFirestore({int? currentSteps}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final userDoc =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    final statsDoc = userDoc
        .collection('stats')
        .doc(DateTime.now().toIso8601String().substring(0, 10));
    int steps = 0;
    if (currentSteps != null) {
      steps = currentSteps;
    } else {
      try {
        // Try to get steps from Firestore if available
        final snapshot = await statsDoc.get();
        if (snapshot.exists) {
          steps = snapshot.data()?['steps'] ?? 0;
        }
      } catch (_) {}
    }
    await statsDoc.set({
      'day': DateTime.now().toString().substring(0, 10),
      'steps': steps,
      'coins': _todayEarned,
      'date': DateTime.now(),
    }, SetOptions(merge: true));
  }

  // Use coins for purchase
  Future<bool> useCoins(int amount) async {
    if (_coins < amount) {
      return false; // Not enough coins
    }

    _coins -= amount;
    await _saveCoins();
    notifyListeners();
    return true;
  }

  // For withdrawal to cash
  Future<bool> withdrawCoins(int amount) async {
    if (_coins < amount) {
      return false; // Not enough coins
    }

    // This would typically involve an API call to process the withdrawal
    // For now, just deduct the coins
    _coins -= amount;
    await _saveCoins();
    notifyListeners();
    return true;
  }

  // For adding referral bonus
  Future<void> addReferralBonus(int bonus) async {
    _coins += bonus;
    await _saveCoins();
    notifyListeners();
  }

  // Set steps per coin ratio
  Future<void> setStepsPerCoin(int steps) async {
    if (_prefs == null) return;
    _stepsPerCoin = steps;
    await _prefs!.setInt('stepsPerCoin', steps);
    notifyListeners();
  }

  // Set daily coin limit
  Future<void> setDailyCoinLimit(int limit) async {
    if (_prefs == null) return;
    _dailyCoinLimit = limit;
    await _prefs!.setInt('dailyCoinLimit', limit);
    notifyListeners();
  }

  void clearBonusSnackbar() {
    _showBonusSnackbar = false;
    notifyListeners();
  }

  // Public initialize method
  Future<void> initialize() async {
    await _initPrefs();
  }

  // Public method to check daily login bonus
  Future<void> checkDailyLoginBonus() async {
    if (!_isInitialized) return;
    await _checkDailyLoginBonus();
  }

  // Support-related properties and methods
  int get prioritySupportCost => 50; // 50 tanga for priority support
  int get feedbackBonus => 10; // 10 tanga for feedback

  bool get canAffordPrioritySupport => _coins >= prioritySupportCost;

  Future<bool> hasPrioritySupport([String? ticketId]) async {
    // Check if user has active priority support for ticket
    return false; // Placeholder implementation
  }

  Future<bool> purchasePrioritySupport([String? ticketId]) async {
    if (!canAffordPrioritySupport) return false;
    return await useCoins(prioritySupportCost);
  }

  // Deduct coins with optional reason
  Future<bool> deductCoins(int amount, [String? reason]) async {
    if (_coins < amount) return false;

    _coins -= amount;
    await _saveCoins();

    // Tranzaksiya qo'shish
    await _addTransaction(
      type: TransactionType.spent,
      amount: -amount,
      description: reason ?? 'Tanga sarflandi',
    );

    notifyListeners();
    return true;
  }

  // Hold/Save coins functionality
  int _heldCoins = 0;
  int get heldCoins => _heldCoins;
  int get availableCoins => _coins - _heldCoins;

  // Hold coins for later use
  Future<bool> holdCoins(int amount) async {
    if (_prefs == null) return false;
    if (availableCoins < amount) return false;

    _heldCoins += amount;
    await _prefs!.setInt('heldCoins', _heldCoins);
    notifyListeners();
    return true;
  }

  // Release held coins back to available balance
  Future<bool> releaseHeldCoins(int amount) async {
    if (_prefs == null) return false;
    if (_heldCoins < amount) return false;

    _heldCoins -= amount;
    await _prefs!.setInt('heldCoins', _heldCoins);
    notifyListeners();
    return true;
  }

  // Release all held coins
  Future<void> releaseAllHeldCoins() async {
    if (_prefs == null) return;
    _heldCoins = 0;
    await _prefs!.setInt('heldCoins', 0);
    notifyListeners();
  }

  void addChallengeAchievement(String challengeTitle, int reward) {
    // Check if achievement already exists for this challenge and reward
    final alreadyExists = _achievements
        .any((a) => a.challengeTitle == challengeTitle && a.reward == reward);
    if (alreadyExists) return;
    _achievements.add(AchievementModel(
      challengeTitle: challengeTitle,
      reward: reward,
      date: DateTime.now(),
    ));
    _saveAchievements();
    notifyListeners();
  }

  // Persist local challenge claim state
  Future<void> saveLocalChallengeState(List challenges) async {
    if (_prefs == null) return;
    final localStates = _prefs!.getString('localChallengeStates');
    Map<String, dynamic> stateMap = {};
    if (localStates != null) {
      stateMap = jsonDecode(localStates);
    }
    for (var c in challenges) {
      if (c.id.startsWith('daily_') ||
          c.id.startsWith('profile_') ||
          c.id.startsWith('invite_') ||
          c.id.startsWith('weekly_') ||
          c.id == 'share_stats') {
        stateMap[c.id] = {
          'rewardClaimed': c.rewardClaimed ?? false,
          'isCompleted': c.isCompleted,
        };
      }
    }
    await _prefs!.setString('localChallengeStates', jsonEncode(stateMap));
  }

  Future<void> loadLocalChallengeState(List challenges) async {
    if (_prefs == null) return;
    final localStates = _prefs!.getString('localChallengeStates');
    if (localStates != null) {
      final stateMap = jsonDecode(localStates);
      for (var c in challenges) {
        if (stateMap[c.id] != null) {
          c.rewardClaimed = stateMap[c.id]['rewardClaimed'] ?? false;
          c.isCompleted = stateMap[c.id]['isCompleted'] ?? false;
        }
      }
    }
  }

  // Sync coins to Firestore
  Future<void> _syncCoinsToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'totalCoins': _coins,
        'lastUpdated': Timestamp.now(),
      }, SetOptions(merge: true));

      debugPrint('Coins synced to Firestore: $_coins');
    } catch (e) {
      debugPrint('Error syncing coins to Firestore: $e');
    }
  }

  // Real-time coin balance listener
  void startRealTimeUpdates() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Cancel existing subscription
    _coinSubscription?.cancel();

    // Listen to user's coin balance in real-time
    _coinSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen(
      (snapshot) {
        if (snapshot.exists) {
          final data = snapshot.data() as Map<String, dynamic>;
          final firestoreCoins = data['totalCoins'] ?? 0;

          // Update local coins if Firestore has more recent data
          if (firestoreCoins != _coins) {
            _coins = firestoreCoins;
            _saveCoins();
            notifyListeners();
            debugPrint('🪙 Coins updated from Firestore: $_coins');
          }
        }
      },
      onError: (error) {
        debugPrint('Coin listener error: $error');
        // Retry after 30 seconds
        Future.delayed(const Duration(seconds: 30), () {
          startRealTimeUpdates();
        });
      },
      cancelOnError: false,
    );
  }

  void stopRealTimeUpdates() {
    _coinSubscription?.cancel();
    _coinSubscription = null;
  }

  @override
  void dispose() {
    stopRealTimeUpdates();
    super.dispose();
  }
}
