import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginStreakScreen extends StatefulWidget {
  const LoginStreakScreen({Key? key}) : super(key: key);

  @override
  State<LoginStreakScreen> createState() => _LoginStreakScreenState();
}

class _LoginStreakScreenState extends State<LoginStreakScreen>
    with TickerProviderStateMixin {
  // TODO: Integrate with real login streak logic and coin claiming
  int streak = 3;
  bool todayClaimed = false;
  int week = 1;
  int totalCoins = 285; // Example total coins
  List<int> dailyRewards = [10, 15, 20, 25, 30, 35, 50];
  List<String> dayNames = ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya'];

  late AnimationController _bounceController;
  late AnimationController _shimmerController;
  late Animation<double> _bounceAnimation;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _loadTodayClaimed();
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _bounceAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));

    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 1.0,
    ).animate(_shimmerController);
  }

  Future<void> _loadTodayClaimed() async {
    final prefs = await SharedPreferences.getInstance();
    final lastClaimed = prefs.getString('lastClaimedDate');
    final today = DateTime.now().toIso8601String().substring(0, 10);
    setState(() {
      todayClaimed = lastClaimed == today;
    });
  }

  Future<void> _setTodayClaimed() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await prefs.setString('lastClaimedDate', today);
    setState(() {
      todayClaimed = true;
    });
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF2D3748),
        title: const Text(
          '7 kunlik kirish',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.monetization_on,
                  color: Color(0xFF2D3748),
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  '$totalCoins',
                  style: const TextStyle(
                    color: Color(0xFF2D3748),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Week indicator with gradient background
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667EEA).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                'Hafta: $week',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Progress bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Jarayon',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF4A5568),
                        ),
                      ),
                      Text(
                        '$streak/7 kun',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF667EEA),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: streak / 7,
                    backgroundColor: Colors.grey[200],
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Color(0xFF667EEA)),
                    minHeight: 6,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Days streak visualization
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Kundalik mukofotlar',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(7, (i) {
                        bool completed = i < streak;
                        bool isToday = i == streak && !todayClaimed;
                        bool isTodayCompleted = i == streak && todayClaimed;

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0),
                          child: AnimatedBuilder(
                            animation: _bounceAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: isToday ? _bounceAnimation.value : 1.0,
                                child: Column(
                                  children: [
                                    Stack(
                                      children: [
                                        Container(
                                          width: 64,
                                          height: 64,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: completed ||
                                                    isTodayCompleted
                                                ? const LinearGradient(
                                                    colors: [
                                                      Color(0xFF48BB78),
                                                      Color(0xFF38A169)
                                                    ],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  )
                                                : isToday
                                                    ? const LinearGradient(
                                                        colors: [
                                                          Color(0xFFED8936),
                                                          Color(0xFFDD6B20)
                                                        ],
                                                        begin:
                                                            Alignment.topLeft,
                                                        end: Alignment
                                                            .bottomRight,
                                                      )
                                                    : null,
                                            color: !completed && !isToday
                                                ? Colors.grey[200]
                                                : null,
                                            boxShadow: completed ||
                                                    isToday ||
                                                    isTodayCompleted
                                                ? [
                                                    BoxShadow(
                                                      color: (completed ||
                                                                  isTodayCompleted
                                                              ? const Color(
                                                                  0xFF48BB78)
                                                              : const Color(
                                                                  0xFFED8936))
                                                          .withOpacity(0.3),
                                                      blurRadius: 12,
                                                      offset:
                                                          const Offset(0, 4),
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                          child: Center(
                                            child: completed || isTodayCompleted
                                                ? const Icon(
                                                    Icons.check,
                                                    color: Colors.white,
                                                    size: 28,
                                                  )
                                                : Text(
                                                    '${i + 1}',
                                                    style: TextStyle(
                                                      color: isToday
                                                          ? Colors.white
                                                          : Colors.grey[600],
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 20,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                        if (isToday)
                                          Positioned.fill(
                                            child: AnimatedBuilder(
                                              animation: _shimmerAnimation,
                                              builder: (context, child) {
                                                return Container(
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        Colors.transparent,
                                                        Colors.white
                                                            .withOpacity(0.3),
                                                        Colors.transparent,
                                                      ],
                                                      stops: const [
                                                        0.0,
                                                        0.5,
                                                        1.0
                                                      ],
                                                      begin: Alignment(
                                                          -1.0 +
                                                              _shimmerAnimation
                                                                  .value,
                                                          -1.0),
                                                      end: Alignment(
                                                          1.0 +
                                                              _shimmerAnimation
                                                                  .value,
                                                          1.0),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      dayNames[i],
                                      style: TextStyle(
                                        color: completed ||
                                                isToday ||
                                                isTodayCompleted
                                            ? const Color(0xFF2D3748)
                                            : Colors.grey[500],
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: completed ||
                                                isToday ||
                                                isTodayCompleted
                                            ? const Color(0xFFFFD700)
                                                .withOpacity(0.2)
                                            : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '+${dailyRewards[i]}',
                                        style: TextStyle(
                                          color: completed ||
                                                  isToday ||
                                                  isTodayCompleted
                                              ? const Color(0xFFB7791F)
                                              : Colors.grey[500],
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Claim button or claimed status
            todayClaimed
                ? Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF48BB78).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF48BB78).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Color(0xFF48BB78),
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Bugungi mukofot olindi!',
                          style: TextStyle(
                            color: Color(0xFF48BB78),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                : Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFED8936), Color(0xFFDD6B20)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFED8936).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.card_giftcard, size: 24),
                      label: Text(
                        'Mukofot olish (+${dailyRewards[streak]} tanga)',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: todayClaimed
                          ? null
                          : () async {
                              _bounceController.forward().then((_) {
                                _bounceController.reverse();
                              });
                              await _setTodayClaimed();
                              setState(() {
                                totalCoins += dailyRewards[streak];
                                streak++;
                                // TODO: Add coin to user balance and persist streak
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.celebration,
                                          color: Colors.white),
                                      const SizedBox(width: 12),
                                      Text(
                                          'Tabriklaymiz! +${dailyRewards[streak - 1]} tanga olindi!'),
                                    ],
                                  ),
                                  backgroundColor: const Color(0xFF48BB78),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            },
                    ),
                  ),
            const SizedBox(height: 30),

            // Information card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF667EEA).withOpacity(0.1),
                    const Color(0xFF764BA2).withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF667EEA).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Color(0xFF667EEA),
                    size: 32,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Qanday ishlaydi?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Har kuni ilovaga kirib, tanga yutib oling! 7-kunlik streak yakunlaganingizda bonus mukofot olasiz. Har hafta mukofotlar yana ham ko\'payib boradi.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF4A5568),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
