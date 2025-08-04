import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

/// Service to track and manage active users for real-time rankings
class ActiveUserService extends ChangeNotifier {
  static final ActiveUserService _instance = ActiveUserService._internal();
  factory ActiveUserService() => _instance;
  ActiveUserService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Timer? _heartbeatTimer;
  Timer? _cleanupTimer;

  // Active users tracking
  final Set<String> _activeUserIds = {};
  DateTime? _lastStepUpdate;
  int _lastStepCount = 0;

  // Constants
  static const Duration _heartbeatInterval = Duration(minutes: 1);
  static const Duration _userActiveThreshold = Duration(minutes: 5);
  static const Duration _cleanupInterval = Duration(minutes: 10);

  Set<String> get activeUserIds => Set.unmodifiable(_activeUserIds);
  bool get isCurrentUserActive =>
      _activeUserIds.contains(_auth.currentUser?.uid);

  /// Initialize active user tracking
  Future<void> initialize() async {
    await _startHeartbeat();
    await _startCleanupTimer();
    await _loadActiveUsers();

    debugPrint('🟢 ActiveUserService initialized');
  }

  /// Start heartbeat to mark current user as active
  Future<void> _startHeartbeat() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // Mark user as active immediately
    await _markUserActive(currentUser.uid);

    // Start periodic heartbeat
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (timer) async {
      await _markUserActive(currentUser.uid);
    });
  }

  /// Mark user as active in Firestore
  Future<void> _markUserActive(String userId) async {
    try {
      final now = DateTime.now();
      final currentUser = _auth.currentUser;

      // Get user data from users collection
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data() ?? {};

      await _firestore.collection('active_users').doc(userId).set({
        'uid': userId,
        'userId': userId, // Keep for backward compatibility
        'name': userData['name'] ?? currentUser?.displayName ?? 'User',
        'email': userData['email'] ?? currentUser?.email ?? '',
        'photoURL': userData['photoURL'] ?? currentUser?.photoURL,
        'lastSeen': now.millisecondsSinceEpoch,
        'isActive': true,
        'lastStepUpdate': _lastStepUpdate?.millisecondsSinceEpoch,
        'currentSteps': _lastStepCount,
        'totalSteps': userData['totalSteps'] ?? 0,
        'todaySteps': userData['todaySteps'] ?? 0,
        'realStepsDetected': _lastStepCount > 0,
        'joinedAt': userData['createdAt'] ?? FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _activeUserIds.add(userId);
      notifyListeners();

      debugPrint('✅ User marked as active: $userId');
    } catch (e) {
      debugPrint('❌ Error marking user active: $e');
    }
  }

  /// Update user's step activity (called when real steps are detected)
  Future<void> updateStepActivity(int stepCount) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final now = DateTime.now();

    // Only update if steps actually increased (real movement detected)
    if (stepCount > _lastStepCount) {
      _lastStepUpdate = now;
      _lastStepCount = stepCount;

      // Mark user as active with step data
      await _firestore.collection('active_users').doc(currentUser.uid).update({
        'lastStepUpdate': now.millisecondsSinceEpoch,
        'currentSteps': stepCount,
        'lastSeen': now.millisecondsSinceEpoch,
        'isActive': true,
        'realStepsDetected': true,
      });

      debugPrint('📈 Real steps detected: $stepCount for ${currentUser.uid}');
    }
  }

  /// Start cleanup timer to remove inactive users
  Future<void> _startCleanupTimer() async {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(_cleanupInterval, (timer) async {
      await _cleanupInactiveUsers();
    });
  }

  /// Remove inactive users from active list
  Future<void> _cleanupInactiveUsers() async {
    try {
      final now = DateTime.now();
      final cutoffTime = now.subtract(_userActiveThreshold);

      final snapshot = await _firestore
          .collection('active_users')
          .where('lastSeen', isLessThan: cutoffTime.millisecondsSinceEpoch)
          .get();

      final batch = _firestore.batch();
      final inactiveUserIds = <String>[];

      for (final doc in snapshot.docs) {
        final userId = doc.id;
        inactiveUserIds.add(userId);

        // Mark as inactive instead of deleting
        batch.update(doc.reference, {
          'isActive': false,
          'inactiveSince': now.millisecondsSinceEpoch,
        });
      }

      await batch.commit();

      // Remove from local active set
      for (final userId in inactiveUserIds) {
        _activeUserIds.remove(userId);
      }

      if (inactiveUserIds.isNotEmpty) {
        debugPrint('🔴 Marked ${inactiveUserIds.length} users as inactive');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Error cleaning up inactive users: $e');
    }
  }

  /// Load currently active users
  Future<void> _loadActiveUsers() async {
    try {
      final now = DateTime.now();
      final cutoffTime = now.subtract(_userActiveThreshold);

      final snapshot = await _firestore
          .collection('active_users')
          .where('isActive', isEqualTo: true)
          .where('lastSeen', isGreaterThan: cutoffTime.millisecondsSinceEpoch)
          .get();

      _activeUserIds.clear();
      for (final doc in snapshot.docs) {
        _activeUserIds.add(doc.id);
      }

      debugPrint('✅ Loaded ${_activeUserIds.length} active users');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading active users: $e');
    }
  }

  /// Get active users with step data
  Future<List<Map<String, dynamic>>> getActiveUsersWithSteps() async {
    try {
      final now = DateTime.now();
      final cutoffTime = now.subtract(_userActiveThreshold);

      final snapshot = await _firestore
          .collection('active_users')
          .where('isActive', isEqualTo: true)
          .where('lastSeen', isGreaterThan: cutoffTime.millisecondsSinceEpoch)
          .where('realStepsDetected', isEqualTo: true)
          .get();

      final activeUsers = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();

        // Get user details from users collection
        final userDoc = await _firestore.collection('users').doc(doc.id).get();
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;

          activeUsers.add({
            'userId': doc.id,
            'name':
                userData['name'] ?? userData['displayName'] ?? 'Foydalanuvchi',
            'totalSteps': userData['totalSteps'] ?? 0,
            'currentSteps': data['currentSteps'] ?? 0,
            'lastStepUpdate': data['lastStepUpdate'],
            'lastSeen': data['lastSeen'],
            'photoUrl': userData['photoUrl'],
            'level': userData['level'] ?? 1,
            'totalCoins': userData['totalCoins'] ?? 0,
          });
        }
      }

      // Sort by total steps
      activeUsers.sort(
          (a, b) => (b['totalSteps'] as int).compareTo(a['totalSteps'] as int));

      return activeUsers;
    } catch (e) {
      debugPrint('❌ Error getting active users with steps: $e');
      return [];
    }
  }

  /// Check if user is genuinely active (has real step updates)
  Future<bool> isUserGenuinelyActive(String userId) async {
    try {
      final doc = await _firestore.collection('active_users').doc(userId).get();

      if (!doc.exists) return false;

      final data = doc.data() as Map<String, dynamic>;
      final lastStepUpdate = data['lastStepUpdate'] as int?;
      final realStepsDetected = data['realStepsDetected'] as bool? ?? false;

      if (!realStepsDetected || lastStepUpdate == null) return false;

      // Check if step update was recent (within last hour)
      final stepUpdateTime =
          DateTime.fromMillisecondsSinceEpoch(lastStepUpdate);
      final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));

      return stepUpdateTime.isAfter(oneHourAgo);
    } catch (e) {
      debugPrint('❌ Error checking if user is genuinely active: $e');
      return false;
    }
  }

  /// Stream of active users count
  Stream<int> get activeUsersCountStream {
    return _firestore
        .collection('active_users')
        .where('isActive', isEqualTo: true)
        .where('realStepsDetected', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Mark user as offline when app is closed
  Future<void> markUserOffline() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      await _firestore.collection('active_users').doc(currentUser.uid).update({
        'isActive': false,
        'lastSeen': DateTime.now().millisecondsSinceEpoch,
        'offlineAt': DateTime.now().millisecondsSinceEpoch,
      });

      _activeUserIds.remove(currentUser.uid);
      notifyListeners();

      debugPrint('🔴 User marked as offline: ${currentUser.uid}');
    } catch (e) {
      debugPrint('❌ Error marking user offline: $e');
    }
  }

  /// Dispose and cleanup
  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    _cleanupTimer?.cancel();
    markUserOffline();
    super.dispose();
  }
}

