import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  String? _fcmToken;
  bool _notificationsEnabled = true;
  bool _dailyReminders = true;
  bool _challengeAlerts = true;
  bool _achievementNotifications = true;

  // Getters
  bool get isInitialized => _isInitialized;
  String? get fcmToken => _fcmToken;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get dailyReminders => _dailyReminders;
  bool get challengeAlerts => _challengeAlerts;
  bool get achievementNotifications => _achievementNotifications;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Local notifications sozlash
      await _initializeLocalNotifications();

      // Firebase messaging sozlash
      await _initializeFirebaseMessaging();

      // Sozlamalarni yuklash
      await _loadSettings();

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Notification service initialization error: $e');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(initSettings);
  }

  Future<void> _initializeFirebaseMessaging() async {
    // Ruxsat so'rash
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('Foydalanuvchi push notification ruxsat berdi');

      // FCM token olish
      _fcmToken = await _firebaseMessaging.getToken();
      debugPrint('FCM Token: $_fcmToken');

      // Token yangilanishini kuzatish
      _firebaseMessaging.onTokenRefresh.listen((token) {
        _fcmToken = token;
        debugPrint('FCM Token yangilandi: $token');
        notifyListeners();
      });

      // Foreground message handler
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Background message handler
      FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Foreground message: ${message.notification?.title}');

    if (_notificationsEnabled) {
      await _showLocalNotification(
        title: message.notification?.title ?? 'Qadam App',
        body: message.notification?.body ?? '',
        payload: jsonEncode(message.data),
      );
    }
  }

  Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    debugPrint('Background message: ${message.notification?.title}');
    // Background message handling logic
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'qadam_app_channel',
      'Qadam App Notifications',
      channelDescription: 'Qadam App uchun bildirishnomalar',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  // Challenge notifications
  Future<void> showChallengeCompleted(String challengeName, int reward) async {
    if (!_challengeAlerts) return;

    await _showLocalNotification(
      title: 'Vazifa bajarildi! 🎉',
      body: '$challengeName bajarildi! $reward tanga yutib oldingiz!',
    );
  }

  // Achievement notifications
  Future<void> showAchievementUnlocked(String achievementName) async {
    if (!_achievementNotifications) return;

    await _showLocalNotification(
      title: 'Yangi yutuq! 🏆',
      body: '$achievementName yutuqini qo\'lga kiritdingiz!',
    );
  }

  // Step milestone notifications
  Future<void> showStepMilestone(int steps) async {
    await _showLocalNotification(
      title: 'Ajoyib! 👏',
      body: 'Bugun $steps qadam yurdingiz! Davom eting!',
    );
  }

  // Settings
  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setDailyReminders(bool enabled) async {
    _dailyReminders = enabled;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setChallengeAlerts(bool enabled) async {
    _challengeAlerts = enabled;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setAchievementNotifications(bool enabled) async {
    _achievementNotifications = enabled;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    _dailyReminders = prefs.getBool('daily_reminders') ?? true;
    _challengeAlerts = prefs.getBool('challenge_alerts') ?? true;
    _achievementNotifications =
        prefs.getBool('achievement_notifications') ?? true;
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
    await prefs.setBool('daily_reminders', _dailyReminders);
    await prefs.setBool('challenge_alerts', _challengeAlerts);
    await prefs.setBool('achievement_notifications', _achievementNotifications);
  }
}
