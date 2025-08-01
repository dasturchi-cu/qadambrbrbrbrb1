import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:qadam_app/app/screens/login_screen.dart';
import 'package:qadam_app/app/screens/splash_screen.dart';
import 'package:qadam_app/app/screens/support_screen.dart';
import 'package:qadam_app/app/services/step_counter_service.dart'
    as step_service;
import 'package:qadam_app/app/services/coin_service.dart';
import 'package:qadam_app/app/screens/coin_wallet_screen.dart';
import 'package:qadam_app/app/screens/challenge_screen.dart';
import 'statistics_screen.dart';
import 'package:qadam_app/app/screens/referral_screen.dart';
import 'package:qadam_app/app/screens/profile_screen.dart';
import 'package:qadam_app/app/screens/settings_screen.dart';
import 'package:qadam_app/app/screens/ranking_screen.dart';
import 'package:qadam_app/app/screens/transaction_history_screen.dart';
import 'package:qadam_app/app/components/step_progress_card.dart';
import 'package:qadam_app/app/components/challenge_banner.dart';
import 'package:qadam_app/app/screens/notification_screen.dart';
import 'package:qadam_app/app/screens/login_streak_screen.dart';
import 'package:qadam_app/app/screens/support_history_screen.dart';
import 'package:qadam_app/app/models/challenge_model.dart';
import 'package:qadam_app/app/services/challenge_service.dart';
import 'package:qadam_app/app/screens/shop_screen.dart';
import 'package:qadam_app/app/utils/auto_firebase_setup.dart';
import 'package:qadam_app/app/services/active_user_service.dart';
import 'package:qadam_app/app/services/dynamic_ranking_service.dart';
import 'package:qadam_app/app/services/weekly_bonus_service.dart';
import 'package:qadam_app/app/services/daily_bonus_service.dart';
import 'package:qadam_app/app/services/progressive_login_streak_service.dart';

