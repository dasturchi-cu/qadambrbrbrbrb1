import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qadam_app/app/services/step_counter_service.dart'
    as step_service;
import 'package:qadam_app/app/services/challenge_service.dart';

// Challenge model
class ChallengeModel {
  final String id;
  final String title;
  final String description;
  final int reward;
  final int targetSteps;
  final int duration;
  final String type;
  final DateTime? startDate;
  final DateTime? endDate;
  final double progress;
  final bool isCompleted;
  final bool rewardClaimed;

  ChallengeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.reward,
    required this.targetSteps,
    required this.duration,
    required this.type,
    this.startDate,
    this.endDate,
    this.progress = 0,
    this.isCompleted = false,
    this.rewardClaimed = false,
  });

  ChallengeModel copyWith({
    double? progress,
    bool? isCompleted,
    bool? rewardClaimed,
  }) {
    return ChallengeModel(
      id: id,
      title: title,
      description: description,
      reward: reward,
      targetSteps: targetSteps,
      duration: duration,
      type: type,
      startDate: startDate,
      endDate: endDate,
      progress: progress ?? this.progress,
      isCompleted: isCompleted ?? this.isCompleted,
      rewardClaimed: rewardClaimed ?? this.rewardClaimed,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "title": title,
      "description": description,
      "reward": reward,
      "targetSteps": targetSteps,
      "duration": duration,
      "type": type,
      "startDate": startDate,
      "endDate": endDate,
      "progress": progress,
      "isCompleted": isCompleted,
      "rewardClaimed": rewardClaimed,
    };
  }
}

// Progress update function
void updateChallengesProgress(List<ChallengeModel> challenges, int currentSteps,
    ChallengeService service) {
  for (var challenge in challenges) {
    if (!challenge.isCompleted && challenge.progress < 1.0) {
      final progress = (currentSteps / challenge.targetSteps).clamp(0.0, 1.0);
      if (progress != challenge.progress) {
        service.updateChallengeProgress(challenge.id, progress);
      }
    }
  }
}

// Main App Widget
class MyChallengeScreen extends StatelessWidget {
  const MyChallengeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stepService = Provider.of<step_service.StepCounterService>(context);
    final challengeService = Provider.of<ChallengeService>(context);

    // Update progress when UI builds (or ideally when steps change)
    updateChallengesProgress(
      challengeService.challenges,
      stepService.steps,
      challengeService,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Challenges'),
      ),
      body: ListView.builder(
        itemCount: challengeService.challenges.length,
        itemBuilder: (context, index) {
          final challenge = challengeService.challenges[index];
          return ListTile(
            title: Text(challenge.title),
            subtitle: Text(
              '${(challenge.progress * 100).toStringAsFixed(1)}% completed',
            ),
            trailing: challenge.isCompleted
                ? const Icon(Icons.check_circle, color: Colors.green)
                : null,
          );
        },
      ),
    );
  }
}

// App Entry Point
void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => step_service.StepCounterService()),
        ChangeNotifierProvider(
          create: (_) => ChallengeService(),
        ),
      ],
      child: const MaterialApp(
        home: MyChallengeScreen(),
      ),
    ),
  );
}
