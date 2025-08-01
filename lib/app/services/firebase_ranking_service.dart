import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/ranking_model.dart';
import 'active_user_service.dart';

class FirebaseRankingService {
  static final FirebaseRankingService _instance =
      FirebaseRankingService._internal();
  factory FirebaseRankingService() => _instance;
  FirebaseRankingService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ActiveUserService _activeUserService = ActiveUserService();

  // Collection references
  CollectionReference get _usersCollection => _firestore.collection('users');
  CollectionReference get _rankingsCollection =>
      _firestore.collection('rankings');
  CollectionReference get _weeklyRankingsCollection =>
      _firestore.collection('weekly_rankings');
  CollectionReference get _monthlyRankingsCollection =>
      _firestore.collection('monthly_rankings');
  CollectionReference get _rewardsCollection =>
      _firestore.collection('ranking_rewards');

  /// Update user's step count and recalculate rankings
  Future<void> updateUserSteps(String userId, int steps) async {
    try {
      final batch = _firestore.batch();
      final now = DateTime.now();

      // Update user's total steps
      final userRef = _usersCollection.doc(userId);
      batch.update(userRef, {
        'totalSteps': steps,
        'lastUpdated': now.millisecondsSinceEpoch,
      });

      // Update weekly steps
      final weekStart = _getWeekStart(now);
      final weeklyRef = _weeklyRankingsCollection
          .doc('${weekStart.millisecondsSinceEpoch}_$userId');
      batch.set(
          weeklyRef,
          {
            'userId': userId,
            'steps': steps,
            'weekStart': weekStart.millisecondsSinceEpoch,
            'lastUpdated': now.millisecondsSinceEpoch,
          },
          SetOptions(merge: true));

      // Update monthly steps
      final monthStart = _getMonthStart(now);
      final monthlyRef = _monthlyRankingsCollection
          .doc('${monthStart.millisecondsSinceEpoch}_$userId');
      batch.set(
          monthlyRef,
          {
            'userId': userId,
            'steps': steps,
            'monthStart': monthStart.millisecondsSinceEpoch,
            'lastUpdated': now.millisecondsSinceEpoch,
          },
          SetOptions(merge: true));

      await batch.commit();

      // Recalculate rankings after update
      await _recalculateRankings();
    } catch (e) {
      debugPrint('Error updating user steps: $e');
      rethrow;
    }
  }

  /// Get global rankings (top 50) - Only active users with real steps
  Future<List<RankingModel>> getGlobalRankings({int limit = 50}) async {
    try {
      // Get active users with real step data
      final activeUsersData =
          await _activeUserService.getActiveUsersWithSteps();

      if (activeUsersData.isEmpty) {
        debugPrint('⚠️ No active users found for rankings');
        return [];
      }

      final rankings = <RankingModel>[];
      int rank = 1;

      // Take only the top users up to the limit
      final topUsers = activeUsersData.take(limit);

      for (final userData in topUsers) {
        final rankingData = {
          'userId': userData['userId'],
          'name': userData['name'],
          'totalSteps': userData['totalSteps'],
          'photoUrl': userData['photoUrl'],
          'level': userData['level'],
          'totalCoins': userData['totalCoins'],
          'isCurrentUser': false,
        };

        rankings.add(RankingModel.fromMap(rankingData, rank));
        rank++;
      }

      debugPrint('✅ Loaded ${rankings.length} active users in global rankings');
      return rankings;
    } catch (e) {
      debugPrint('❌ Error getting global rankings: $e');
      return [];
    }
  }