/// Active user model for easier data handling
class ActiveUser {
  final String userId;
  final String name;
  final int totalSteps;
  final int currentSteps;
  final DateTime lastStepUpdate;
  final DateTime lastSeen;
  final String? photoUrl;
  final int level;
  final int totalCoins;

  ActiveUser({
    required this.userId,
    required this.name,
    required this.totalSteps,
    required this.currentSteps,
    required this.lastStepUpdate,
    required this.lastSeen,
    this.photoUrl,
    required this.level,
    required this.totalCoins,
  });

  factory ActiveUser.fromMap(Map<String, dynamic> map) {
    return ActiveUser(
      userId: map['userId'] ?? '',
      name: map['name'] ?? 'Foydalanuvchi',
      totalSteps: map['totalSteps'] ?? 0,
      currentSteps: map['currentSteps'] ?? 0,
      lastStepUpdate:
          DateTime.fromMillisecondsSinceEpoch(map['lastStepUpdate'] ?? 0),
      lastSeen: DateTime.fromMillisecondsSinceEpoch(map['lastSeen'] ?? 0),
      photoUrl: map['photoUrl'],
      level: map['level'] ?? 1,
      totalCoins: map['totalCoins'] ?? 0,
    );
  }

  bool get isRecentlyActive {
    final fiveMinutesAgo = DateTime.now().subtract(const Duration(minutes: 5));
    return lastSeen.isAfter(fiveMinutesAgo);
  }

  bool get hasRecentSteps {
    final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
    return lastStepUpdate.isAfter(oneHourAgo);
  }
}
