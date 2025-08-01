import 'package:flutter/foundation.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // App Events
  Future<void> logAppOpen() async {
    await _analytics.logAppOpen();
    await _logCustomEvent('app_opened', {});
  }

  Future<void> logLogin(String method) async {
    await _analytics.logLogin(loginMethod: method);
    await _logCustomEvent('user_login', {'method': method});
  }

  Future<void> logSignUp(String method) async {
    await _analytics.logSignUp(signUpMethod: method);
    await _logCustomEvent('user_signup', {'method': method});
  }

  // Step Events
  Future<void> logStepsRecorded(int steps, int coinsEarned) async {
    await _analytics.logEvent(
      name: 'steps_recorded',
      parameters: {
        'steps_count': steps,
        'coins_earned': coinsEarned,
        'steps_per_coin': steps > 0 ? (steps / (coinsEarned > 0 ? coinsEarned : 1)).round() : 0,
      },
    );
    
    await _logCustomEvent('steps_recorded', {
      'steps': steps,
      'coins': coinsEarned,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> logDailyGoalReached(int steps, int goalSteps) async {
    await _analytics.logEvent(
      name: 'daily_goal_reached',
      parameters: {
        'steps_count': steps,
        'goal_steps': goalSteps,
        'percentage': ((steps / goalSteps) * 100).round(),
      },
    );
    
    await _logCustomEvent('daily_goal_reached', {
      'steps': steps,
      'goal': goalSteps,
      'date': DateTime.now().toIso8601String().split('T')[0],
    });
  }

  // Challenge Events
  Future<void> logChallengeStarted(String challengeId, String challengeType) async {
    await _analytics.logEvent(
      name: 'challenge_started',
      parameters: {
        'challenge_id': challengeId,
        'challenge_type': challengeType,
      },
    );
    
    await _logCustomEvent('challenge_started', {
      'challengeId': challengeId,
      'type': challengeType,
      'startedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> logChallengeCompleted(String challengeId, String challengeType, int reward) async {
    await _analytics.logEvent(
      name: 'challenge_completed',
      parameters: {
        'challenge_id': challengeId,
        'challenge_type': challengeType,
        'reward': reward,
      },
    );
    
    await _logCustomEvent('challenge_completed', {
      'challengeId': challengeId,
      'type': challengeType,
      'reward': reward,
      'completedAt': FieldValue.serverTimestamp(),
    });
  }

  // Achievement Events
  Future<void> logAchievementUnlocked(String achievementId, String achievementType, int reward) async {
    await _analytics.logEvent(
      name: 'achievement_unlocked',
      parameters: {
        'achievement_id': achievementId,
        'achievement_type': achievementType,
        'reward': reward,
      },
    );
    
    await _logCustomEvent('achievement_unlocked', {
      'achievementId': achievementId,
      'type': achievementType,
      'reward': reward,
      'unlockedAt': FieldValue.serverTimestamp(),
    });
  }

  // Level Events
  Future<void> logLevelUp(int oldLevel, int newLevel, int totalXP) async {
    await _analytics.logEvent(
      name: 'level_up',
      parameters: {
        'old_level': oldLevel,
        'new_level': newLevel,
        'total_xp': totalXP,
      },
    );
    
    await _logCustomEvent('level_up', {
      'oldLevel': oldLevel,
      'newLevel': newLevel,
      'totalXP': totalXP,
      'levelUpAt': FieldValue.serverTimestamp(),
    });
  }

  // Coin Events
  Future<void> logCoinsEarned(int amount, String source) async {
    await _analytics.logEvent(
      name: 'coins_earned',
      parameters: {
        'amount': amount,
        'source': source,
      },
    );
    
    await _logCustomEvent('coins_earned', {
      'amount': amount,
      'source': source,
      'earnedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> logCoinsSpent(int amount, String category, String itemId) async {
    await _analytics.logEvent(
      name: 'coins_spent',
      parameters: {
        'amount': amount,
        'category': category,
        'item_id': itemId,
      },
    );
    
    await _logCustomEvent('coins_spent', {
      'amount': amount,
      'category': category,
      'itemId': itemId,
      'spentAt': FieldValue.serverTimestamp(),
    });
  }

  // Shop Events
  Future<void> logShopItemViewed(String itemId, String category, int price) async {
    await _analytics.logEvent(
      name: 'shop_item_viewed',
      parameters: {
        'item_id': itemId,
        'category': category,
        'price': price,
      },
    );
  }

  Future<void> logShopPurchase(String itemId, String category, int price) async {
    await _analytics.logEvent(
      name: 'shop_purchase',
      parameters: {
        'item_id': itemId,
        'category': category,
        'price': price,
      },
    );
    
    await _logCustomEvent('shop_purchase', {
      'itemId': itemId,
      'category': category,
      'price': price,
      'purchasedAt': FieldValue.serverTimestamp(),
    });
  }

  // Withdraw Events
  Future<void> logWithdrawRequest(int amount, String method) async {
    await _analytics.logEvent(
      name: 'withdraw_request',
      parameters: {
        'amount': amount,
        'method': method,
      },
    );
    
    await _logCustomEvent('withdraw_request', {
      'amount': amount,
      'method': method,
      'requestedAt': FieldValue.serverTimestamp(),
    });
  }

  // Social Events
  Future<void> logFriendAdded(String friendId) async {
    await _analytics.logEvent(
      name: 'friend_added',
      parameters: {
        'friend_id': friendId,
      },
    );
    
    await _logCustomEvent('friend_added', {
      'friendId': friendId,
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> logContentShared(String contentType, String platform) async {
    await _analytics.logEvent(
      name: 'content_shared',
      parameters: {
        'content_type': contentType,
        'platform': platform,
      },
    );
  }

  // Ad Events
  Future<void> logAdViewed(String adType, String placement) async {
    await _analytics.logEvent(
      name: 'ad_viewed',
      parameters: {
        'ad_type': adType,
        'placement': placement,
      },
    );
    
    await _logCustomEvent('ad_viewed', {
      'adType': adType,
      'placement': placement,
      'viewedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> logAdClicked(String adType, String placement) async {
    await _analytics.logEvent(
      name: 'ad_clicked',
      parameters: {
        'ad_type': adType,
        'placement': placement,
      },
    );
  }

  Future<void> logRewardedAdCompleted(String placement, int reward) async {
    await _analytics.logEvent(
      name: 'rewarded_ad_completed',
      parameters: {
        'placement': placement,
        'reward': reward,
      },
    );
    
    await _logCustomEvent('rewarded_ad_completed', {
      'placement': placement,
      'reward': reward,
      'completedAt': FieldValue.serverTimestamp(),
    });
  }

  // Screen Events
  Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
  }

  // Error Events
  Future<void> logError(String errorType, String errorMessage, String? stackTrace) async {
    await _analytics.logEvent(
      name: 'app_error',
      parameters: {
        'error_type': errorType,
        'error_message': errorMessage.length > 100 ? errorMessage.substring(0, 100) : errorMessage,
      },
    );
    
    await _logCustomEvent('app_error', {
      'errorType': errorType,
      'errorMessage': errorMessage,
      'stackTrace': stackTrace,
      'occurredAt': FieldValue.serverTimestamp(),
    });
  }

  // User Properties
  Future<void> setUserProperties({
    required int level,
    required int totalSteps,
    required int totalCoins,
    required int dailyStreak,
    required int friendsCount,
    required int achievementsCount,
  }) async {
    await _analytics.setUserProperty(name: 'user_level', value: level.toString());
    await _analytics.setUserProperty(name: 'total_steps', value: totalSteps.toString());
    await _analytics.setUserProperty(name: 'total_coins', value: totalCoins.toString());
    await _analytics.setUserProperty(name: 'daily_streak', value: dailyStreak.toString());
    await _analytics.setUserProperty(name: 'friends_count', value: friendsCount.toString());
    await _analytics.setUserProperty(name: 'achievements_count', value: achievementsCount.toString());
  }

  // Custom event logging to Firestore
  Future<void> _logCustomEvent(String eventName, Map<String, dynamic> parameters) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('analytics_events').add({
        'userId': user.uid,
        'eventName': eventName,
        'parameters': parameters,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': 'mobile',
        'appVersion': '1.0.0', // Bu qiymatni package_info dan olish kerak
      });
    } catch (e) {
      debugPrint('Analytics event logging error: $e');
    }
  }

  // Session tracking
  Future<void> logSessionStart() async {
    await _analytics.logEvent(name: 'session_start');
    await _logCustomEvent('session_start', {
      'sessionStartAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> logSessionEnd(Duration sessionDuration) async {
    await _analytics.logEvent(
      name: 'session_end',
      parameters: {
        'session_duration': sessionDuration.inSeconds,
      },
    );
    
    await _logCustomEvent('session_end', {
      'sessionDuration': sessionDuration.inSeconds,
      'sessionEndAt': FieldValue.serverTimestamp(),
    });
  }
}
