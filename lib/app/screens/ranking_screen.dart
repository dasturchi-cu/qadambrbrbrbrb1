import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/ranking_service.dart';
import '../models/ranking_model.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({Key? key}) : super(key: key);

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Start real-time rankings when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final rankingService = context.read<RankingService>();
      rankingService.fetchRankings();
      rankingService
          .startRealTimeUpdates(); // Real-time yangilanishlarni boshlash
    });
  }

  @override
  void dispose() {
    // Stop real-time updates when leaving screen
    context.read<RankingService>().stopRealTimeUpdates();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          '🏆 Reyting',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '🌍 Global'),
            Tab(text: '📅 Haftalik'),
            Tab(text: '📆 Oylik'),
            Tab(text: '👥 Do\'stlar'),
          ],
          indicatorColor: Theme.of(context).primaryColor,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGlobalRanking(),
          _buildWeeklyRanking(),
          _buildMonthlyRanking(),
          _buildFriendsRanking(),
        ],
      ),
    );
  }

  Widget _buildGlobalRanking() {
    return Consumer<RankingService>(
      builder: (context, rankingService, child) {
        if (rankingService.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (rankingService.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text('Xatolik yuz berdi',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(rankingService.error!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => rankingService.fetchRankings(),
                  child: const Text('Qayta urinish'),
                ),
              ],
            ),
          );
        }

        final rankings = rankingService.rankings;
        if (rankings.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.leaderboard_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Hali reyting yo\'q',
                    style: TextStyle(fontSize: 18, color: Colors.grey)),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Top 3 podium
            _buildPodium(rankings.take(3).toList()),

            // Current user position (if not in top 3)
            _buildCurrentUserCard(rankings),

            // Rest of the rankings
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: rankings.length,
                itemBuilder: (context, index) {
                  final ranking = rankings[index];
                  return _buildRankingCard(ranking, index + 1);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWeeklyRanking() {
    return Consumer<RankingService>(
      builder: (context, rankingService, child) {
        final rankings = rankingService.weeklyRankings;

        if (rankings.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Bu hafta hali reyting yo\'q',
                    style: TextStyle(fontSize: 18, color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: rankings.length,
          itemBuilder: (context, index) {
            final ranking = rankings[index];
            return _buildRankingCard(ranking, index + 1, isWeekly: true);
          },
        );
      },
    );
  }

  Widget _buildMonthlyRanking() {
    return Consumer<RankingService>(
      builder: (context, rankingService, child) {
        final rankings = rankingService.monthlyRankings;

        if (rankings.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_month, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Bu oy hali reyting yo\'q',
                    style: TextStyle(fontSize: 18, color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: rankings.length,
          itemBuilder: (context, index) {
            final ranking = rankings[index];
            return _buildRankingCard(ranking, index + 1, isMonthly: true);
          },
        );
      },
    );
  }

  Widget _buildFriendsRanking() {
    return Consumer<RankingService>(
      builder: (context, rankingService, child) {
        final rankings = rankingService.friendsRankings;

        if (rankings.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Do\'stlar reytingi yo\'q',
                    style: TextStyle(fontSize: 18, color: Colors.grey)),
                SizedBox(height: 8),
                Text('Do\'stlaringizni taklif qiling!',
                    style: TextStyle(fontSize: 14, color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: rankings.length,
          itemBuilder: (context, index) {
            final ranking = rankings[index];
            return _buildRankingCard(ranking, index + 1);
          },
        );
      },
    );
  }

  Widget _buildPodium(List<RankingModel> topThree) {
    if (topThree.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 200,
      margin: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd place
          if (topThree.length > 1) _buildPodiumPlace(topThree[1], 2, 120),
          // 1st place
          _buildPodiumPlace(topThree[0], 1, 160),
          // 3rd place
          if (topThree.length > 2) _buildPodiumPlace(topThree[2], 3, 100),
        ],
      ),
    );
  }

  Widget _buildPodiumPlace(RankingModel ranking, int position, double height) {
    Color color;
    String emoji;
    int reward;

    switch (position) {
      case 1:
        color = Colors.amber;
        emoji = '🥇';
        reward = 200;
        break;
      case 2:
        color = Colors.grey[400]!;
        emoji = '🥈';
        reward = 100;
        break;
      case 3:
        color = Colors.brown[400]!;
        emoji = '🥉';
        reward = 50;
        break;
      default:
        color = Colors.grey;
        emoji = '🏆';
        reward = 0;
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // User info
        Column(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: color,
              child: Text(emoji, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(height: 4),
            Text(
              ranking.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${ranking.steps.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} qadam',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
            if (reward > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '+$reward 💰',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        // Podium
        Container(
          width: 80,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          child: Center(
            child: Text(
              position.toString(),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentUserCard(List<RankingModel> rankings) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const SizedBox.shrink();

    final userRanking = rankings.firstWhere(
      (r) => r.userId == currentUser.uid,
      orElse: () => RankingModel(
        userId: currentUser.uid,
        name: currentUser.displayName ?? 'Siz',
        steps: 0,
        rank: rankings.length + 1,
      ),
    );

    // Don't show if user is in top 3
    if (userRanking.rank <= 3) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withValues(alpha: 0.1),
            Theme.of(context).primaryColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                userRanking.rank.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sizning o\'rningiz',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${userRanking.steps.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} qadam',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          const Icon(Icons.person, color: Colors.blue),
        ],
      ),
    );
  }

  Widget _buildRankingCard(RankingModel ranking, int position,
      {bool isWeekly = false, bool isMonthly = false}) {
    Color? cardColor;
    Widget? trailingWidget;

    // Special styling for top 3
    if (position <= 3) {
      switch (position) {
        case 1:
          cardColor = Colors.amber.withValues(alpha: 0.1);
          trailingWidget = const Text('🥇 +200💰',
              style: TextStyle(fontWeight: FontWeight.bold));
          break;
        case 2:
          cardColor = Colors.grey.withValues(alpha: 0.1);
          trailingWidget = const Text('🥈 +100💰',
              style: TextStyle(fontWeight: FontWeight.bold));
          break;
        case 3:
          cardColor = Colors.brown.withValues(alpha: 0.1);
          trailingWidget = const Text('🥉 +50💰',
              style: TextStyle(fontWeight: FontWeight.bold));
          break;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cardColor ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: position <= 3
                ? (position == 1
                    ? Colors.amber
                    : position == 2
                        ? Colors.grey[400]
                        : Colors.brown[400])
                : Theme.of(context).primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              position.toString(),
              style: TextStyle(
                color: position <= 3
                    ? Colors.white
                    : Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Text(
          ranking.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${ranking.steps.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} qadam',
          style: const TextStyle(color: Colors.grey),
        ),
        trailing: trailingWidget ??
            Text(
              '${ranking.level ?? 1} lvl',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
      ),
    );
  }
}
