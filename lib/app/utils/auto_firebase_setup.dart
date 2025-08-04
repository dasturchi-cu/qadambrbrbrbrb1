import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// 🔥 AVTOMATIK FIREBASE SETUP - Bir marta ishga tushiring!
class AutoFirebaseSetup {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🚀 BARCHA COLLECTIONS VA SAMPLE DATA YARATISH
  static Future<void> setupEverything() async {
    try {
      debugPrint('🔥 AVTOMATIK FIREBASE SETUP BOSHLANDI...');
      
      // 1. Sample users yaratish
      await _createSampleUsers();
      
      // 2. Active users yaratish
      await _createActiveUsers();
      
      // 3. Rankings yaratish
      await _createRankings();
      
      // 4. Weekly rankings yaratish
      await _createWeeklyRankings();
      
      // 5. Monthly rankings yaratish
      await _createMonthlyRankings();
      
      // 6. Sample transactions yaratish
      await _createSampleTransactions();
      
      // 7. Sample daily bonuses yaratish
      await _createSampleDailyBonuses();
      
      // 8. Sample notifications yaratish
      await _createSampleNotifications();

      debugPrint('✅ BARCHA COLLECTIONS MUVAFFAQIYATLI YARATILDI!');
      debugPrint('🎉 RANKING SYSTEM TAYYOR!');
      
    } catch (e) {
      debugPrint('❌ XATOLIK: $e');
    }
  }

  /// 1. Sample users yaratish
  static Future<void> _createSampleUsers() async {
    debugPrint('👥 Sample users yaratilmoqda...');
    
    final batch = _firestore.batch();
    final now = DateTime.now();
    
    final users = [
      {
        'id': 'user_sardor',
        'name': 'Sardor Umarov',
        'email': 'sardor@example.com',
        'totalSteps': 22000,
        'totalCoins': 800,
        'level': 7,
      },
      {
        'id': 'user_bobur',
        'name': 'Bobur Aliyev', 
        'email': 'bobur@example.com',
        'totalSteps': 18000,
        'totalCoins': 600,
        'level': 6,
      },
      {
        'id': 'user_ahmad',
        'name': 'Ahmad Karimov',
        'email': 'ahmad@example.com', 
        'totalSteps': 15000,
        'totalCoins': 500,
        'level': 5,
      },
      {
        'id': 'user_malika',
        'name': 'Malika Tosheva',
        'email': 'malika@example.com',
        'totalSteps': 12500,
        'totalCoins': 400,
        'level': 4,
      },
      {
        'id': 'user_dilnoza',
        'name': 'Dilnoza Rahimova',
        'email': 'dilnoza@example.com',
        'totalSteps': 9500,
        'totalCoins': 300,
        'level': 3,
      },
    ];

    for (final user in users) {
      final userRef = _firestore.collection('users').doc(user['id'] as String);
      batch.set(userRef, {
        'name': user['name'],
        'email': user['email'],
        'displayName': user['name'],
        'totalSteps': user['totalSteps'],
        'weeklySteps': (user['totalSteps'] as int) ~/ 4,
        'monthlySteps': user['totalSteps'],
        'totalCoins': user['totalCoins'],
        'level': user['level'],
        'createdAt': now.millisecondsSinceEpoch,
        'lastUpdated': now.millisecondsSinceEpoch,
        'friends': [],
        'achievements': [],
        'isActive': true,
        'dailyBonusStreak': 3,
        'lastDailyBonus': now.subtract(const Duration(days: 1)).millisecondsSinceEpoch,
      });
    }

    await batch.commit();
    debugPrint('✅ Sample users yaratildi');
  }

  /// 2. Active users yaratish
  static Future<void> _createActiveUsers() async {
    debugPrint('🟢 Active users yaratilmoqda...');
    
    final batch = _firestore.batch();
    final now = DateTime.now();
    
    final activeUsers = [
      'user_sardor',
      'user_bobur', 
      'user_ahmad',
      'user_malika',
      'user_dilnoza',
    ];

    for (final userId in activeUsers) {
      final activeRef = _firestore.collection('active_users').doc(userId);
      batch.set(activeRef, {
        'userId': userId,
        'lastSeen': now.millisecondsSinceEpoch,
        'isActive': true,
        'lastStepUpdate': now.subtract(const Duration(minutes: 10)).millisecondsSinceEpoch,
        'currentSteps': 1000 + (activeUsers.indexOf(userId) * 500),
        'realStepsDetected': true,
      });
    }

    await batch.commit();
    debugPrint('✅ Active users yaratildi');
  }

  /// 3. Rankings yaratish
  static Future<void> _createRankings() async {
    debugPrint('🏆 Rankings yaratilmoqda...');
    
    final batch = _firestore.batch();
    final now = DateTime.now();
    
    final rankings = [
      {'userId': 'user_sardor', 'totalSteps': 22000, 'rank': 1},
      {'userId': 'user_bobur', 'totalSteps': 18000, 'rank': 2},
      {'userId': 'user_ahmad', 'totalSteps': 15000, 'rank': 3},
      {'userId': 'user_malika', 'totalSteps': 12500, 'rank': 4},
      {'userId': 'user_dilnoza', 'totalSteps': 9500, 'rank': 5},
    ];

    for (final ranking in rankings) {
      final rankingRef = _firestore.collection('rankings').doc(ranking['userId'] as String);
      batch.set(rankingRef, {
        'userId': ranking['userId'],
        'totalSteps': ranking['totalSteps'],
        'rank': ranking['rank'],
        'lastUpdated': now.millisecondsSinceEpoch,
      });
    }

    await batch.commit();
    debugPrint('✅ Rankings yaratildi');
  }

