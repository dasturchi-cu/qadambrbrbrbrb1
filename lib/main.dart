import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:qadam_app/app/firebase_options.dart';
import 'package:qadam_app/app/screens/splash_screen.dart';
import 'package:qadam_app/app/screens/register_screen.dart';
import 'package:provider/provider.dart';
import 'package:qadam_app/app/services/challenge_service.dart';
import 'package:qadam_app/app/services/step_counter_service.dart'
    as step_service;
import 'package:qadam_app/app/services/coin_service.dart';
import 'package:qadam_app/app/services/auth_service.dart'
    hide AchievementService;
import 'package:qadam_app/app/screens/login_screen.dart';
import 'package:qadam_app/app/services/ranking_service.dart';
import 'package:qadam_app/app/services/settings_service.dart';
import 'package:qadam_app/app/services/transaction_service.dart';
import 'package:qadam_app/app/services/referral_service.dart';
import 'package:qadam_app/app/services/statistics_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:qadam_app/app/services/support_service.dart';
import 'package:qadam_app/app/services/achievement_service.dart';
import 'package:qadam_app/app/services/shop_service.dart';
import 'package:qadam_app/app/services/withdraw_service.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'qadam_channel',
  'Qadam Notifications',
  description: 'Notifications for Qadam app',
  importance: Importance.high,
);

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');
}

Future<void> setupFlutterNotifications() async {
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase ni initialize qilish
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Firebase Messaging background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Notification setup
  await setupFlutterNotifications();

  // AdMob ni initialize qilish
  MobileAds.instance.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(
            create: (_) => step_service.StepCounterService()),
        ChangeNotifierProvider(create: (_) => CoinService()),
        ChangeNotifierProvider(create: (_) => StatisticsService()),
        ChangeNotifierProvider(create: (_) => ChallengeService()),
        ChangeNotifierProvider(create: (_) => RankingService()),
        ChangeNotifierProvider(create: (_) => SettingsService()),
        ChangeNotifierProvider(create: (_) => TransactionService()),
        ChangeNotifierProvider(create: (_) => ReferralService()),
        ChangeNotifierProvider(create: (_) => AchievementService()),
        ChangeNotifierProvider(create: (_) => SupportService()),
        ChangeNotifierProvider(create: (_) => ShopService()),
        ChangeNotifierProvider(create: (_) => WithdrawService()),
        // Takrorlangan providerlar olib tashlandi
      ],
      child: const QadamApp(),
    ),
  );
}

// Firebase funksiyalari vaqtincha o'chirildi

class QadamApp extends StatefulWidget {
  const QadamApp({Key? key}) : super(key: key);

  @override
  State<QadamApp> createState() => _QadamAppState();
}

class _QadamAppState extends State<QadamApp> {
  String? _referralCode;

  @override
  void initState() {
    super.initState();
    _handleInitialDynamicLink();
  }

  Future<void> _handleInitialDynamicLink() async {
    final PendingDynamicLinkData? data =
        await FirebaseDynamicLinks.instance.getInitialLink();
    final Uri? deepLink = data?.link;
    if (deepLink != null && deepLink.pathSegments.contains('ref')) {
      final referralCode = deepLink.pathSegments.last;
      // Use navigatorKey to push RegisterScreen
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => RegisterScreen(referralCode: referralCode),
        ),
      );
    }
  }

  // Future<void> _handleInitialDynamicLink() async {
  //   final PendingDynamicLinkData? data =
  //       await FirebaseDynamicLinks.instance.getInitialLink();
  //   final Uri? deepLink = data?.link;
  //   if (deepLink != null && deepLink.pathSegments.contains('ref')) {
  //     final referralCode = deepLink.pathSegments.last;
  //     // Use navigatorKey to push RegisterScreen
  //     navigatorKey.currentState?.push(
  //       MaterialPageRoute(
  //         builder: (_) => RegisterScreen(referralCode: referralCode),
  //       ),
  //     );
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final settingsService = Provider.of<SettingsService>(context);

    // CoinService va AchievementService initialize qilish
    if (authService.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final coinService = Provider.of<CoinService>(context, listen: false);
        final achievementService =
            Provider.of<AchievementService>(context, listen: false);

        coinService.initialize();
        coinService.checkDailyLoginBonus();
        achievementService.initialize();
      });
    }

    return MaterialApp(
      title: 'Qadam++',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF4CAF50),
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.green,
          accentColor: const Color(0xFFFFC107),
          backgroundColor: const Color(0xFFF5F5F5),
        ),
        fontFamily: 'Roboto',
        textTheme: const TextTheme(
          displayLarge: TextStyle(
              fontSize: 28.0,
              fontWeight: FontWeight.bold,
              color: Color(0xFF212121)),
          displayMedium: TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.w600,
              color: Color(0xFF212121)),
          bodyLarge: TextStyle(fontSize: 16.0, color: Color(0xFF424242)),
          bodyMedium: TextStyle(fontSize: 14.0, color: Color(0xFF616161)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: const Color(0xFF4CAF50),
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.0),
            ),
          ),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF212121),
        colorScheme: ColorScheme.fromSwatch(
          brightness: Brightness.dark,
          primarySwatch: Colors.green,
          accentColor: const Color(0xFFFFC107),
          backgroundColor: const Color(0xFF121212),
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        fontFamily: 'Roboto',
        textTheme: const TextTheme(
          displayLarge: TextStyle(
              fontSize: 28.0, fontWeight: FontWeight.bold, color: Colors.white),
          displayMedium: TextStyle(
              fontSize: 24.0, fontWeight: FontWeight.w600, color: Colors.white),
          bodyLarge: TextStyle(fontSize: 16.0, color: Colors.white70),
          bodyMedium: TextStyle(fontSize: 14.0, color: Colors.white60),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: const Color(0xFF4CAF50),
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.0),
            ),
          ),
        ),
      ),
      themeMode: settingsService.themeMode,
      locale: settingsService.locale,
      supportedLocales: const [
        Locale('uz'),
        Locale('ru'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: authService.isLoggedIn
          ? const SplashScreen()
          : LoginScreen(referralCode: _referralCode),
      navigatorKey: navigatorKey,
    );
  }
}

// Navigator uchun global key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
