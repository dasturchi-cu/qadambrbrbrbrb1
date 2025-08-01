import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../models/ranking_model.dart';
import 'firebase_ranking_service.dart';

class RankingService extends ChangeNotifier {
  static final RankingService _instance = RankingService._internal();
  factory RankingService() => _instance;
  RankingService._internal();

  final FirebaseRankingService _firebaseRankingService =
      FirebaseRankingService();

  List<RankingModel> _rankings = [];
  List<RankingModel> _weeklyRankings = [];
  List<RankingModel> _monthlyRankings = [];
  List<RankingModel> _friendsRankings = [];

  bool _isLoading = false;
  String? _error;

  StreamSubscription? _rankingSubscription;

  List<RankingModel> get rankings => _rankings;
  List<RankingModel> get weeklyRankings => _weeklyRankings;
  List<RankingModel> get monthlyRankings => _monthlyRankings;
  List<RankingModel> get friendsRankings => _friendsRankings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> initialize() async {
    await fetchRankings();
  }

  Future<void> fetchRankings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Fetch all rankings concurrently
      final results = await Future.wait([
        _firebaseRankingService.getGlobalRankings(),
        _firebaseRankingService.getWeeklyRankings(),
        _firebaseRankingService.getMonthlyRankings(),
        _getCurrentUserFriendsRankings(),
      ]);

      _rankings = results[0];
      _weeklyRankings = results[1];
      _monthlyRankings = results[2];
      _friendsRankings = results[3];

      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<RankingModel>> _getCurrentUserFriendsRankings() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return [];

    return await _firebaseRankingService.getFriendsRankings(currentUser.uid);
  }

  /// Update user steps and refresh rankings
  Future<void> updateUserSteps(int steps) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      await _firebaseRankingService.updateUserSteps(currentUser.uid, steps);
      // Refresh rankings after update
      await fetchRankings();
    } catch (e) {
      debugPrint('Error updating user steps: $e');
    }
  }

  /// Get user's current ranking position
  Future<int> getUserRankingPosition() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return -1;

    return await _firebaseRankingService
        .getUserRankingPosition(currentUser.uid);
  }

  /// Start real-time ranking updates
  void startRealTimeUpdates() {
    _rankingSubscription?.cancel();
    _rankingSubscription =
        _firebaseRankingService.streamGlobalRankings().listen(
      (rankings) {
        _rankings = rankings;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Ranking stream error: $error');
        // Retry after 30 seconds
        Future.delayed(const Duration(seconds: 30), () {
          if (_rankingSubscription == null) {
            startRealTimeUpdates();
          }
        });
      },
      cancelOnError: false,
    );
  }

  /// Stop real-time updates
  void stopRealTimeUpdates() {
    _rankingSubscription?.cancel();
    _rankingSubscription = null;
  }

  /// Distribute weekly rewards (admin function)
  Future<void> distributeWeeklyRewards() async {
    try {
      await _firebaseRankingService.distributeWeeklyRewards();
    } catch (e) {
      debugPrint('Error distributing weekly rewards: $e');
    }
  }

  /// Distribute monthly rewards (admin function)
  Future<void> distributeMonthlyRewards() async {
    try {
      await _firebaseRankingService.distributeMonthlyRewards();
    } catch (e) {
      debugPrint('Error distributing monthly rewards: $e');
    }
  }

  @override
  void dispose() {
    _rankingSubscription?.cancel();
    super.dispose();
  }
}
