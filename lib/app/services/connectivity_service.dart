import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'dart:async';

enum ConnectionStatus {
  online,
  offline,
  checking,
}

class ConnectivityService extends ChangeNotifier {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final InternetConnectionChecker _internetChecker =
      InternetConnectionChecker();

  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  StreamSubscription<InternetConnectionStatus>? _internetSubscription;

  ConnectionStatus _connectionStatus = ConnectionStatus.checking;
  ConnectivityResult _connectivityResult = ConnectivityResult.none;
  bool _hasInternetAccess = false;
  DateTime? _lastOnlineTime;
  Duration _offlineDuration = Duration.zero;
  Timer? _offlineTimer;

  // Getters
  ConnectionStatus get connectionStatus => _connectionStatus;
  ConnectivityResult get connectivityResult => _connectivityResult;
  bool get isOnline => _connectionStatus == ConnectionStatus.online;
  bool get isOffline => _connectionStatus == ConnectionStatus.offline;
  bool get hasInternetAccess => _hasInternetAccess;
  DateTime? get lastOnlineTime => _lastOnlineTime;
  Duration get offlineDuration => _offlineDuration;

  // Connection type getters
  bool get isWifi => _connectivityResult == ConnectivityResult.wifi;
  bool get isMobile => _connectivityResult == ConnectivityResult.mobile;
  bool get isEthernet => _connectivityResult == ConnectivityResult.ethernet;

