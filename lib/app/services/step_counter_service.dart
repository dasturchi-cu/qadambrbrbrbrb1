import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'ranking_service.dart';

class StepCounterService extends ChangeNotifier {
  int _steps = 0;
  int _dailyGoal = 10000;
  DateTime? _lastResetDate;
  String _status = 'stopped';
  Stream<StepCount>? _stepCountStream;
  StreamSubscription<StepCount>? _stepCountSubscription;
  late SharedPreferences _prefs;
  Timer? _syncTimer;
  bool _isInitialized = false;

  StepCounterService() {
    _initPrefs();
  }

  int get steps => _steps;
  int get dailyGoal => _dailyGoal;
  String get status => _status;
  bool get isInitialized => _isInitialized;

  Future<void> _initPrefs() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadSteps();
      await _loadGoal();
      await _checkForDailyReset();
      _isInitialized = true;
      _startSyncTimer();
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing StepCounterService: $e');
      _status = 'error: $e';
      notifyListeners();
    }
  }

  void _startSyncTimer() {
    _syncTimer?.cancel();
    // Sync every 30 seconds instead of every step
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isInitialized) {
        syncStepsWithFirestore();
      }
    });
  }

  Future<void> _loadSteps() async {
    _steps = _prefs.getInt('steps') ?? 0;
    final lastResetString = _prefs.getString('lastResetDate');
    if (lastResetString != null) {
      _lastResetDate = DateTime.parse(lastResetString);
    }
    notifyListeners();
  }

  Future<void> _loadGoal() async {
    _dailyGoal = _prefs.getInt('dailyGoal') ?? 10000;
    notifyListeners();
  }

  Future<void> setDailyGoal(int goal) async {
    _dailyGoal = goal;
    await _prefs.setInt('dailyGoal', goal);
    notifyListeners();
  }

  Future<void> _saveSteps() async {
    await _prefs.setInt('steps', _steps);
    await _prefs.setString('lastResetDate', DateTime.now().toIso8601String());
  }

  Future<void> _checkForDailyReset() async {
    if (_lastResetDate == null) {
      _lastResetDate = DateTime.now();
      await _prefs.setString(
          'lastResetDate', _lastResetDate!.toIso8601String());
      return;
    }

    final now = DateTime.now();
    final lastMidnight = DateTime(now.year, now.month, now.day);
    final resetMidnight = DateTime(
      _lastResetDate!.year,
      _lastResetDate!.month,
      _lastResetDate!.day,
    );

    if (lastMidnight.isAfter(resetMidnight)) {
      // New day, reset steps
      _steps = 0;
      _lastResetDate = now;
      await _saveSteps();
      notifyListeners();
    }
  }

  void startCounting() {
    if (!_isInitialized) {
      debugPrint('StepCounterService not initialized yet');
      return;
    }
    _setupPedometer();
    _status = 'counting';
    notifyListeners();
  }

  void stopCounting() {
    _stepCountSubscription?.cancel();
    _stepCountSubscription = null;
    _status = 'stopped';
    notifyListeners();
  }

  void _setupPedometer() {
    try {
      // Cancel existing subscription
      _stepCountSubscription?.cancel();

      _stepCountStream = Pedometer.stepCountStream;
      _stepCountSubscription = _stepCountStream?.listen(
        _onStepCount,
        onError: _onStepCountError,
        cancelOnError: false,
      );
    } catch (e) {
      debugPrint('Error setting up pedometer: $e');
      _status = 'error: $e';
      notifyListeners();
    }
  }

  void _onStepCount(StepCount event) async {
    try {
      final newSteps = event.steps;
      if (newSteps != _steps) {
        _steps = newSteps;
        await _saveSteps();

        // Only update challenges and rankings periodically, not on every step
        if (_steps % 100 == 0) {
          // Every 100 steps
          await _updateAllChallengeProgress();
          await _updateRankings();
        }

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error processing step count: $e');
    }
  }

  void _onStepCountError(error) {
    _status = 'error: $error';
    debugPrint('Step counter error: $error');

    // Try to restart pedometer after error
    Future.delayed(const Duration(seconds: 5), () {
      if (_status.contains('error')) {
        debugPrint('Attempting to restart pedometer...');
        _setupPedometer();
      }
    });

    notifyListeners();
  }

  // For testing or manual entry
  void addSteps(int count) {
    _steps += count;
    _saveSteps();
    // Don't sync immediately, let timer handle it
    notifyListeners();
  }

  /// Update rankings when steps change
  Future<void> _updateRankings() async {
    try {
      final rankingService = RankingService();
      await rankingService.updateUserSteps(_steps);
    } catch (e) {
      debugPrint('Error updating rankings: $e');
    }
  }

  void resetSteps() {
    _steps = 0;
    _saveSteps();
    notifyListeners();
  }

  // Sinxronizatsiya: lokal qadamlarni Firestore bilan bir xil qilish
  Future<void> syncStepsWithFirestore() async {
    if (!_isInitialized) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final statsDoc = userDoc.collection('stats').doc(today);

      // Firestore'dan mavjud qadamlarni olish
      final snapshot = await statsDoc.get();
      int firestoreSteps = 0;
      if (snapshot.exists) {
        firestoreSteps = snapshot.data()?['steps'] ?? 0;
      }

      // Agar lokal qadamlar ko'proq bo'lsa, Firestore'ga yozamiz
      if (_steps > firestoreSteps) {
        await statsDoc.set({
          'day': DateTime.now().weekday,
          'steps': _steps,
          'coins': 0, // coins logikasi CoinService'da
          'date': Timestamp.now(),
          'lastUpdated': Timestamp.now(),
        }, SetOptions(merge: true));

        debugPrint('Steps synced to Firestore: $_steps');
      } else if (firestoreSteps > _steps) {
        // Agar Firestore ko'proq bo'lsa, lokalga yozamiz
        _steps = firestoreSteps;
        await _saveSteps();
        notifyListeners();
        debugPrint('Steps synced from Firestore: $_steps');
      }
    } catch (e) {
      debugPrint('Error syncing steps with Firestore: $e');
    }
  }

  Future<void> _updateAllChallengeProgress() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final userChallenges = await FirebaseFirestore.instance
        .collection('user_challenges')
        .where('userId', isEqualTo: user.uid)
        .get();
    for (var doc in userChallenges.docs) {
      final data = doc.data();
      final challengeId = data['challengeId'];
      final targetSteps = await _getChallengeTargetSteps(challengeId);
      if (targetSteps > 0) {
        final progress = (_steps / targetSteps).clamp(0.0, 1.0);
        await FirebaseFirestore.instance
            .collection('user_challenges')
            .doc('${user.uid}_$challengeId')
            .update({'progress': progress, 'isCompleted': progress >= 1.0});
      }
    }
  }

  Future<int> _getChallengeTargetSteps(String challengeId) async {
    final doc = await FirebaseFirestore.instance
        .collection('challenges')
        .doc(challengeId)
        .get();
    if (doc.exists) {
      return doc.data()?['targetSteps'] ?? 0;
    }
    return 0;
  }

  @override
  void dispose() {
    _stepCountSubscription?.cancel();
    _syncTimer?.cancel();
    super.dispose();
  }
}
