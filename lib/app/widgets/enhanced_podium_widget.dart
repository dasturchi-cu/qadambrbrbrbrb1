import 'package:flutter/material.dart';
import '../models/ranking_model.dart';

/// 🏆 Enhanced Podium Widget - Dynamic design based on active users
class EnhancedPodiumWidget extends StatelessWidget {
  final List<RankingModel> activeUsers;
  final String? currentUserId;

  const EnhancedPodiumWidget({
    Key? key,
    required this.activeUsers,
    this.currentUserId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (activeUsers.isEmpty) {
      return const SizedBox.shrink();
    }

    // Dynamic design based on user count
    if (activeUsers.length == 1) {
      return _buildSingleUserDesign(context);
    } else if (activeUsers.length == 2) {
      return _buildTwoUsersDesign(context);
    } else {
      return _buildFullPodiumDesign(context);
    }
  }

  /// Single user design - Special champion design
  Widget _buildSingleUserDesign(BuildContext context) {
    final user = activeUsers.first;
    final isCurrentUser = user.userId == currentUserId;

    return Container(
      height: 280,
      margin: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Crown animation
            TweenAnimationBuilder(
              duration: const Duration(seconds: 2),
              tween: Tween<double>(begin: 0, end: 1),
              builder: (context, double value, child) {
                return Transform.scale(
                  scale: 0.8 + (0.2 * value),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.amber, Colors.orange],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withValues(alpha: 0.5),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.emoji_events,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            
            // User info
            Text(
              '👑 CHAMPION',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.amber[700],
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            
            Text(
              user.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            
            Text(
              '${_formatSteps(user.steps)} qadam',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            
            if (isCurrentUser) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'SIZ',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Two users design - Winner and runner-up
  Widget _buildTwoUsersDesign(BuildContext context) {
    final winner = activeUsers[0];
    final runnerUp = activeUsers[1];

    return Container(
      height: 250,
      margin: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd place (smaller)
          _buildPodiumPlace(
            context,
            runnerUp,
            2,
            120,
            Colors.grey[400]!,
            '🥈',
            false,
          ),
          
          // 1st place (larger)
          _buildPodiumPlace(
            context,
            winner,
            1,
            160,
            Colors.amber,
            '🥇',
            true,
          ),
        ],
      ),
    );
  }

  /// Full podium design - Top 3 + others
  Widget _buildFullPodiumDesign(BuildContext context) {
    final topThree = activeUsers.take(3).toList();
    final others = activeUsers.skip(3).toList();

    return Column(
      children: [
        // Top 3 podium
        Container(
          height: 220,
          margin: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 2nd place
              if (topThree.length > 1)
                _buildPodiumPlace(
                  context,
                  topThree[1],
                  2,
                  120,
                  Colors.grey[400]!,
                  '🥈',
                  false,
                ),
              
              // 1st place
              _buildPodiumPlace(
                context,
                topThree[0],
                1,
                160,
                Colors.amber,
                '🥇',
                true,
              ),
              
              // 3rd place
              if (topThree.length > 2)
                _buildPodiumPlace(
                  context,
                  topThree[2],
                  3,
                  100,
                  Colors.brown[400]!,
                  '🥉',
                  false,
                ),
            ],
          ),
        ),
        
        // Others list (4th+)
        if (others.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(),
          ),
          ...others.asMap().entries.map((entry) {
            final index = entry.key;
            final user = entry.value;
            return _buildOtherUserTile(context, user, index + 4);
          }).toList(),
        ],
      ],
    );
  }

  /// Build individual podium place
  Widget _buildPodiumPlace(
    BuildContext context,
    RankingModel user,
    int position,
    double height,
    Color color,
    String emoji,
    bool isWinner,
  ) {
    final isCurrentUser = user.userId == currentUserId;
    final reward = _getRewardForPosition(position);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // User info above podium
        Column(
          children: [
            // Avatar with glow effect for winner
            Container(
              width: isWinner ? 60 : 50,
              height: isWinner ? 60 : 50,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: isWinner
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.5),
                          blurRadius: 15,
                          spreadRadius: 3,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  emoji,
                  style: TextStyle(fontSize: isWinner ? 28 : 24),
                ),
              ),
            ),
            const SizedBox(height: 8),
            
            // User name
            SizedBox(
              width: 90,
              child: Text(
                user.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isWinner ? 14 : 12,
                  color: isCurrentUser ? Colors.blue : Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            
            // Steps
            Text(
              _formatSteps(user.steps),
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
            
            // Reward
            if (reward > 0) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '+$reward 💰',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            
            // Current user indicator
            if (isCurrentUser) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'SIZ',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        
        // Podium base
        AnimatedContainer(
          duration: Duration(milliseconds: 500 + (position * 200)),
          width: isWinner ? 100 : 80,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color,
                color.withValues(alpha: 0.7),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              position.toString(),
              style: TextStyle(
                color: Colors.white,
                fontSize: isWinner ? 32 : 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Build tile for 4th+ place users
  Widget _buildOtherUserTile(BuildContext context, RankingModel user, int position) {
    final isCurrentUser = user.userId == currentUserId;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentUser ? Colors.blue[50] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: isCurrentUser
            ? Border.all(color: Colors.blue[200]!, width: 2)
            : null,
      ),
      child: Row(
        children: [
          // Position
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isCurrentUser ? Colors.blue : Colors.grey[400],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                position.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isCurrentUser ? Colors.blue[700] : Colors.black87,
                  ),
                ),
                Text(
                  '${_formatSteps(user.steps)} qadam',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Current user indicator
          if (isCurrentUser)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'SIZ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Format steps with commas
  String _formatSteps(int steps) {
    return steps.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  /// Get reward amount for position
  int _getRewardForPosition(int position) {
    switch (position) {
      case 1:
        return 200;
      case 2:
        return 100;
      case 3:
        return 50;
      default:
        return 0;
    }
  }
}
