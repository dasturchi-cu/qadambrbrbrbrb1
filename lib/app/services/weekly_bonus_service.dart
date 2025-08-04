import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/ranking_model.dart';
import 'firebase_ranking_service.dart';
import 'active_user_service.dart';

/// Service for automated weekly bonus distribution
class WeeklyBonusService extends ChangeNotifier {
  static final WeeklyBonusService _instance = WeeklyBonusService._internal();
  factory WeeklyBonusService() => _instance;
  WeeklyBonusService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseRankingService _rankingService = FirebaseRankingService();
  final ActiveUserService _activeUserService = ActiveUserService();

  Timer? _weeklyCheckTimer;
  bool _isDistributingRewards = false;

  // Bonus amounts
  static const Map<int, int> weeklyRewards = {
    1: 200, // 1st place
    2: 100, // 2nd place  
    3: 50,  // 3rd place
  };

  /// Initialize weekly bonus automation
  Future<void> initialize() async {
    await _startWeeklyCheck();
    debugPrint('💰 WeeklyBonusService initialized');
  }

  /// Start weekly check timer (checks every hour)
  Future<void> _startWeeklyCheck() async {
    _weeklyCheckTimer?.cancel();
    
    // Check every hour if it's time for weekly distribution
    _weeklyCheckTimer = Timer.periodic(const Duration(hours: 1), (timer) async {
      await _checkAndDistributeWeeklyRewards();
    });

    // Also check immediately on startup
    await _checkAndDistributeWeeklyRewards();
  }

  /// Check if it's time to distribute weekly rewards and do it
  Future<void> _checkAndDistributeWeeklyRewards() async {
    if (_isDistributingRewards) return;

    try {
      final now = DateTime.now();
      
      // Check if it's Sunday evening (end of week) and we haven't distributed yet
      if (now.weekday == DateTime.sunday && now.hour >= 20) {
        final weekStart = _getWeekStart(now);
        
        // Check if we already distributed for this week
        final alreadyDistributed = await _hasWeeklyRewardsBeenDistributed(weekStart);
        
        if (!alreadyDistributed) {
          await _distributeWeeklyRewards(weekStart);
        }
      }
    } catch (e) {
      debugPrint('❌ Error in weekly check: $e');
    }
  }

  /// Check if weekly rewards have already been distributed for this week
  Future<bool> _hasWeeklyRewardsBeenDistributed(DateTime weekStart) async {
    try {
      final snapshot = await _firestore
          .collection('weekly_rewards_history')
          .where('weekStart', isEqualTo: weekStart.millisecondsSinceEpoch)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('❌ Error checking weekly rewards distribution: $e');
      return false;
    }
  }

  /// Distribute weekly rewards to top 3 active users
  Future<void> _distributeWeeklyRewards(DateTime weekStart) async {
    if (_isDistributingRewards) return;
    
    _isDistributingRewards = true;
    
    try {
      debugPrint('🏆 Starting weekly rewards distribution...');
      
      // Get top active users for this week
      final topUsers = await _getTopActiveUsersForWeek(weekStart);
      
      if (topUsers.length < 3) {
        debugPrint('⚠️ Not enough active users for weekly rewards (${topUsers.length})');
        _isDistributingRewards = false;
        return;
      }

      final batch = _firestore.batch();
      final now = DateTime.now();
      final rewardedUsers = <Map<String, dynamic>>[];

      // Distribute rewards to top 3
      for (int i = 0; i < 3 && i < topUsers.length; i++) {
        final user = topUsers[i];
        final position = i + 1;
        final reward = weeklyRewards[position]!;
        
        // Add coins to user
        final userRef = _firestore.collection('users').doc(user['userId']);
        batch.update(userRef, {
          'totalCoins': FieldValue.increment(reward),
          'weeklyRewardsReceived': FieldValue.increment(1),
        });

        // Record reward transaction
        final rewardRef = _firestore.collection('coin_transactions').doc();
        batch.set(rewardRef, {
          'userId': user['userId'],
          'amount': reward,
          'type': 'weekly_ranking_reward',
          'description': 'Haftalik reyting mukofoti - ${position}-o\'rin',
          'position': position,
          'weekStart': weekStart.millisecondsSinceEpoch,
          'createdAt': now.millisecondsSinceEpoch,
          'metadata': {
            'totalSteps': user['totalSteps'],
            'weeklySteps': user['weeklySteps'],
            'rank': position,
          },
        });

        rewardedUsers.add({
          'userId': user['userId'],
          'name': user['name'],
          'position': position,
          'reward': reward,
          'totalSteps': user['totalSteps'],
        });
      }

      // Record weekly distribution history
      final historyRef = _firestore.collection('weekly_rewards_history').doc();
      batch.set(historyRef, {
        'weekStart': weekStart.millisecondsSinceEpoch,
        'weekEnd': now.millisecondsSinceEpoch,
        'distributedAt': now.millisecondsSinceEpoch,
        'totalActiveUsers': topUsers.length,
        'rewardedUsers': rewardedUsers,
        'totalCoinsDistributed': weeklyRewards.values.take(3).reduce((a, b) => a + b),
      });

      await batch.commit();

      // Send notifications to winners
      await _sendWeeklyRewardNotifications(rewardedUsers);

      debugPrint('✅ Weekly rewards distributed successfully!');
      debugPrint('🥇 1st: ${rewardedUsers[0]['name']} - ${rewardedUsers[0]['reward']} coins');
      debugPrint('🥈 2nd: ${rewardedUsers[1]['name']} - ${rewardedUsers[1]['reward']} coins');
      debugPrint('🥉 3rd: ${rewardedUsers[2]['name']} - ${rewardedUsers[2]['reward']} coins');

      notifyListeners();

    } catch (e) {
      debugPrint('❌ Error distributing weekly rewards: $e');
    } finally {
      _isDistributingRewards = false;
    }
  }

