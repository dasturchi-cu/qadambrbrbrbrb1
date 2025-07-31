class RankingModel {
  final String userId;
  final String name;
  final int rank;
  final int steps;

  RankingModel({
    required this.userId,
    required this.name,
    required this.rank,
    required this.steps,
  });

  factory RankingModel.fromMap(Map<String, dynamic> map, String userId, int rank) {
    return RankingModel(
      userId: userId,
      name: map['name'] ?? '',
      rank: rank,
      steps: map['steps'] ?? 0,
    );
  }
} 