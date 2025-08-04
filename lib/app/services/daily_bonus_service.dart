import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:math';
import 'weekly_bonus_service.dart';
import 'active_user_service.dart';

/// Enhanced daily bonus service with ranking integration
class DailyBonusService extends ChangeNotifier {
  static final DailyBonusService _instance = DailyBonusService._internal();
  factory DailyBonusService() => _instance;
  DailyBonusService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final WeeklyBonusService _weeklyBonusService = WeeklyBonusService();
  final ActiveUserService _activeUserService = ActiveUserService();

  Timer? _dailyCheckTimer;
  bool _isProcessingBonus = false;

  // Base daily bonus amounts
  static const int baseDailyBonus = 10;
  static const int streakMultiplier = 2;
  static const int maxStreakBonus = 50;
  
  // Ranking bonus multipliers
  static const Map<int, double> rankingMultipliers = {
    1: 2.0, // 1st place gets 2x bonus
    2: 1.5, // 2nd place gets 1.5x bonus
    3: 1.3, // 3rd place gets 1.3x bonus
  };

  /// Initialize daily bonus service
  Future<void> initialize() async {
    await _startDailyCheck();
    debugPrint('🎁 DailyBonusService initialized');
  }

  /// Start daily check timer (checks every hour)
  Future<void> _startDailyCheck() async {
    _dailyCheckTimer?.cancel();
    
    // Check every hour for daily bonus eligibility
    _dailyCheckTimer = Timer.periodic(const Duration(hours: 1), (timer) async {
      await _checkAndProcessDailyBonus();
    });

    // Also check immediately on startup
    await _checkAndProcessDailyBonus();
  }