  /// Get top active users for the week
  Future<List<Map<String, dynamic>>> _getTopActiveUsersForWeek(DateTime weekStart) async {
    try {
      // Get all active users with step data
      final activeUsers = await _activeUserService.getActiveUsersWithSteps();
      
      // Filter users who were active during this week
      final weekEnd = weekStart.add(const Duration(days: 7));
      final weekActiveUsers = <Map<String, dynamic>>[];

      for (final user in activeUsers) {
        final lastStepUpdate = DateTime.fromMillisecondsSinceEpoch(user['lastStepUpdate'] ?? 0);
        
        // Check if user was active during this week
        if (lastStepUpdate.isAfter(weekStart) && lastStepUpdate.isBefore(weekEnd)) {
          // Get weekly steps for this specific week
          final weeklySteps = await _getUserWeeklySteps(user['userId'], weekStart);
          
          weekActiveUsers.add({
            ...user,
            'weeklySteps': weeklySteps,
          });
        }
      }

      // Sort by weekly steps (not total steps)
      weekActiveUsers.sort((a, b) => (b['weeklySteps'] as int).compareTo(a['weeklySteps'] as int));

      return weekActiveUsers;
    } catch (e) {
      debugPrint('❌ Error getting top active users for week: $e');
      return [];
    }
  }

  /// Get user's weekly steps for specific week
  Future<int> _getUserWeeklySteps(String userId, DateTime weekStart) async {
    try {
      final doc = await _firestore
          .collection('weekly_rankings')
          .doc('${weekStart.millisecondsSinceEpoch}_$userId')
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['steps'] ?? 0;
      }
      
      return 0;
    } catch (e) {
      debugPrint('❌ Error getting user weekly steps: $e');
      return 0;
    }
  }

  /// Send notifications to weekly reward winners
  Future<void> _sendWeeklyRewardNotifications(List<Map<String, dynamic>> winners) async {
    try {
      final batch = _firestore.batch();
      final now = DateTime.now();

      for (final winner in winners) {
        final notificationRef = _firestore.collection('notifications').doc();
        
        String emoji = '';
        String title = '';
        
        switch (winner['position']) {
          case 1:
            emoji = '🥇';
            title = 'Birinchi o\'rin!';
            break;
          case 2:
            emoji = '🥈';
            title = 'Ikkinchi o\'rin!';
            break;
          case 3:
            emoji = '🥉';
            title = 'Uchinchi o\'rin!';
            break;
        }

        batch.set(notificationRef, {
          'userId': winner['userId'],
          'title': '$emoji $title',
          'body': 'Haftalik reytingda ${winner['position']}-o\'rinni egallading! ${winner['reward']} tanga mukofot oldingiz.',
          'type': 'weekly_reward',
          'data': {
            'position': winner['position'],
            'reward': winner['reward'],
            'totalSteps': winner['totalSteps'],
          },
          'createdAt': now.millisecondsSinceEpoch,
          'isRead': false,
        });
      }

      await batch.commit();
      debugPrint('📱 Weekly reward notifications sent');
    } catch (e) {
      debugPrint('❌ Error sending weekly reward notifications: $e');
    }
  }

  /// Manual trigger for weekly rewards (for testing)
  Future<void> triggerWeeklyRewards() async {
    final now = DateTime.now();
    final weekStart = _getWeekStart(now);
    await _distributeWeeklyRewards(weekStart);
  }

  /// Get weekly rewards history
  Future<List<Map<String, dynamic>>> getWeeklyRewardsHistory({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection('weekly_rewards_history')
          .orderBy('distributedAt', descending: true)
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
      debugPrint('❌ Error getting weekly rewards history: $e');
      return [];
    }
  }

  /// Helper method to get week start (Monday)
  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return DateTime(date.year, date.month, date.day - (weekday - 1));
  }

  /// Get current week's top users preview
  Future<List<Map<String, dynamic>>> getCurrentWeekTopUsers() async {
    final now = DateTime.now();
    final weekStart = _getWeekStart(now);
    return await _getTopActiveUsersForWeek(weekStart);
  }

  /// Check if current user is in top 3 this week
  Future<int?> getCurrentUserWeeklyPosition(String userId) async {
    final topUsers = await getCurrentWeekTopUsers();
    
    for (int i = 0; i < topUsers.length; i++) {
      if (topUsers[i]['userId'] == userId) {
        return i + 1;
      }
    }
    
    return null;
  }

  @override
  void dispose() {
    _weeklyCheckTimer?.cancel();
    super.dispose();
  }
}
