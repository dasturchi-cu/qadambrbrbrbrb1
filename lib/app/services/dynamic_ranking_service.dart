import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/ranking_model.dart';
import 'active_user_service.dart';

/// 📊 Dynamic Ranking Service - Real-time active users ranking
class DynamicRankingService extends ChangeNotifier {
  static final DynamicRankingService _instance =
      DynamicRankingService._internal();
  factory DynamicRankingService() => _instance;
  DynamicRankingService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ActiveUserService _activeUserService = ActiveUserService();

  List<RankingModel> _activeRankings = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription? _activeUsersSubscription;
  Timer? _refreshTimer;

  // Getters
  List<RankingModel> get activeRankings => _activeRankings;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get activeUserCount => _activeRankings.length;

  /// Initialize dynamic ranking service
  Future<void> initialize() async {
    await _startRealTimeTracking();
    await _startPeriodicRefresh();
    debugPrint('📊 DynamicRankingService initialized');
  }

  /// Start real-time tracking of active users
  Future<void> _startRealTimeTracking() async {
    _activeUsersSubscription?.cancel();

    // Listen to active users collection changes
    _activeUsersSubscription = _firestore
        .collection('active_users')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .listen((snapshot) async {
      await _updateActiveRankings(snapshot.docs);
    });
  }

