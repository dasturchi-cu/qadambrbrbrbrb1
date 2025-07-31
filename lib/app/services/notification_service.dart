import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();

  static Future<void> showDailyReminder() async {
    await _notifications.show(
      0,
      'Qadam vaqti!',
      'Bugungi maqsadingizga erishish uchun yuring!',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Kunlik eslatma',
          importance: Importance.high,
        ),
      ),
    );
  }
}