  /// Get weekly rankings
  Future<List<RankingModel>> getWeeklyRankings({int limit = 50}) async {
    try {
      final weekStart = _getWeekStart(DateTime.now());

      final snapshot = await _weeklyRankingsCollection
          .where('weekStart', isEqualTo: weekStart.millisecondsSinceEpoch)
          .orderBy('steps', descending: true)
          .limit(limit)
          .get();

      final rankings = <RankingModel>[];
      int rank = 1;

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Get user details
        final userDoc = await _usersCollection.doc(data['userId']).get();
        final userData = userDoc.data() as Map<String, dynamic>? ?? {};

        final rankingData = {
          'userId': data['userId'],
          'steps': data['steps'],
          'weeklySteps': data['steps'],
          'name':
              userData['name'] ?? userData['displayName'] ?? 'Foydalanuvchi',
          'photoUrl': userData['photoUrl'],
          'level': userData['level'] ?? 1,
        };

        rankings.add(RankingModel.fromMap(rankingData, rank));
        rank++;
      }

      return rankings;
    } catch (e) {
      debugPrint('Error getting weekly rankings: $e');
      return [];
    }
  }

  /// Get monthly rankings
  Future<List<RankingModel>> getMonthlyRankings({int limit = 50}) async {
    try {
      final monthStart = _getMonthStart(DateTime.now());

      final snapshot = await _monthlyRankingsCollection
          .where('monthStart', isEqualTo: monthStart.millisecondsSinceEpoch)
          .orderBy('steps', descending: true)
          .limit(limit)
          .get();

      final rankings = <RankingModel>[];
      int rank = 1;

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Get user details
        final userDoc = await _usersCollection.doc(data['userId']).get();
        final userData = userDoc.data() as Map<String, dynamic>? ?? {};

        final rankingData = {
          'userId': data['userId'],
          'steps': data['steps'],
          'monthlySteps': data['steps'],
          'name':
              userData['name'] ?? userData['displayName'] ?? 'Foydalanuvchi',
          'photoUrl': userData['photoUrl'],
          'level': userData['level'] ?? 1,
        };

        rankings.add(RankingModel.fromMap(rankingData, rank));
        rank++;
      }

      return rankings;
    } catch (e) {
      debugPrint('Error getting monthly rankings: $e');
      return [];
    }
  }

  /// Get friends rankings
  Future<List<RankingModel>> getFriendsRankings(String userId) async {
    try {
      // Get user's friends list
      final userDoc = await _usersCollection.doc(userId).get();
      final userData = userDoc.data() as Map<String, dynamic>? ?? {};
      final friendIds = List<String>.from(userData['friends'] ?? []);

      if (friendIds.isEmpty) return [];

      // Get friends' data
      final rankings = <RankingModel>[];
      int rank = 1;

      for (final friendId in friendIds) {
        final friendDoc = await _usersCollection.doc(friendId).get();
        if (friendDoc.exists) {
          final friendData = friendDoc.data() as Map<String, dynamic>;
          final rankingData = {
            'userId': friendId,
            ...friendData,
          };
          rankings.add(RankingModel.fromMap(rankingData, rank));
          rank++;
        }
      }

      // Sort by steps
      rankings.sort((a, b) => b.steps.compareTo(a.steps));

      // Update ranks after sorting
      for (int i = 0; i < rankings.length; i++) {
        rankings[i] = rankings[i].copyWith(rank: i + 1);
      }

      return rankings;
    } catch (e) {
      debugPrint('Error getting friends rankings: $e');
      return [];
    }
  }

  /// Distribute rewards to top 3 users
  Future<void> distributeWeeklyRewards() async {
    try {
      final topUsers = await getWeeklyRankings(limit: 3);
      final batch = _firestore.batch();
      final now = DateTime.now();

      for (final user in topUsers) {
        final reward = RankingReward.getRewardForPosition(user.rank);
        if (reward != null) {
          // Add coins to user
          final userRef = _usersCollection.doc(user.userId);
          batch.update(userRef, {
            'totalCoins': FieldValue.increment(reward.coins),
          });

          // Record reward transaction
          final rewardRef = _rewardsCollection.doc();
          batch.set(rewardRef, {
            'userId': user.userId,
            'position': user.rank,
            'coins': reward.coins,
            'title': reward.title,
            'emoji': reward.emoji,
            'type': 'weekly',
            'createdAt': now.millisecondsSinceEpoch,
            'weekStart': _getWeekStart(now).millisecondsSinceEpoch,
          });
        }
      }

      await batch.commit();
      debugPrint('Weekly rewards distributed successfully');
    } catch (e) {
      debugPrint('Error distributing weekly rewards: $e');
    }
  }

  /// Distribute monthly rewards
  Future<void> distributeMonthlyRewards() async {
    try {
      final topUsers = await getMonthlyRankings(limit: 3);
      final batch = _firestore.batch();
      final now = DateTime.now();

      for (final user in topUsers) {
        final reward = RankingReward.getRewardForPosition(user.rank);
        if (reward != null) {
          // Double rewards for monthly
          final monthlyCoins = reward.coins * 2;

          // Add coins to user
          final userRef = _usersCollection.doc(user.userId);
          batch.update(userRef, {
            'totalCoins': FieldValue.increment(monthlyCoins),
          });

          // Record reward transaction
          final rewardRef = _rewardsCollection.doc();
          batch.set(rewardRef, {
            'userId': user.userId,
            'position': user.rank,
            'coins': monthlyCoins,
            'title': '${reward.title} (Oylik)',
            'emoji': reward.emoji,
            'type': 'monthly',
            'createdAt': now.millisecondsSinceEpoch,
            'monthStart': _getMonthStart(now).millisecondsSinceEpoch,
          });
        }
      }

      await batch.commit();
      debugPrint('Monthly rewards distributed successfully');
    } catch (e) {
      debugPrint('Error distributing monthly rewards: $e');
    }
  }

  /// Get user's ranking position
  Future<int> getUserRankingPosition(String userId) async {
    try {
      final userDoc = await _usersCollection.doc(userId).get();
      if (!userDoc.exists) return -1;

      final userData = userDoc.data() as Map<String, dynamic>;
      final userSteps = userData['totalSteps'] ?? 0;

      final higherRankedCount = await _usersCollection
          .where('totalSteps', isGreaterThan: userSteps)
          .count()
          .get();

      return higherRankedCount.count! + 1;
    } catch (e) {
      debugPrint('Error getting user ranking position: $e');
      return -1;
    }
  }

  /// Private helper methods
  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return DateTime(date.year, date.month, date.day - (weekday - 1));
  }

  DateTime _getMonthStart(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// Recalculate all rankings (called periodically)
  Future<void> _recalculateRankings() async {
    try {
      // This could be optimized with Cloud Functions
      // For now, we'll just update the rankings collection
      final snapshot =
          await _usersCollection.orderBy('totalSteps', descending: true).get();

      final batch = _firestore.batch();
      int rank = 1;

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final rankingRef = _rankingsCollection.doc(doc.id);
        batch.set(
            rankingRef,
            {
              'userId': doc.id,
              'rank': rank,
              'totalSteps': data['totalSteps'] ?? 0,
              'lastUpdated': DateTime.now().millisecondsSinceEpoch,
            },
            SetOptions(merge: true));
        rank++;
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error recalculating rankings: $e');
    }
  }

  /// Stream rankings for real-time updates
  Stream<List<RankingModel>> streamGlobalRankings({int limit = 50}) {
    return _usersCollection
        .orderBy('totalSteps', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      final rankings = <RankingModel>[];
      int rank = 1;

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final rankingData = {
          'userId': doc.id,
          ...data,
        };
        rankings.add(RankingModel.fromMap(rankingData, rank));
        rank++;
      }

      return rankings;
    });
  }
}