  /// 4. Weekly rankings yaratish
  static Future<void> _createWeeklyRankings() async {
    debugPrint('📅 Weekly rankings yaratilmoqda...');
    
    final batch = _firestore.batch();
    final now = DateTime.now();
    final weekStart = _getWeekStart(now);
    
    final weeklyRankings = [
      {'userId': 'user_sardor', 'steps': 5000, 'rank': 1},
      {'userId': 'user_bobur', 'steps': 4000, 'rank': 2},
      {'userId': 'user_ahmad', 'steps': 3500, 'rank': 3},
      {'userId': 'user_malika', 'steps': 3200, 'rank': 4},
      {'userId': 'user_dilnoza', 'steps': 2800, 'rank': 5},
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

    await batch.commit();
    debugPrint('✅ Weekly rankings yaratildi');
  }

  /// 5. Monthly rankings yaratish
  static Future<void> _createMonthlyRankings() async {
    debugPrint('📆 Monthly rankings yaratilmoqda...');
    
    final batch = _firestore.batch();
    final now = DateTime.now();
    final monthStart = _getMonthStart(now);
    
    final monthlyRankings = [
      {'userId': 'user_sardor', 'steps': 22000, 'rank': 1},
      {'userId': 'user_bobur', 'steps': 18000, 'rank': 2},
      {'userId': 'user_ahmad', 'steps': 15000, 'rank': 3},
      {'userId': 'user_malika', 'steps': 12500, 'rank': 4},
      {'userId': 'user_dilnoza', 'steps': 9500, 'rank': 5},
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

    await batch.commit();
    debugPrint('✅ Monthly rankings yaratildi');
  }

  /// 6. Sample transactions yaratish
  static Future<void> _createSampleTransactions() async {
    debugPrint('💰 Sample transactions yaratilmoqda...');
    
    final batch = _firestore.batch();
    final now = DateTime.now();
    
    // Weekly reward transactions
    final rewards = [
      {'userId': 'user_sardor', 'amount': 200, 'position': 1},
      {'userId': 'user_bobur', 'amount': 100, 'position': 2},
      {'userId': 'user_ahmad', 'amount': 50, 'position': 3},
    ];

    for (final reward in rewards) {
      final transactionRef = _firestore.collection('coin_transactions').doc();
      batch.set(transactionRef, {
        'userId': reward['userId'],
        'amount': reward['amount'],
        'type': 'weekly_ranking_reward',
        'description': 'Haftalik reyting mukofoti - ${reward['position']}-o\'rin',
        'position': reward['position'],
        'weekStart': _getWeekStart(now).millisecondsSinceEpoch,
        'createdAt': now.millisecondsSinceEpoch,
        'metadata': {
          'rank': reward['position'],
        },
      });
    }

    await batch.commit();
    debugPrint('✅ Sample transactions yaratildi');
  }

  /// 7. Sample daily bonuses yaratish
  static Future<void> _createSampleDailyBonuses() async {
    debugPrint('🎁 Sample daily bonuses yaratilmoqda...');
    
    final batch = _firestore.batch();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final users = ['user_sardor', 'user_bobur', 'user_ahmad'];
    
    for (int i = 0; i < users.length; i++) {
      final bonusRef = _firestore.collection('daily_bonuses').doc();
      batch.set(bonusRef, {
        'userId': users[i],
        'amount': 25 + (i * 5),
        'date': today.millisecondsSinceEpoch,
        'streakDays': 3 + i,
        'rankingBonus': 10 - (i * 2),
        'weeklyPosition': i + 1,
        'createdAt': now.millisecondsSinceEpoch,
      });
    }

    await batch.commit();
    debugPrint('✅ Sample daily bonuses yaratildi');
  }

  /// 8. Sample notifications yaratish
  static Future<void> _createSampleNotifications() async {
    debugPrint('📱 Sample notifications yaratilmoqda...');
    
    final batch = _firestore.batch();
    final now = DateTime.now();
    
    final notifications = [
      {
        'userId': 'user_sardor',
        'title': '🥇 Birinchi o\'rin!',
        'body': 'Haftalik reytingda 1-o\'rinni egallading! 200 tanga mukofot oldingiz.',
        'type': 'weekly_reward',
      },
      {
        'userId': 'user_bobur',
        'title': '🥈 Ikkinchi o\'rin!',
        'body': 'Haftalik reytingda 2-o\'rinni egallading! 100 tanga mukofot oldingiz.',
        'type': 'weekly_reward',
      },
      {
        'userId': 'user_ahmad',
        'title': '🥉 Uchinchi o\'rin!',
        'body': 'Haftalik reytingda 3-o\'rinni egallading! 50 tanga mukofot oldingiz.',
        'type': 'weekly_reward',
      },
    ];

    for (final notification in notifications) {
      final notificationRef = _firestore.collection('notifications').doc();
      batch.set(notificationRef, {
        'userId': notification['userId'],
        'title': notification['title'],
        'body': notification['body'],
        'type': notification['type'],
        'createdAt': now.millisecondsSinceEpoch,
        'isRead': false,
      });
    }

    await batch.commit();
    debugPrint('✅ Sample notifications yaratildi');
  }

  /// Helper methods
  static DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return DateTime(date.year, date.month, date.day - (weekday - 1));
  }

  static DateTime _getMonthStart(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }
}
