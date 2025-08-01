import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qadam_app/app/services/step_counter_service.dart';
import 'package:qadam_app/app/services/coin_service.dart';
import 'package:qadam_app/app/services/challenge_service.dart';
import 'package:qadam_app/app/models/challenge_model.dart';
import 'package:qadam_app/app/services/auth_service.dart';
import 'package:confetti/confetti.dart';
import 'package:qadam_app/app/components/loading_widget.dart';
import 'package:qadam_app/app/components/error_widget.dart';
import 'package:qadam_app/app/components/app_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../components/custom_app_bar.dart';

class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({Key? key}) : super(key: key);

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isClaiming = false;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final challengeService =
          Provider.of<ChallengeService>(context, listen: false);
      final stepService =
          Provider.of<StepCounterService>(context, listen: false);

      challengeService.fetchChallenges();
      challengeService.startListening(); // Real-time listener boshlash
      _updateChallengeProgress();
      _autoCreateChallenges(); // Avtomatik challenge yaratish
    });
  }

  void _updateChallengeProgress() {
    final challengeService =
        Provider.of<ChallengeService>(context, listen: false);
    final stepService = Provider.of<StepCounterService>(context, listen: false);

    for (var challenge in challengeService.challenges) {
      if (!challenge.rewardClaimed) {
        final progress =
            (stepService.steps / challenge.targetSteps).clamp(0.0, 1.0);
        challengeService.updateChallengeProgress(challenge.id, progress);
      }
    }
  }

  @override
  void dispose() {
    // Stop real-time listener when leaving screen
    context.read<ChallengeService>().stopListening();
    _tabController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final challengeService = Provider.of<ChallengeService>(context);

    // Faqat mukofoti olinmagan challengelarni ko'rsatish
    final dailyChallenges = challengeService.challenges
        .where((c) => c.type == 'daily' && !c.rewardClaimed)
        .toList();

    final weeklyChallenges = challengeService.challenges
        .where((c) => c.type == 'weekly' && !c.rewardClaimed)
        .toList();

    // Faqat mukofoti olingan challengelarni ko'rsatish (butun umr uchun)
    final completedChallenges =
        challengeService.challenges.where((c) => c.rewardClaimed).toList();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.primaryColor,
                theme.primaryColor.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text(
              'Challenge\'lar',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.monetization_on,
                        color: Colors.yellow, size: 18),
                    const SizedBox(width: 4),
                    Consumer<CoinService>(
                      builder: (context, coinService, child) {
                        return Text(
                          '${coinService.coins}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: challengeService.isLoading
          ? const LoadingWidget(message: 'Challengelar yuklanmoqda...')
          : challengeService.error != null
              ? AppErrorWidget(
                  message: challengeService.error ?? 'Noma\'lum xatolik',
                  onRetry: () => challengeService.fetchChallenges(),
                )
              : Column(
                  children: [
                    Container(
                      color: colorScheme.surface,
                      child: TabBar(
                        controller: _tabController,
                        labelColor: theme.primaryColor,
                        unselectedLabelColor:
                            colorScheme.onSurface.withOpacity(0.6),
                        indicatorColor: theme.primaryColor,
                        indicatorWeight: 3,
                        tabs: [
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Flexible(
                                  child: Text(
                                    'Kunlik',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (dailyChallenges.isNotEmpty) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: theme.primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '${dailyChallenges.length}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Flexible(
                                  child: Text(
                                    'Haftalik',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (weeklyChallenges.isNotEmpty) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: theme.primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '${weeklyChallenges.length}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Flexible(
                                  child: Text(
                                    'Tugallangan',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (completedChallenges.isNotEmpty) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '${completedChallenges.length}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildChallengeList(
                              dailyChallenges, 'Kunlik challengelar topilmadi'),
                          _buildChallengeList(weeklyChallenges,
                              'Haftalik challengelar topilmadi'),
                          _buildCompletedChallengeList(
                              context,
                              completedChallenges,
                              'Tugallangan challengelar topilmadi'),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildChallengeList(
      List<ChallengeModel> challenges, String emptyText) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (challenges.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 64,
              color: colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              emptyText,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: challenges.length,
      itemBuilder: (context, index) {
        final challenge = challenges[index];
        return _buildChallengeCard(challenge);
      },
    );
  }

  Widget _buildChallengeCard(ChallengeModel challenge) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final stepService = Provider.of<StepCounterService>(context);

    final progress =
        (stepService.steps / challenge.targetSteps).clamp(0.0, 1.0);
    final isCompleted = progress >= 1.0;
    final canClaimReward = isCompleted && !challenge.rewardClaimed;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: challenge.rewardClaimed
            ? colorScheme.surface.withOpacity(0.7)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: challenge.rewardClaimed
              ? Colors.green.withOpacity(0.3)
              : colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: challenge.rewardClaimed
                        ? Colors.green.withOpacity(0.1)
                        : theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    challenge.rewardClaimed
                        ? Icons.check_circle
                        : getIconForChallenge(challenge.title),
                    color: challenge.rewardClaimed
                        ? Colors.green
                        : theme.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        challenge.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: challenge.rewardClaimed
                              ? colorScheme.onSurface.withOpacity(0.7)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        challenge.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: challenge.rewardClaimed
                        ? Colors.green.withOpacity(0.1)
                        : Colors.yellow.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.monetization_on,
                          color: challenge.rewardClaimed
                              ? Colors.green
                              : Colors.orange,
                          size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${challenge.reward}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: challenge.rewardClaimed
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Progress bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      challenge.rewardClaimed
                          ? 'Tugallandi ✓'
                          : 'Progress: ${(progress * 100).toInt()}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: challenge.rewardClaimed ? Colors.green : null,
                      ),
                    ),
                    Text(
                      '${stepService.steps}/${challenge.targetSteps}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: challenge.rewardClaimed ? 1.0 : progress,
                  backgroundColor: colorScheme.outline.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    challenge.rewardClaimed || isCompleted
                        ? Colors.green
                        : theme.primaryColor,
                  ),
                  minHeight: 6,
                ),
              ],
            ),

            if (canClaimReward) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isClaiming ? null : () => _claimReward(challenge),
                  icon: _isClaiming
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.card_giftcard, size: 18),
                  label: Text(_isClaiming ? 'Olinmoqda...' : 'Mukofot olish'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ] else if (challenge.rewardClaimed) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle,
                        color: Colors.green, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Mukofot olindi',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData getIconForChallenge(String title) {
    if (title.contains('qadam')) return Icons.directions_walk;
    if (title.contains('do\'st')) return Icons.people;
    if (title.contains('kun')) return Icons.calendar_today;
    return Icons.emoji_events;
  }

  void _claimReward(ChallengeModel challenge) async {
    if (_isClaiming) return;

    setState(() {
      _isClaiming = true;
    });

    final coinService = Provider.of<CoinService>(context, listen: false);
    final challengeService =
        Provider.of<ChallengeService>(context, listen: false);

    try {
      await coinService.addCoins(challenge.reward);
      await challengeService.claimChallengeReward(
          challenge.id, challenge.reward);

      if (mounted) {
        _confettiController.play();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('${challenge.reward} coin olindi!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );

        await Future.delayed(const Duration(milliseconds: 1000));
        if (mounted) {
          _tabController.animateTo(2);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Xatolik yuz berdi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isClaiming = false;
        });
      }
    }
  }
}

class Challenge {
  final String title;
  final String description;
  final int reward;
  final double progress;
  final bool isCompleted;
  final IconData icon;
  final String id;
  final bool? rewardClaimed;

  Challenge({
    required this.title,
    required this.description,
    required this.reward,
    required this.progress,
    required this.isCompleted,
    required this.icon,
    required this.id,
    this.rewardClaimed,
  });
}

List<ChallengeModel> filterValidChallenges(List<ChallengeModel> challenges) {
  return challenges; // vaqtincha hech narsa filtrlamaydi
}

/// Progresslarni yangilash uchun utility funksiya
void updateChallengesProgress(List<ChallengeModel> challenges, int currentSteps,
    ChallengeService challengeService) {
  for (var challenge in challenges) {
    if (!challenge.isCompleted && challenge.progress < 1.0) {
      final progress = (currentSteps / challenge.targetSteps).clamp(0.0, 1.0);
      if (progress != challenge.progress) {
        challengeService.updateChallengeProgress(challenge.id, progress);
      }
    }
  }
}

Widget _buildCompletedChallengeList(
    BuildContext context, List<ChallengeModel> challenges, String emptyText) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;

  if (challenges.isEmpty) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 64,
            color: colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            emptyText,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  return ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: challenges.length,
    itemBuilder: (context, index) {
      final challenge = challenges[index];
      return _buildCompletedChallengeCard(context, challenge);
    },
  );
}

Widget _buildCompletedChallengeCard(
    BuildContext context, ChallengeModel challenge) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;

  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: Colors.green.withOpacity(0.05),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: Colors.green.withOpacity(0.3),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      challenge.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.monetization_on,
                        color: Colors.green, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '+${challenge.reward}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Completed status
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.emoji_events, color: Colors.green, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Challenge tugallandi!',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
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

  // Avtomatik challenge yaratish - sodda versiya
  Future<void> _autoCreateChallenges() async {
    debugPrint('🎯 Avtomatik challenge yaratish boshlandi');
    // Hozircha faqat log, keyinroq to'liq implement qilamiz
  }
}
