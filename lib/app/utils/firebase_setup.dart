import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Firebase Collections Setup and Management
class FirebaseSetup {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Initialize all required Firebase collections and indexes
  static Future<void> initializeFirebaseCollections() async {
    try {
      debugPrint('🔥 Initializing Firebase Collections...');

      // Create sample data for testing
      await _createSampleUsers();
      await _createSampleRankings();
      await _createIndexes();

      debugPrint('✅ Firebase Collections initialized successfully!');
    } catch (e) {
      debugPrint('❌ Error initializing Firebase Collections: $e');
    }
  }

  /// Create sample users for testing
  static Future<void> _createSampleUsers() async {
    final batch = _firestore.batch();
    
    // Sample users data
    final sampleUsers = [
      {
        'name': 'Ahmad Karimov',
        'email': 'ahmad@example.com',
        'totalSteps': 15000,
        'totalCoins': 500,
        'level': 5,
        'photoUrl': null,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
        'weeklySteps': 3500,
        'monthlySteps': 15000,
        'friends': [],
        'achievements': [],
        'isActive': true,
      },
      {
        'name': 'Malika Tosheva',
        'email': 'malika@example.com',
        'totalSteps': 12500,
        'totalCoins': 400,
        'level': 4,
        'photoUrl': null,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
        'weeklySteps': 3200,
        'monthlySteps': 12500,
        'friends': [],
        'achievements': [],
        'isActive': true,
      },
      {
        'name': 'Bobur Aliyev',
        'email': 'bobur@example.com',
        'totalSteps': 18000,
        'totalCoins': 600,
        'level': 6,
        'photoUrl': null,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
        'weeklySteps': 4000,
        'monthlySteps': 18000,
        'friends': [],
        'achievements': [],
        'isActive': true,
      },
      {
        'name': 'Dilnoza Rahimova',
        'email': 'dilnoza@example.com',
        'totalSteps': 9500,
        'totalCoins': 300,
        'level': 3,
        'photoUrl': null,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
        'weeklySteps': 2800,
        'monthlySteps': 9500,
        'friends': [],
        'achievements': [],
        'isActive': true,
      },
      {
        'name': 'Sardor Umarov',
        'email': 'sardor@example.com',
        'totalSteps': 22000,
        'totalCoins': 800,
        'level': 7,
        'photoUrl': null,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
        'weeklySteps': 5000,
        'monthlySteps': 22000,
        'friends': [],
        'achievements': [],
        'isActive': true,
      },
    ];

    // Add sample users to Firestore
    for (int i = 0; i < sampleUsers.length; i++) {
      final userRef = _firestore.collection('users').doc('sample_user_$i');
      batch.set(userRef, sampleUsers[i]);
    }

    await batch.commit();
    debugPrint('✅ Sample users created');
  }

  /// Create sample rankings
  static Future<void> _createSampleRankings() async {
    final batch = _firestore.batch();
    final now = DateTime.now();
    final weekStart = _getWeekStart(now);
    final monthStart = _getMonthStart(now);

    // Create weekly rankings
    final weeklyRankings = [
      {'userId': 'sample_user_4', 'steps': 5000, 'rank': 1},
      {'userId': 'sample_user_2', 'steps': 4000, 'rank': 2},
      {'userId': 'sample_user_0', 'steps': 3500, 'rank': 3},
      {'userId': 'sample_user_1', 'steps': 3200, 'rank': 4},
      {'userId': 'sample_user_3', 'steps': 2800, 'rank': 5},
    ];

    for (final ranking in weeklyRankings) {
      final weeklyRef = _firestore.collection('weekly_rankings')
          .doc('${weekStart.millisecondsSinceEpoch}_${ranking['userId']}');
      
      batch.set(weeklyRef, {
        'userId': ranking['userId'],
        'steps': ranking['steps'],
        'rank': ranking['rank'],
        'weekStart': weekStart.millisecondsSinceEpoch,
        'lastUpdated': now.millisecondsSinceEpoch,
      });
    }

    // Create monthly rankings
    final monthlyRankings = [
      {'userId': 'sample_user_4', 'steps': 22000, 'rank': 1},
      {'userId': 'sample_user_2', 'steps': 18000, 'rank': 2},
      {'userId': 'sample_user_0', 'steps': 15000, 'rank': 3},
      {'userId': 'sample_user_1', 'steps': 12500, 'rank': 4},
      {'userId': 'sample_user_3', 'steps': 9500, 'rank': 5},
    ];

    for (final ranking in monthlyRankings) {
      final monthlyRef = _firestore.collection('monthly_rankings')
          .doc('${monthStart.millisecondsSinceEpoch}_${ranking['userId']}');
      
      batch.set(monthlyRef, {
        'userId': ranking['userId'],
        'steps': ranking['steps'],
        'rank': ranking['rank'],
        'monthStart': monthStart.millisecondsSinceEpoch,
        'lastUpdated': now.millisecondsSinceEpoch,
      });
    }

    // Create global rankings
    final globalRankings = [
      {'userId': 'sample_user_4', 'totalSteps': 22000, 'rank': 1},
      {'userId': 'sample_user_2', 'totalSteps': 18000, 'rank': 2},
      {'userId': 'sample_user_0', 'totalSteps': 15000, 'rank': 3},
      {'userId': 'sample_user_1', 'totalSteps': 12500, 'rank': 4},
      {'userId': 'sample_user_3', 'totalSteps': 9500, 'rank': 5},
    ];

    for (final ranking in globalRankings) {
      final rankingRef = _firestore.collection('rankings').doc(ranking['userId'] as String);
      
      batch.set(rankingRef, {
        'userId': ranking['userId'],
        'totalSteps': ranking['totalSteps'],
        'rank': ranking['rank'],
        'lastUpdated': now.millisecondsSinceEpoch,
      });
    }

    await batch.commit();
    debugPrint('✅ Sample rankings created');
  }

