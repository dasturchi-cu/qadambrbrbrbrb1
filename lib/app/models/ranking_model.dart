class RankingModel {
  final String userId;
  final String name;
  final int steps;
  final int rank;
  final int? level;
  final String? photoUrl;
  final DateTime? lastUpdated;
  final int? weeklySteps;
  final int? monthlySteps;
  final int? totalCoins;
  final bool? isCurrentUser;

  RankingModel({
    required this.userId,
    required this.name,
    required this.steps,
    required this.rank,
    this.level,
    this.photoUrl,
    this.lastUpdated,
    this.weeklySteps,
    this.monthlySteps,
    this.totalCoins,
    this.isCurrentUser,
  });

  factory RankingModel.fromMap(Map<String, dynamic> map, int rank) {
    return RankingModel(
      userId: map['userId'] ?? '',
      name: map['displayName'] ?? map['name'] ?? 'Foydalanuvchi',
      steps: map['totalSteps'] ?? map['steps'] ?? 0,
      rank: rank,
      level: map['level'] ?? 1,
      photoUrl: map['photoUrl'] ?? map['photoURL'],
      lastUpdated: map['lastUpdated'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastUpdated'])
          : null,
      weeklySteps: map['weeklySteps'] ?? 0,
      monthlySteps: map['monthlySteps'] ?? 0,
      totalCoins: map['totalCoins'] ?? map['coins'] ?? 0,
      isCurrentUser: map['isCurrentUser'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'totalSteps': steps,
      'rank': rank,
      'level': level,
      'photoUrl': photoUrl,
      'lastUpdated': lastUpdated?.millisecondsSinceEpoch,
      'weeklySteps': weeklySteps,
      'monthlySteps': monthlySteps,
      'totalCoins': totalCoins,
      'isCurrentUser': isCurrentUser,
    };
  }

  RankingModel copyWith({
    String? userId,
    String? name,
    int? steps,
    int? rank,
    int? level,
    String? photoUrl,
    DateTime? lastUpdated,
    int? weeklySteps,
    int? monthlySteps,
    int? totalCoins,
    bool? isCurrentUser,
  }) {
    return RankingModel(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      steps: steps ?? this.steps,
      rank: rank ?? this.rank,
      level: level ?? this.level,
      photoUrl: photoUrl ?? this.photoUrl,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      weeklySteps: weeklySteps ?? this.weeklySteps,
      monthlySteps: monthlySteps ?? this.monthlySteps,
      totalCoins: totalCoins ?? this.totalCoins,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
    );
  }

  @override
  String toString() {
    return 'RankingModel(userId: $userId, name: $name, steps: $steps, rank: $rank, level: $level)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RankingModel &&
        other.userId == userId &&
        other.name == name &&
        other.steps == steps &&
        other.rank == rank;
  }

  @override
  int get hashCode {
    return userId.hashCode ^ name.hashCode ^ steps.hashCode ^ rank.hashCode;
  }
}

// Reward system for top rankings
class RankingReward {
  final int position;
  final int coins;
  final String title;
  final String emoji;

  const RankingReward({
    required this.position,
    required this.coins,
    required this.title,
    required this.emoji,
  });

  static const List<RankingReward> topRewards = [
    RankingReward(
        position: 1, coins: 200, title: 'Birinchi o\'rin', emoji: '🥇'),
    RankingReward(
        position: 2, coins: 100, title: 'Ikkinchi o\'rin', emoji: '🥈'),
    RankingReward(
        position: 3, coins: 50, title: 'Uchinchi o\'rin', emoji: '🥉'),
  ];

  static RankingReward? getRewardForPosition(int position) {
    try {
      return topRewards.firstWhere((reward) => reward.position == position);
    } catch (e) {
      return null;
    }
  }
}

// Ranking period types
enum RankingPeriod {
  daily,
  weekly,
  monthly,
  allTime,
}

extension RankingPeriodExtension on RankingPeriod {
  String get displayName {
    switch (this) {
      case RankingPeriod.daily:
        return 'Kunlik';
      case RankingPeriod.weekly:
        return 'Haftalik';
      case RankingPeriod.monthly:
        return 'Oylik';
      case RankingPeriod.allTime:
        return 'Umumiy';
    }
  }

  String get emoji {
    switch (this) {
      case RankingPeriod.daily:
        return '📅';
      case RankingPeriod.weekly:
        return '📊';
      case RankingPeriod.monthly:
        return '📆';
      case RankingPeriod.allTime:
        return '🌍';
    }
  }
}