  /// Check if user is eligible for daily bonus and process it
  Future<void> _checkAndProcessDailyBonus() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || _isProcessingBonus) return;

    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // Check if user already received bonus today
      final alreadyReceived = await _hasReceivedDailyBonus(currentUser.uid, today);
      
      if (!alreadyReceived) {
        // Check if user is active and eligible
        final isEligible = await _isUserEligibleForDailyBonus(currentUser.uid);
        
        if (isEligible) {
          await _processDailyBonus(currentUser.uid, today);
        }
      }
    } catch (e) {
      debugPrint('❌ Error in daily bonus check: $e');
    }
  }

  /// Check if user has already received daily bonus today
  Future<bool> _hasReceivedDailyBonus(String userId, DateTime date) async {
    try {
      final snapshot = await _firestore
          .collection('daily_bonuses')
          .where('userId', isEqualTo: userId)
          .where('date', isEqualTo: date.millisecondsSinceEpoch)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('❌ Error checking daily bonus: $e');
      return false;
    }
  }

  /// Check if user is eligible for daily bonus (must be active)
  Future<bool> _isUserEligibleForDailyBonus(String userId) async {
    try {
      // User must be genuinely active (real steps detected)
      final isActive = await _activeUserService.isUserGenuinelyActive(userId);
      
      if (!isActive) {
        debugPrint('⚠️ User $userId not eligible - not genuinely active');
        return false;
      }

      // User must have taken at least some steps today
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return false;

      final userData = userDoc.data() as Map<String, dynamic>;
      final totalSteps = userData['totalSteps'] ?? 0;

      // Must have at least 100 steps to be eligible
      if (totalSteps < 100) {
        debugPrint('⚠️ User $userId not eligible - insufficient steps ($totalSteps)');
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('❌ Error checking user eligibility: $e');
      return false;
    }
  }

  /// Process daily bonus for user
  Future<void> _processDailyBonus(String userId, DateTime date) async {
    if (_isProcessingBonus) return;
    
    _isProcessingBonus = true;
    
    try {
      debugPrint('🎁 Processing daily bonus for user: $userId');
      
      // Calculate bonus amount
      final bonusData = await _calculateDailyBonus(userId);
      final totalBonus = bonusData['totalBonus'] as int;
      final streakDays = bonusData['streakDays'] as int;
      final rankingBonus = bonusData['rankingBonus'] as int;
      final weeklyPosition = bonusData['weeklyPosition'] as int?;

      final batch = _firestore.batch();
      final now = DateTime.now();

      // Add coins to user
      final userRef = _firestore.collection('users').doc(userId);
      batch.update(userRef, {
        'totalCoins': FieldValue.increment(totalBonus),
        'dailyBonusStreak': streakDays,
        'lastDailyBonus': now.millisecondsSinceEpoch,
      });

      // Record daily bonus transaction
      final transactionRef = _firestore.collection('coin_transactions').doc();
      batch.set(transactionRef, {
        'userId': userId,
        'amount': totalBonus,
        'type': 'daily_bonus',
        'description': 'Kunlik faollik bonusi',
        'date': date.millisecondsSinceEpoch,
        'createdAt': now.millisecondsSinceEpoch,
        'metadata': {
          'baseBonus': baseDailyBonus,
          'streakDays': streakDays,
          'streakBonus': totalBonus - baseDailyBonus - rankingBonus,
          'rankingBonus': rankingBonus,
          'weeklyPosition': weeklyPosition,
        },
      });

      // Record daily bonus history
      final bonusRef = _firestore.collection('daily_bonuses').doc();
      batch.set(bonusRef, {
        'userId': userId,
        'amount': totalBonus,
        'date': date.millisecondsSinceEpoch,
        'streakDays': streakDays,
        'rankingBonus': rankingBonus,
        'weeklyPosition': weeklyPosition,
        'createdAt': now.millisecondsSinceEpoch,
      });

      await batch.commit();

      // Send notification
      await _sendDailyBonusNotification(userId, totalBonus, streakDays, weeklyPosition);

      debugPrint('✅ Daily bonus processed: $totalBonus coins (streak: $streakDays days)');
      notifyListeners();

    } catch (e) {
      debugPrint('❌ Error processing daily bonus: $e');
    } finally {
      _isProcessingBonus = false;
    }
  }

  /// Calculate daily bonus amount based on streak and ranking
  Future<Map<String, dynamic>> _calculateDailyBonus(String userId) async {
    try {
      // Get user's current streak
      final streakDays = await _getUserStreakDays(userId);
      
      // Get user's weekly ranking position
      final weeklyPosition = await _weeklyBonusService.getCurrentUserWeeklyPosition(userId);
      
      // Calculate base bonus with streak
      int baseBonus = baseDailyBonus;
      int streakBonus = min(streakDays * streakMultiplier, maxStreakBonus);
      
      // Calculate ranking bonus
      int rankingBonus = 0;
      if (weeklyPosition != null && rankingMultipliers.containsKey(weeklyPosition)) {
        final multiplier = rankingMultipliers[weeklyPosition]!;
        rankingBonus = ((baseBonus + streakBonus) * (multiplier - 1)).round();
      }
      
      final totalBonus = baseBonus + streakBonus + rankingBonus;

      return {
        'totalBonus': totalBonus,
        'baseBonus': baseBonus,
        'streakBonus': streakBonus,
        'rankingBonus': rankingBonus,
        'streakDays': streakDays + 1, // Next day's streak
        'weeklyPosition': weeklyPosition,
      };
    } catch (e) {
      debugPrint('❌ Error calculating daily bonus: $e');
      return {
        'totalBonus': baseDailyBonus,
        'baseBonus': baseDailyBonus,
        'streakBonus': 0,
        'rankingBonus': 0,
        'streakDays': 1,
        'weeklyPosition': null,
      };
    }
  }

  /// Get user's current streak days
  Future<int> _getUserStreakDays(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return 0;

      final userData = userDoc.data() as Map<String, dynamic>;
      final lastBonusTime = userData['lastDailyBonus'] as int?;
      final currentStreak = userData['dailyBonusStreak'] as int? ?? 0;

      if (lastBonusTime == null) return 0;

      final lastBonusDate = DateTime.fromMillisecondsSinceEpoch(lastBonusTime);
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayDate = DateTime(yesterday.year, yesterday.month, yesterday.day);
      final lastBonusDateOnly = DateTime(lastBonusDate.year, lastBonusDate.month, lastBonusDate.day);

      // Check if last bonus was yesterday (consecutive days)
      if (lastBonusDateOnly.isAtSameMomentAs(yesterdayDate)) {
        return currentStreak;
      } else {
        // Streak broken, start over
        return 0;
      }
    } catch (e) {
      debugPrint('❌ Error getting user streak: $e');
      return 0;
    }
  }

  /// Send daily bonus notification
  Future<void> _sendDailyBonusNotification(String userId, int amount, int streakDays, int? weeklyPosition) async {
    try {
      String title = '🎁 Kunlik bonus!';
      String body = '$amount tanga oldingiz!';
      
      if (streakDays > 1) {
        body += ' ($streakDays kun ketma-ket)';
      }
      
      if (weeklyPosition != null && weeklyPosition <= 3) {
        String positionEmoji = weeklyPosition == 1 ? '🥇' : weeklyPosition == 2 ? '🥈' : '🥉';
        body += ' $positionEmoji Haftalik reyting bonusi!';
      }

      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'type': 'daily_bonus',
        'data': {
          'amount': amount,
          'streakDays': streakDays,
          'weeklyPosition': weeklyPosition,
        },
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'isRead': false,
      });

      debugPrint('📱 Daily bonus notification sent');
    } catch (e) {
      debugPrint('❌ Error sending daily bonus notification: $e');
    }
  }

  /// Manual trigger for daily bonus (for testing)
  Future<void> triggerDailyBonus() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    
    await _processDailyBonus(currentUser.uid, todayDate);
  }

  /// Get user's daily bonus history
  Future<List<Map<String, dynamic>>> getUserDailyBonusHistory(String userId, {int limit = 30}) async {
    try {
      final snapshot = await _firestore
          .collection('daily_bonuses')
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      debugPrint('❌ Error getting daily bonus history: $e');
      return [];
    }
  }

  /// Get current user's streak info
  Future<Map<String, dynamic>> getCurrentUserStreakInfo() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return {};

    try {
      final streakDays = await _getUserStreakDays(currentUser.uid);
      final weeklyPosition = await _weeklyBonusService.getCurrentUserWeeklyPosition(currentUser.uid);
      final bonusData = await _calculateDailyBonus(currentUser.uid);

      return {
        'streakDays': streakDays,
        'weeklyPosition': weeklyPosition,
        'nextBonusAmount': bonusData['totalBonus'],
        'hasRankingBonus': weeklyPosition != null && weeklyPosition <= 3,
      };
    } catch (e) {
      debugPrint('❌ Error getting streak info: $e');
      return {};
    }
  }

  @override
  void dispose() {
    _dailyCheckTimer?.cancel();
    super.dispose();
  }
}