  /// Create necessary Firestore indexes
  static Future<void> _createIndexes() async {
    // Note: Firestore indexes are created automatically when queries are run
    // But we can document the required indexes here:
    
    debugPrint('📋 Required Firestore Indexes:');
    debugPrint('1. users: totalSteps (descending)');
    debugPrint('2. weekly_rankings: weekStart (ascending), steps (descending)');
    debugPrint('3. monthly_rankings: monthStart (ascending), steps (descending)');
    debugPrint('4. ranking_rewards: userId (ascending), createdAt (descending)');
    debugPrint('5. users: totalSteps (greater than) - for ranking position queries');
    
    // These indexes will be created automatically when the queries are first run
    // Or you can create them manually in Firebase Console
  }

  /// Update current user's data structure
  static Future<void> updateCurrentUserForRanking() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final userRef = _firestore.collection('users').doc(currentUser.uid);
      final userDoc = await userRef.get();

      if (userDoc.exists) {
        // Update existing user with ranking fields
        await userRef.update({
          'totalSteps': FieldValue.increment(0), // Ensure field exists
          'weeklySteps': FieldValue.increment(0),
          'monthlySteps': FieldValue.increment(0),
          'totalCoins': FieldValue.increment(0),
          'level': FieldValue.increment(0),
          'lastUpdated': DateTime.now().millisecondsSinceEpoch,
          'friends': FieldValue.arrayUnion([]), // Ensure friends array exists
          'achievements': FieldValue.arrayUnion([]),
          'isActive': true,
        });
      } else {
        // Create new user document
        await userRef.set({
          'name': currentUser.displayName ?? 'Foydalanuvchi',
          'email': currentUser.email ?? '',
          'photoUrl': currentUser.photoURL,
          'totalSteps': 0,
          'weeklySteps': 0,
          'monthlySteps': 0,
          'totalCoins': 0,
          'level': 1,
          'createdAt': DateTime.now().millisecondsSinceEpoch,
          'lastUpdated': DateTime.now().millisecondsSinceEpoch,
          'friends': [],
          'achievements': [],
          'isActive': true,
        });
      }

      debugPrint('✅ Current user updated for ranking system');
    } catch (e) {
      debugPrint('❌ Error updating current user: $e');
    }
  }

  /// Helper methods
  static DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return DateTime(date.year, date.month, date.day - (weekday - 1));
  }

  static DateTime _getMonthStart(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// Clean up old ranking data (call this periodically)
  static Future<void> cleanupOldRankings() async {
    try {
      final now = DateTime.now();
      final oneMonthAgo = now.subtract(const Duration(days: 30));
      final threeMonthsAgo = now.subtract(const Duration(days: 90));

      // Clean up old weekly rankings (older than 1 month)
      final oldWeeklyQuery = await _firestore
          .collection('weekly_rankings')
          .where('weekStart', isLessThan: oneMonthAgo.millisecondsSinceEpoch)
          .get();

      final batch = _firestore.batch();
      for (final doc in oldWeeklyQuery.docs) {
        batch.delete(doc.reference);
      }

      // Clean up old monthly rankings (older than 3 months)
      final oldMonthlyQuery = await _firestore
          .collection('monthly_rankings')
          .where('monthStart', isLessThan: threeMonthsAgo.millisecondsSinceEpoch)
          .get();

      for (final doc in oldMonthlyQuery.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      debugPrint('✅ Old ranking data cleaned up');
    } catch (e) {
      debugPrint('❌ Error cleaning up old rankings: $e');
    }
  }
}

/// Firebase Collections Structure Documentation
/// 
/// 1. users/
///    - userId (document ID)
///    - name: string
///    - email: string
///    - photoUrl: string?
///    - totalSteps: number
///    - weeklySteps: number
///    - monthlySteps: number
///    - totalCoins: number
///    - level: number
///    - createdAt: timestamp
///    - lastUpdated: timestamp
///    - friends: array<string>
///    - achievements: array<string>
///    - isActive: boolean
/// 
/// 2. rankings/
///    - userId (document ID)
///    - totalSteps: number
///    - rank: number
///    - lastUpdated: timestamp
/// 
/// 3. weekly_rankings/
///    - {weekStart}_{userId} (document ID)
///    - userId: string
///    - steps: number
///    - rank: number
///    - weekStart: timestamp
///    - lastUpdated: timestamp
/// 
/// 4. monthly_rankings/
///    - {monthStart}_{userId} (document ID)
///    - userId: string
///    - steps: number
///    - rank: number
///    - monthStart: timestamp
///    - lastUpdated: timestamp
/// 
/// 5. ranking_rewards/
///    - rewardId (auto-generated document ID)
///    - userId: string
///    - position: number (1, 2, 3)
///    - coins: number
///    - title: string
///    - emoji: string
///    - type: string ('weekly', 'monthly')
///    - createdAt: timestamp
///    - weekStart?: timestamp
///    - monthStart?: timestamp