  Future<void> initialize() async {
    try {
      // Dastlabki holatni tekshirish
      await _checkInitialConnection();

      // Connectivity o'zgarishlarini kuzatish
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _onConnectivityChanged,
        onError: (error) {
          debugPrint('Connectivity subscription error: $error');
        },
        cancelOnError: false,
      );

      // Internet access o'zgarishlarini kuzatish
      _internetSubscription = _internetChecker.onStatusChange.listen(
        _onInternetStatusChanged,
        onError: (error) {
          debugPrint('Internet checker subscription error: $error');
        },
        cancelOnError: false,
      );

      debugPrint('ConnectivityService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing ConnectivityService: $e');
    }
  }

  Future<void> _checkInitialConnection() async {
    try {
      _connectivityResult = await _connectivity.checkConnectivity();
      _hasInternetAccess = await _internetChecker.hasConnection;

      _updateConnectionStatus();
    } catch (e) {
      debugPrint('Dastlabki ulanishni tekshirishda xatolik: $e');
      _connectionStatus = ConnectionStatus.offline;
      notifyListeners();
    }
  }

  void _onConnectivityChanged(ConnectivityResult result) {
    _connectivityResult = result;
    _updateConnectionStatus();
  }

  void _onInternetStatusChanged(InternetConnectionStatus status) {
    _hasInternetAccess = status == InternetConnectionStatus.connected;
    _updateConnectionStatus();
  }

  void _updateConnectionStatus() {
    final previousStatus = _connectionStatus;

    if (_connectivityResult == ConnectivityResult.none || !_hasInternetAccess) {
      _connectionStatus = ConnectionStatus.offline;

      // Offline timer boshlash
      if (previousStatus == ConnectionStatus.online) {
        _startOfflineTimer();
      }
    } else {
      _connectionStatus = ConnectionStatus.online;
      _lastOnlineTime = DateTime.now();

      // Offline timer to'xtatish
      _stopOfflineTimer();
      _offlineDuration = Duration.zero;
    }

    // Status o'zgargan bo'lsa, listeners ga xabar berish
    if (previousStatus != _connectionStatus) {
      debugPrint('Internet holati o\'zgardi: ${_connectionStatus.name}');
      notifyListeners();
    }
  }

  void _startOfflineTimer() {
    _stopOfflineTimer();
    final startTime = DateTime.now();

    _offlineTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _offlineDuration = DateTime.now().difference(startTime);
      notifyListeners();
    });
  }

  void _stopOfflineTimer() {
    _offlineTimer?.cancel();
    _offlineTimer = null;
  }

  // Manual ravishda ulanishni tekshirish
  Future<bool> checkConnection() async {
    _connectionStatus = ConnectionStatus.checking;
    notifyListeners();

    try {
      _connectivityResult = await _connectivity.checkConnectivity();
      _hasInternetAccess = await _internetChecker.hasConnection;

      _updateConnectionStatus();
      return isOnline;
    } catch (e) {
      debugPrint('Ulanishni tekshirishda xatolik: $e');
      _connectionStatus = ConnectionStatus.offline;
      notifyListeners();
      return false;
    }
  }

  // Connection type string
  String getConnectionTypeString() {
    switch (_connectivityResult) {
      case ConnectivityResult.wifi:
        return 'Wi-Fi';
      case ConnectivityResult.mobile:
        return 'Mobil internet';
      case ConnectivityResult.ethernet:
        return 'Ethernet';
      case ConnectivityResult.bluetooth:
        return 'Bluetooth';
      case ConnectivityResult.vpn:
        return 'VPN';
      case ConnectivityResult.other:
        return 'Boshqa';
      case ConnectivityResult.none:
      default:
        return 'Ulanish yo\'q';
    }
  }

  // Connection status string
  String getConnectionStatusString() {
    switch (_connectionStatus) {
      case ConnectionStatus.online:
        return 'Onlayn';
      case ConnectionStatus.offline:
        return 'Oflayn';
      case ConnectionStatus.checking:
        return 'Tekshirilmoqda...';
    }
  }

  // Offline duration string
  String getOfflineDurationString() {
    if (_offlineDuration.inSeconds < 60) {
      return '${_offlineDuration.inSeconds} soniya';
    } else if (_offlineDuration.inMinutes < 60) {
      return '${_offlineDuration.inMinutes} daqiqa';
    } else {
      return '${_offlineDuration.inHours} soat ${_offlineDuration.inMinutes % 60} daqiqa';
    }
  }

  // Network quality assessment
  NetworkQuality getNetworkQuality() {
    if (!isOnline) return NetworkQuality.none;

    if (isWifi) {
      return NetworkQuality.excellent;
    } else if (isMobile) {
      return NetworkQuality.good;
    } else {
      return NetworkQuality.fair;
    }
  }

  // Retry connection
  Future<bool> retryConnection({int maxRetries = 3}) async {
    for (int i = 0; i < maxRetries; i++) {
      debugPrint('Ulanishni qayta urinish: ${i + 1}/$maxRetries');

      final isConnected = await checkConnection();
      if (isConnected) {
        return true;
      }

      // Keyingi urinish oldidan kutish
      if (i < maxRetries - 1) {
        await Future.delayed(Duration(seconds: (i + 1) * 2));
      }
    }

    return false;
  }

  // Show connection status message
  String getConnectionMessage() {
    switch (_connectionStatus) {
      case ConnectionStatus.online:
        return 'Internet aloqasi mavjud (${getConnectionTypeString()})';
      case ConnectionStatus.offline:
        return 'Internet aloqasi yo\'q. Oflayn rejimda ishlayapti.';
      case ConnectionStatus.checking:
        return 'Internet aloqasi tekshirilmoqda...';
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _internetSubscription?.cancel();
    _stopOfflineTimer();
    super.dispose();
  }
}

enum NetworkQuality {
  none,
  poor,
  fair,
  good,
  excellent,
}

extension NetworkQualityExtension on NetworkQuality {
  String get name {
    switch (this) {
      case NetworkQuality.none:
        return 'Yo\'q';
      case NetworkQuality.poor:
        return 'Yomon';
      case NetworkQuality.fair:
        return 'O\'rtacha';
      case NetworkQuality.good:
        return 'Yaxshi';
      case NetworkQuality.excellent:
        return 'A\'lo';
    }
  }

  String get description {
    switch (this) {
      case NetworkQuality.none:
        return 'Internet aloqasi yo\'q';
      case NetworkQuality.poor:
        return 'Sekin internet aloqasi';
      case NetworkQuality.fair:
        return 'O\'rtacha internet aloqasi';
      case NetworkQuality.good:
        return 'Yaxshi internet aloqasi';
      case NetworkQuality.excellent:
        return 'A\'lo internet aloqasi';
    }
  }
}
