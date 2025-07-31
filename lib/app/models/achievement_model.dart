class AchievementModel {
  final String challengeTitle;
  final int reward;
  final DateTime date;

  AchievementModel({
    required this.challengeTitle,
    required this.reward,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'challengeTitle': challengeTitle,
      'reward': reward,
      'date': date.toIso8601String(),
    };
  }

  factory AchievementModel.fromMap(Map<String, dynamic> map, [String? id]) {
    return AchievementModel(
      challengeTitle: map['challengeTitle'] ?? '',
      reward: map['reward'] ?? 0,
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
    );
  }

  // [] operator for backward compatibility
  dynamic operator [](String key) {
    switch (key) {
      case 'challengeTitle':
        return challengeTitle;
      case 'reward':
        return reward;
      case 'date':
        return date.toIso8601String();
      default:
        return null;
    }
  }
}
