import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

/// 🎯 Progressive Login Streak Service
/// Week 1: 10 coins/day, Week 2: 15 coins/day, Week 3: 20 coins/day, etc.
class ProgressiveLoginStreakService extends ChangeNotifier {
  static final ProgressiveLoginStreakService _instance = ProgressiveLoginStreakService._internal();
  factory ProgressiveLoginStreakService() => _instance;
  ProgressiveLoginStreakService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Timer? _dailyCheckTimer;
  bool _isProcessingStreak = false;

  // Progressive streak constants
  static const int baseCoinsPerDay = 10;
  static const int weeklyBonusIncrement = 5;
  static const int daysPerWeek = 7;

  /// Initialize progressive login streak service
  Future<void> initialize() async {
    await _startDailyCheck();
    debugPrint('🎯 ProgressiveLoginStreakService initialized');
  }

  /// Start daily check timer
  Future<void> _startDailyCheck() async {
    _dailyCheckTimer?.cancel();
    
    // Check every hour for login streak
    _dailyCheckTimer = Timer.periodic(const Duration(hours: 1), (timer) async {
      await _checkAndProcessDailyStreak();
    });

    // Also check immediately on startup
    await _checkAndProcessDailyStreak();
  }

  /// Check and process daily login streak
  Future<void> _checkAndProcessDailyStreak() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || _isProcessingStreak) return;

    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // Check if user already received streak bonus today
      final alreadyReceived = await _hasReceivedStreakBonusToday(currentUser.uid, today);
      
      if (!alreadyReceived) {
        await _processLoginStreak(currentUser.uid, today);
      }
    } catch (e) {
      debugPrint('❌ Error in daily streak check: $e');
    }
  }

  /// Check if user has already received streak bonus today
  Future<bool> _hasReceivedStreakBonusToday(String userId, DateTime date) async {
    try {
      final snapshot = await _firestore
          .collection('login_streak_bonuses')
          .where('userId', isEqualTo: userId)
          .where('date', isEqualTo: date.millisecondsSinceEpoch)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('❌ Error checking streak bonus: $e');
      return false;
    }
  }

  /// Process login streak for user
  Future<void> _processLoginStreak(String userId, DateTime date) async {
    if (_isProcessingStreak) return;
    
    _isProcessingStreak = true;
    
    try {
      debugPrint('🎯 Processing login streak for user: $userId');
      
      // Get current streak data
      final streakData = await _calculateStreakBonus(userId, date);
      final streakDays = streakData['streakDays'] as int;
      final currentWeek = streakData['currentWeek'] as int;
      final dayInWeek = streakData['dayInWeek'] as int;
      final coinsPerDay = streakData['coinsPerDay'] as int;
      final isNewWeek = streakData['isNewWeek'] as bool;

      final batch = _firestore.batch();
      final now = DateTime.now();

      // Add coins to user
      final userRef = _firestore.collection('users').doc(userId);
      batch.update(userRef, {
        'totalCoins': FieldValue.increment(coinsPerDay),
        'loginStreakDays': streakDays,
        'loginStreakWeek': currentWeek,
        'lastLoginDate': now.millisecondsSinceEpoch,
      });

      // Record streak bonus transaction
      final transactionRef = _firestore.collection('coin_transactions').doc();
      batch.set(transactionRef, {
        'userId': userId,
        'amount': coinsPerDay,
        'type': 'progressive_login_streak',
        'description': 'Progressiv login streak bonusi - $currentWeek-hafta, $dayInWeek-kun',
        'date': date.millisecondsSinceEpoch,
        'createdAt': now.millisecondsSinceEpoch,
        'metadata': {
          'streakDays': streakDays,
          'currentWeek': currentWeek,
          'dayInWeek': dayInWeek,
          'coinsPerDay': coinsPerDay,
          'isNewWeek': isNewWeek,
        },
      });

      // Record login streak bonus history
      final streakRef = _firestore.collection('login_streak_bonuses').doc();
      batch.set(streakRef, {
        'userId': userId,
        'amount': coinsPerDay,
        'date': date.millisecondsSinceEpoch,
        'streakDays': streakDays,
        'currentWeek': currentWeek,
        'dayInWeek': dayInWeek,
        'isNewWeek': isNewWeek,
        'createdAt': now.millisecondsSinceEpoch,
      });

      await batch.commit();

      // Send notification
      await _sendStreakNotification(userId, coinsPerDay, streakDays, currentWeek, dayInWeek, isNewWeek);

      debugPrint('✅ Login streak processed: $coinsPerDay coins (Week $currentWeek, Day $dayInWeek)');
      notifyListeners();

    } catch (e) {
      debugPrint('❌ Error processing login streak: $e');
    } finally {
      _isProcessingStreak = false;
    }
  }

  /// Calculate streak bonus based on progressive system
  Future<Map<String, dynamic>> _calculateStreakBonus(String userId, DateTime date) async {
    try {
      // Get user's current streak data
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.exists ? userDoc.data() as Map<String, dynamic> : {};
      
      final lastLoginTime = userData['lastLoginDate'] as int?;
      final currentStreakDays = userData['loginStreakDays'] as int? ?? 0;
      final currentStreakWeek = userData['loginStreakWeek'] as int? ?? 0;

      int newStreakDays;
      int newStreakWeek;
      bool isNewWeek = false;

      if (lastLoginTime == null) {
        // First time login
        newStreakDays = 1;
        newStreakWeek = 1;
        isNewWeek = true;
      } else {
        final lastLoginDate = DateTime.fromMillisecondsSinceEpoch(lastLoginTime);
        final lastLoginDateOnly = DateTime(lastLoginDate.year, lastLoginDate.month, lastLoginDate.day);
        final yesterday = date.subtract(const Duration(days: 1));

        if (lastLoginDateOnly.isAtSameMomentAs(yesterday)) {
          // Consecutive day
          newStreakDays = currentStreakDays + 1;
          
          // Check if we're starting a new week
          if (newStreakDays % daysPerWeek == 1 && newStreakDays > 1) {
            newStreakWeek = currentStreakWeek + 1;
            isNewWeek = true;
          } else {
            newStreakWeek = currentStreakWeek;
          }
        } else if (lastLoginDateOnly.isAtSameMomentAs(date)) {
          // Same day (shouldn't happen due to check above, but safety)
          return {
            'streakDays': currentStreakDays,
            'currentWeek': currentStreakWeek,
            'dayInWeek': ((currentStreakDays - 1) % daysPerWeek) + 1,
            'coinsPerDay': _calculateCoinsForWeek(currentStreakWeek),
            'isNewWeek': false,
          };
        } else {
          // Streak broken, restart
          newStreakDays = 1;
          newStreakWeek = 1;
          isNewWeek = true;
        }
      }

      final dayInWeek = ((newStreakDays - 1) % daysPerWeek) + 1;
      final coinsPerDay = _calculateCoinsForWeek(newStreakWeek);

      return {
        'streakDays': newStreakDays,
        'currentWeek': newStreakWeek,
        'dayInWeek': dayInWeek,
        'coinsPerDay': coinsPerDay,
        'isNewWeek': isNewWeek,
      };
    } catch (e) {
      debugPrint('❌ Error calculating streak bonus: $e');
      return {
        'streakDays': 1,
        'currentWeek': 1,
        'dayInWeek': 1,
        'coinsPerDay': baseCoinsPerDay,
        'isNewWeek': true,
      };
    }
  }

  /// Calculate coins per day for given week
  int _calculateCoinsForWeek(int week) {
    return baseCoinsPerDay + ((week - 1) * weeklyBonusIncrement);
  }

  /// Send streak notification
  Future<void> _sendStreakNotification(
    String userId,
    int coins,
    int streakDays,
    int currentWeek,
    int dayInWeek,
    bool isNewWeek,
  ) async {
    try {
      String title;
      String body;

      if (isNewWeek && currentWeek > 1) {
        title = '🎉 Yangi hafta boshlandi!';
        body = '$currentWeek-hafta: Endi kuniga $coins tanga olasiz! ($dayInWeek/7 kun)';
      } else if (dayInWeek == 7) {
        title = '🏆 Hafta yakunlandi!';
        body = '$currentWeek-haftani muvaffaqiyatli yakunladingiz! $coins tanga oldingiz.';
      } else {
        title = '🔥 Login streak!';
        body = '$currentWeek-hafta, $dayInWeek-kun: $coins tanga oldingiz! ($streakDays kun ketma-ket)';
      }

      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'type': 'progressive_login_streak',
        'data': {
          'coins': coins,
          'streakDays': streakDays,
          'currentWeek': currentWeek,
          'dayInWeek': dayInWeek,
          'isNewWeek': isNewWeek,
        },
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'isRead': false,
      });

      debugPrint('📱 Streak notification sent');
    } catch (e) {
      debugPrint('❌ Error sending streak notification: $e');
    }
  }

  /// Get current user's streak info
  Future<Map<String, dynamic>> getCurrentUserStreakInfo() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return {};

    try {
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (!userDoc.exists) return {};

      final userData = userDoc.data() as Map<String, dynamic>;
      final streakDays = userData['loginStreakDays'] as int? ?? 0;
      final currentWeek = userData['loginStreakWeek'] as int? ?? 1;
      final lastLoginTime = userData['lastLoginDate'] as int?;

      final dayInWeek = streakDays > 0 ? ((streakDays - 1) % daysPerWeek) + 1 : 0;
      final coinsPerDay = _calculateCoinsForWeek(currentWeek);
      final nextWeekCoins = _calculateCoinsForWeek(currentWeek + 1);

      // Check if streak is still active
      bool isStreakActive = false;
      if (lastLoginTime != null) {
        final lastLogin = DateTime.fromMillisecondsSinceEpoch(lastLoginTime);
        final lastLoginDate = DateTime(lastLogin.year, lastLogin.month, lastLogin.day);
        final today = DateTime.now();
        final todayDate = DateTime(today.year, today.month, today.day);
        final yesterday = todayDate.subtract(const Duration(days: 1));

        isStreakActive = lastLoginDate.isAtSameMomentAs(todayDate) || 
                        lastLoginDate.isAtSameMomentAs(yesterday);
      }

      return {
        'streakDays': streakDays,
        'currentWeek': currentWeek,
        'dayInWeek': dayInWeek,
        'coinsPerDay': coinsPerDay,
        'nextWeekCoins': nextWeekCoins,
        'isStreakActive': isStreakActive,
        'daysUntilNextWeek': daysPerWeek - dayInWeek,
        'totalWeeklyCoins': coinsPerDay * daysPerWeek,
      };
    } catch (e) {
      debugPrint('❌ Error getting streak info: $e');
      return {};
    }
  }

  /// Get user's streak history
  Future<List<Map<String, dynamic>>> getUserStreakHistory(String userId, {int limit = 30}) async {
    try {
      final snapshot = await _firestore
          .collection('login_streak_bonuses')
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
      debugPrint('❌ Error getting streak history: $e');
      return [];
    }
  }

  /// Manual trigger for login streak (for testing)
  Future<void> triggerLoginStreak() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    
    await _processLoginStreak(currentUser.uid, todayDate);
  }

  /// Get streak leaderboard (users with longest streaks)
  Future<List<Map<String, dynamic>>> getStreakLeaderboard({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('loginStreakDays', isGreaterThan: 0)
          .orderBy('loginStreakDays', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'userId': doc.id,
          'name': data['name'] ?? data['displayName'] ?? 'Foydalanuvchi',
          'streakDays': data['loginStreakDays'] ?? 0,
          'currentWeek': data['loginStreakWeek'] ?? 1,
          'photoUrl': data['photoUrl'],
        };
      }).toList();
    } catch (e) {
      debugPrint('❌ Error getting streak leaderboard: $e');
      return [];
    }
  }

  @override
  void dispose() {
    _dailyCheckTimer?.cancel();
    super.dispose();
  }
}