import '../ad_helper.dart';
import '../services/auth_service.dart';
import '../widgets/connection_status_widget.dart';
import '../widgets/auto_game_trigger_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;

  // COMPLETE: Add _rewardedAd
  RewardedAd? _rewardedAd;
  DateTime? _lastBonusShownDate;
  final bool _isCounting = true;

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to avoid the setState during build error
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Start step counting service
      final stepService =
          Provider.of<step_service.StepCounterService>(context, listen: false);
      stepService.startCounting();

      BannerAd(
        adUnitId: AdHelper.bannerAdUnitId,
        request: const AdRequest(),
        size: AdSize.banner,
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            setState(() {
              _bannerAd = ad as BannerAd;
            });
          },
          onAdFailedToLoad: (ad, err) {
            debugPrint('Failed to load a banner ad: ${err.message}');
            ad.dispose();
          },
        ),
      ).load();

      // COMPLETE: Load a rewarded Ad

      // _loadRewardedAd();

      // Bonus xabarini ko'rsatish
      final coinService = Provider.of<CoinService>(context, listen: false);
      final now = DateTime.now();
      if (coinService.lastBonusAmount != null &&
          coinService.lastBonusDate != null) {
        if (_lastBonusShownDate == null ||
            now.year != _lastBonusShownDate!.year ||
            now.month != _lastBonusShownDate!.month ||
            now.day != _lastBonusShownDate!.day) {
          if (now.year == coinService.lastBonusDate!.year &&
              now.month == coinService.lastBonusDate!.month &&
              now.day == coinService.lastBonusDate!.day) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      'Kundalik bonus: ${coinService.lastBonusAmount} tanga!')),
            );
            _lastBonusShownDate = now;
          }
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final coinService = Provider.of<CoinService>(context);
    if (coinService.showBonusSnackbar && coinService.lastBonusAmount != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Text('Kundalik bonus: ${coinService.lastBonusAmount} tanga! '),
                const Text('😄'),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        coinService.clearBonusSnackbar();
      });
    }
  }

  final GlobalKey<ScaffoldState> _key = GlobalKey(); // Create a key

  @override
  Widget build(BuildContext context) {
    final stepService = Provider.of<step_service.StepCounterService>(context);
    final coinService = Provider.of<CoinService>(context);
    final authService = Provider.of<AuthService>(context);

    return AutoGameTriggerWidget(
      child: Scaffold(
        key: _key,
        drawer: Drawer(
          child: Column(
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.white,
                      backgroundImage: authService.user?.photoURL != null
                          ? NetworkImage(authService.user!.photoURL!)
                          : null,
                      child: authService.user?.photoURL == null
                          ? const Icon(
                              Icons.person,
                              color: Colors.grey,
                              size: 33,
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            authService.user?.displayName ?? "User",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            authService.user?.email ?? "",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildDrawerTile(
                      context,
                      icon: Icons.home_outlined,
                      label: 'Asosiy',
                      onTap: () => Navigator.pop(context),
                    ),
                    _buildDrawerTile(
                      context,
                      icon: Icons.person_outline,
                      label: 'Profil',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ProfileScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDrawerTile(
                      context,
                      icon: Icons.settings_outlined,
                      label: 'Sozlamalar',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDrawerTile(
                      context,
                      icon: Icons.leaderboard,
                      label: 'Reyting',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const RankingScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDrawerTile(
                      context,
                      icon: Icons.history,
                      label: 'Tranzaksiya tarixi',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const TransactionHistoryScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDrawerTile(
                      context,
                      icon: Icons.support_agent,
                      label: 'Yordam',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SupportScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.only(bottom: 16.0, left: 16, right: 16),
                child: _buildDrawerTile(
                  context,
                  icon: Icons.logout,
                  label: 'Chiqish',
                  color: Colors.red,
                  onTap: () {
                    authService.signOut();
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginScreen()));
                  },
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    // Menu button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: () => _key.currentState?.openDrawer(),
                        icon: const Icon(Icons.menu, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // App title with coin balance
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          InkWell(
                            onTap: () => stepService.addSteps(100),
                            child: const Text(
                              'Qadam++',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Consumer<CoinService>(
                            builder: (context, coinService, child) {
                              return Row(
                                children: [
                                  const Icon(
                                    Icons.monetization_on,
                                    color: Colors.amber,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${coinService.coins}tanga',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    // Today's steps indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.directions_walk,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Consumer<step_service.StepCounterService>(
                            builder: (context, stepService, child) {
                              return Text(
                                '${stepService.steps}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Notifications with badge
                    Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.notifications,
                                color: Colors.white),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const NotificationScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        // Notification badge
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 12,
                              minHeight: 12,
                            ),
                            child: const Text(
                              '3',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),

                    // 🔥 FIREBASE SETUP TUGMASI
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.rocket_launch,
                            color: Colors.white),
                        onPressed: () async {
                          if (!mounted) return;

                          // Show loading dialog
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => const AlertDialog(
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 16),
                                  Text(
                                      '🔥 Firebase Collections yaratilmoqda...'),
                                ],
                              ),
                            ),
                          );

                          try {
                            // Run Firebase setup
                            await AutoFirebaseSetup.setupEverything();

                            // Initialize all real-time services
                            await Future.wait([
                              context.read<ActiveUserService>().initialize(),
                              context
                                  .read<DynamicRankingService>()
                                  .initialize(),
                              context.read<WeeklyBonusService>().initialize(),
                              context.read<DailyBonusService>().initialize(),
                              context
                                  .read<ProgressiveLoginStreakService>()
                                  .initialize(),
                            ]);

                            if (!mounted) return;
                            Navigator.of(context).pop(); // Close loading dialog

                            // Show success dialog
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('✅ Muvaffaqiyat!'),
                                content: const Text(
                                    '🔥 Barcha Firebase Collections yaratildi!\n'
                                    '🏆 Ranking System tayyor!\n'
                                    '💰 Sample data qo\'shildi!\n\n'
                                    'Endi Reyting sahifasiga o\'ting va test qiling!'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: const Text('OK'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => const RankingScreen(),
                                        ),
                                      );
                                    },
                                    child: const Text('🏆 Reytingga o\'tish'),
                                  ),
                                ],
                              ),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            Navigator.of(context).pop(); // Close loading dialog

                            // Show error dialog
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('❌ Xatolik'),
                                content: Text('Firebase setup xatoligi: $e'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Connection status
              const ConnectionStatusWidget(showDetails: true),

              // Main content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Banner ad
                      if (_bannerAd != null)
                        Align(
                          alignment: Alignment.topCenter,
                          child: SizedBox(
                            width: _bannerAd!.size.width.toDouble(),
                            height: _bannerAd!.size.height.toDouble(),
                            child: AdWidget(ad: _bannerAd!),
                          ),
                        ),

                      // User greeting
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        color: Theme.of(context).primaryColor,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Salom, ${authService.user?.displayName?.isNotEmpty == true ? authService.user!.displayName : (authService.user?.email ?? 'Foydalanuvchi')}!',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  'Bugun sog\'lom qadamlar',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Colors.white,
                                      ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.monetization_on,
                                    color: Color(0xFFFFC107),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    '${coinService.coins}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Step counter card
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: StepProgressCard(
                          steps: stepService.steps,
                          goal: stepService.dailyGoal,
                          coins: coinService.todayEarned,
                        ),
                      ),

                      // Challenge banner
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.0),
                        child: ChallengeBanner(),
                      ),

                      const SizedBox(height: 20),

                      // Options grid
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Qo\'shimcha imkoniyatlar',
                              style: Theme.of(context)
                                  .textTheme
                                  .displayMedium
                                  ?.copyWith(
                                    fontSize: 18,
                                  ),
                            ),
                            const SizedBox(height: 15),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildFeatureButton(
                                    context,
                                    icon: Icons.monetization_on,
                                    label: 'Hamyon',
                                    color: const Color(0xFFFFC107),
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const CoinWalletScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: _buildFeatureButton(
                                    context,
                                    icon: Icons.analytics,
                                    label: 'Statistika',
                                    color: const Color(0xFF2196F3),
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const StatisticsScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildFeatureButton(
                                    context,
                                    icon: Icons.flag,
                                    label: 'Challenge',
                                    color: const Color(0xFFE91E63),
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const ChallengeScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: _buildFeatureButton(
                                    context,
                                    icon: Icons.people,
                                    label: 'Referal',
                                    color: const Color(0xFF673AB7),
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const ReferralScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildFeatureButton(
                                    context,
                                    icon: Icons.whatshot,
                                    label: 'Login Streak',
                                    color: const Color(0xFF00BFA5),
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const LoginStreakScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: _buildFeatureButton(
                                    context,
                                    icon: Icons.leaderboard,
                                    label: 'Reyting',
                                    color: const Color(0xFF4CAF50),
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => const RankingScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: _buildFeatureButton(
                                    context,
                                    icon: Icons.history,
                                    label: 'Tranzaksiya',
                                    color: const Color(0xFF607D8B),
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const TransactionHistoryScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildFeatureButton(
                                    context,
                                    icon: Icons.support_agent,
                                    label: 'Murojaatlar',
                                    color: const Color(0xFF1976D2),
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const SupportHistoryScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: _buildFeatureButton(
                                    context,
                                    icon: Icons.shopping_cart,
                                    label: 'Do\'kon',
                                    color: const Color(0xFF4CAF50),
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => ShopScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 30,
                color: color,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerTile(BuildContext context,
      {required IconData icon,
      required String label,
      required VoidCallback onTap,
      Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[50],
            ),
            child: Row(
              children: [
                Icon(icon, color: color ?? Theme.of(context).primaryColor),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: color ?? Colors.black87,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios,
                    size: 16, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    ); // AutoGameTriggerWidget yopilishi
  }
}