  /// Start periodic refresh every 30 seconds
  Future<void> _startPeriodicRefresh() async {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      await refreshActiveRankings();
    });
  }

  /// Update active rankings from snapshot
  Future<void> _updateActiveRankings(
      List<QueryDocumentSnapshot> activeDocs) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final now = DateTime.now();
      final tenMinutesAgo = now.subtract(const Duration(minutes: 10));

      final activeUserIds = <String>[];
      final activeUsersData = <Map<String, dynamic>>[];

      // Filter active users (seen within last 10 minutes) - more lenient
      for (final doc in activeDocs) {
        final data = doc.data() as Map<String, dynamic>;
        final lastSeen = data['lastSeen'] as int?;

        if (lastSeen != null) {
          final lastSeenTime = DateTime.fromMillisecondsSinceEpoch(lastSeen);

          // User must be seen recently (more lenient filter)
          if (lastSeenTime.isAfter(tenMinutesAgo)) {
            activeUserIds.add(doc.id);
          }
        }
      }

      // Get user details for active users
      for (final userId in activeUserIds) {
        try {
          final userDoc =
              await _firestore.collection('users').doc(userId).get();
          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>;
            activeUsersData.add({
              'userId': userId,
              'name': userData['name'] ??
                  userData['displayName'] ??
                  'Foydalanuvchi',
              'totalSteps': userData['totalSteps'] ?? 0,
              'photoUrl': userData['photoUrl'],
              'level': userData['level'] ?? 1,
              'totalCoins': userData['totalCoins'] ?? 0,
              'lastUpdated': userData['lastUpdated'],
            });
          }
        } catch (e) {
          debugPrint('❌ Error getting user data for $userId: $e');
        }
      }

      // Sort by total steps (descending)
      activeUsersData.sort(
          (a, b) => (b['totalSteps'] as int).compareTo(a['totalSteps'] as int));

      // Convert to RankingModel list
      _activeRankings = [];
      for (int i = 0; i < activeUsersData.length; i++) {
        final userData = activeUsersData[i];
        final ranking = RankingModel.fromMap(userData, i + 1);
        _activeRankings.add(ranking);
      }

      _isLoading = false;
      _error = null;

      debugPrint('📊 Active rankings updated: ${_activeRankings.length} users');
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      debugPrint('❌ Error updating active rankings: $e');
      notifyListeners();
    }
  }

  /// Manual refresh of active rankings
  Future<void> refreshActiveRankings() async {
    try {
      final snapshot = await _firestore
          .collection('active_users')
          .where('isActive', isEqualTo: true)
          .get();

      await _updateActiveRankings(snapshot.docs);
    } catch (e) {
      debugPrint('❌ Error refreshing active rankings: $e');
    }
  }

  /// Get current user's position in active rankings
  int? getCurrentUserPosition() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return null;

    for (int i = 0; i < _activeRankings.length; i++) {
      if (_activeRankings[i].userId == currentUser.uid) {
        return i + 1;
      }
    }
    return null;
  }

  /// Check if current user is in top 3
  bool isCurrentUserInTopThree() {
    final position = getCurrentUserPosition();
    return position != null && position <= 3;
  }

  /// Get top N active users
  List<RankingModel> getTopActiveUsers(int count) {
    return _activeRankings.take(count).toList();
  }

  /// Get active users excluding current user
  List<RankingModel> getActiveUsersExcludingCurrent() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return _activeRankings;

    return _activeRankings
        .where((user) => user.userId != currentUser.uid)
        .toList();
  }

  /// Stream of active user count
  Stream<int> get activeUserCountStream {
    return _firestore
        .collection('active_users')
        .where('isActive', isEqualTo: true)
        .where('realStepsDetected', isEqualTo: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final now = DateTime.now();
      final fiveMinutesAgo = now.subtract(const Duration(minutes: 5));

      int activeCount = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final lastSeen = data['lastSeen'] as int?;

        if (lastSeen != null) {
          final lastSeenTime = DateTime.fromMillisecondsSinceEpoch(lastSeen);
          if (lastSeenTime.isAfter(fiveMinutesAgo)) {
            activeCount++;
          }
        }
      }

      return activeCount;
    });
  }

  /// Get ranking change for user (compared to last update)
  Map<String, dynamic> getUserRankingChange(String userId) {
    // This would require storing previous rankings
    // For now, return neutral change
    return {
      'previousRank': null,
      'currentRank': getCurrentUserPosition(),
      'change': 0, // 0 = no change, positive = moved up, negative = moved down
      'isNew': false,
    };
  }

  /// Get competition status message
  String getCompetitionStatus() {
    final count = _activeRankings.length;
    final currentPosition = getCurrentUserPosition();

    if (count == 0) {
      return 'Hozirda faol foydalanuvchilar yo\'q';
    } else if (count == 1) {
      return 'Siz yagona faol foydalanuvchisiz! 👑';
    } else if (currentPosition == null) {
      return '$count ta faol foydalanuvchi raqobatlashmoqda';
    } else if (currentPosition == 1) {
      return 'Siz ${count}ta foydalanuvchi orasida 1-o\'rindasiz! 🥇';
    } else {
      return 'Siz ${count}ta foydalanuvchi orasida ${currentPosition}-o\'rindasiz';
    }
  }

  /// Get next competitor info
  Map<String, dynamic>? getNextCompetitor() {
    final currentPosition = getCurrentUserPosition();
    if (currentPosition == null || currentPosition == 1) return null;

    final nextUser = _activeRankings[currentPosition -
        2]; // -2 because list is 0-indexed and we want the user above
    final currentUser = _activeRankings[currentPosition - 1];
    final stepDifference = nextUser.steps - currentUser.steps;

    return {
      'user': nextUser,
      'stepDifference': stepDifference,
      'message': '${nextUser.name}dan $stepDifference qadam orqadasiz',
    };
  }

  /// Get follower info (user behind current user)
  Map<String, dynamic>? getFollowerInfo() {
    final currentPosition = getCurrentUserPosition();
    if (currentPosition == null || currentPosition >= _activeRankings.length)
      return null;

    final followerUser = _activeRankings[currentPosition]; // Next user in list
    final currentUser = _activeRankings[currentPosition - 1];
    final stepDifference = currentUser.steps - followerUser.steps;

    return {
      'user': followerUser,
      'stepDifference': stepDifference,
      'message': '${followerUser.name}dan $stepDifference qadam oldadasiz',
    };
  }

  @override
  void dispose() {
    _activeUsersSubscription?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }
}
