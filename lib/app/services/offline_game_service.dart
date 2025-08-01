import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'connectivity_service.dart';
import '../screens/dinosaur_game_screen.dart';
import '../screens/offline_game_screen.dart';

class OfflineGameService extends ChangeNotifier {
  static final OfflineGameService _instance = OfflineGameService._internal();
  factory OfflineGameService() => _instance;
  OfflineGameService._internal();

  final ConnectivityService _connectivityService = ConnectivityService();

  bool _isGameTriggered = false;
  bool _autoTriggerEnabled = true;
  Timer? _offlineTimer;
  Duration _offlineThreshold = const Duration(seconds: 10);
  DateTime? _offlineStartTime;

  // Game preferences
  GameType _preferredGame = GameType.dinosaur;
  bool _showGameNotificationEnabled = true;
  bool _vibrateOnTrigger = true;

  // Getters
  bool get isGameTriggered => _isGameTriggered;
  bool get autoTriggerEnabled => _autoTriggerEnabled;
  Duration get offlineThreshold => _offlineThreshold;
  GameType get preferredGame => _preferredGame;
  bool get showGameNotification => _showGameNotificationEnabled;
  bool get vibrateOnTrigger => _vibrateOnTrigger;

  Future<void> initialize() async {
    _connectivityService.addListener(_onConnectivityChanged);
  }

  void _onConnectivityChanged() {
    if (_connectivityService.isOffline) {
      _onOfflineDetected();
    } else {
      _onOnlineRestored();
    }
  }

  void _onOfflineDetected() {
    _offlineStartTime = DateTime.now();

    if (_autoTriggerEnabled) {
      _startOfflineTimer();
    }
  }

  void _onOnlineRestored() {
    _offlineTimer?.cancel();
    _offlineStartTime = null;

    if (_isGameTriggered) {
      _isGameTriggered = false;
      notifyListeners();
    }
  }

  void _startOfflineTimer() {
    _offlineTimer?.cancel();

    _offlineTimer = Timer(_offlineThreshold, () {
      if (_connectivityService.isOffline && !_isGameTriggered) {
        _triggerOfflineGame();
      }
    });
  }

  void _triggerOfflineGame() {
    _isGameTriggered = true;

    if (_vibrateOnTrigger) {
      HapticFeedback.mediumImpact();
    }

    notifyListeners();

    // Show game notification if enabled
    if (_showGameNotificationEnabled) {
      _showGameNotificationDialog();
    }
  }

  void _showGameNotificationDialog() {
    // This would typically show a snackbar or dialog
    // Implementation depends on having access to BuildContext
  }

  // Manual game trigger
  void triggerGame(BuildContext context) {
    _navigateToGame(context);
  }

  void _navigateToGame(BuildContext context) {
    Widget gameScreen;

    switch (_preferredGame) {
      case GameType.dinosaur:
        gameScreen = const DinosaurGameScreen();
        break;
      case GameType.bubble:
        gameScreen = const OfflineGameScreen();
        break;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => gameScreen,
        fullscreenDialog: true,
      ),
    );
  }

  // Settings
  void setAutoTriggerEnabled(bool enabled) {
    _autoTriggerEnabled = enabled;
    notifyListeners();

    if (!enabled) {
      _offlineTimer?.cancel();
      _isGameTriggered = false;
    } else if (_connectivityService.isOffline && _offlineStartTime != null) {
      final elapsed = DateTime.now().difference(_offlineStartTime!);
      if (elapsed >= _offlineThreshold) {
        _triggerOfflineGame();
      } else {
        _startOfflineTimer();
      }
    }
  }

  void setOfflineThreshold(Duration threshold) {
    _offlineThreshold = threshold;
    notifyListeners();
  }

  void setPreferredGame(GameType game) {
    _preferredGame = game;
    notifyListeners();
  }

  void setShowGameNotification(bool show) {
    _showGameNotificationEnabled = show;
    notifyListeners();
  }

  void setVibrateOnTrigger(bool vibrate) {
    _vibrateOnTrigger = vibrate;
    notifyListeners();
  }

  // Game statistics
  Map<String, dynamic> getGameStats() {
    return {
      'totalGamesTriggered': 0, // Would be stored in SharedPreferences
      'totalTimeInGame': Duration.zero,
      'favoriteGame': _preferredGame.name,
      'averageGameDuration': Duration.zero,
    };
  }

  // Utility methods
  String getOfflineTimeString() {
    if (_offlineStartTime == null) return 'Onlayn';

    final elapsed = DateTime.now().difference(_offlineStartTime!);
    if (elapsed.inSeconds < 60) {
      return '${elapsed.inSeconds} soniya oflayn';
    } else if (elapsed.inMinutes < 60) {
      return '${elapsed.inMinutes} daqiqa oflayn';
    } else {
      return '${elapsed.inHours} soat oflayn';
    }
  }

  String getTimeUntilGameTrigger() {
    if (_offlineStartTime == null || !_autoTriggerEnabled) {
      return '';
    }

    final elapsed = DateTime.now().difference(_offlineStartTime!);
    final remaining = _offlineThreshold - elapsed;

    if (remaining.isNegative) {
      return 'O\'yin tayyor!';
    } else {
      return '${remaining.inSeconds} soniyada o\'yin';
    }
  }

  bool shouldShowGameButton() {
    return _connectivityService.isOffline &&
        (_isGameTriggered || !_autoTriggerEnabled);
  }

  @override
  void dispose() {
    _offlineTimer?.cancel();
    _connectivityService.removeListener(_onConnectivityChanged);
    super.dispose();
  }
}

enum GameType {
  dinosaur,
  bubble,
}

extension GameTypeExtension on GameType {
  String get name {
    switch (this) {
      case GameType.dinosaur:
        return 'Dinosaur Runner';
      case GameType.bubble:
        return 'Bubble Pop';
    }
  }

  String get description {
    switch (this) {
      case GameType.dinosaur:
        return 'Chrome Dinosaur ga o\'xshash o\'yin';
      case GameType.bubble:
        return 'Rangdor pufakchalarni bosish o\'yini';
    }
  }

  IconData get icon {
    switch (this) {
      case GameType.dinosaur:
        return Icons.directions_run;
      case GameType.bubble:
        return Icons.bubble_chart;
    }
  }
}
