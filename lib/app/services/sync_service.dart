import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'dart:convert';
import 'connectivity_service.dart';
import 'offline_storage_service.dart';

class SyncService extends ChangeNotifier {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final ConnectivityService _connectivityService = ConnectivityService();
  final OfflineStorageService _offlineStorage = OfflineStorageService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  int _pendingSyncItems = 0;
  String? _syncError;
  Timer? _autoSyncTimer;

  // Getters
  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;
  int get pendingSyncItems => _pendingSyncItems;
  String? get syncError => _syncError;
  bool get hasPendingSync => _pendingSyncItems > 0;

  Future<void> initialize() async {
    await _offlineStorage.initialize();

    // Connectivity o'zgarishlarini kuzatish
    _connectivityService.addListener(_onConnectivityChanged);

    // Auto sync timer
    _startAutoSyncTimer();

    // Dastlabki sync
    if (_connectivityService.isOnline) {
      await syncAll();
    }
  }

  void _onConnectivityChanged() {
    if (_connectivityService.isOnline && !_isSyncing) {
      // Internet qaytganda avtomatik sync
      syncAll();
    }
  }

  void _startAutoSyncTimer() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (_connectivityService.isOnline && !_isSyncing) {
        syncAll();
      }
    });
  }

  // Barcha ma'lumotlarni sinxronlashtirish
  Future<void> syncAll() async {
    if (_isSyncing || !_connectivityService.isOnline) {
      debugPrint(
          'Sync skipped: isSyncing=$_isSyncing, isOnline=${_connectivityService.isOnline}');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('Sync skipped: User not logged in');
      return;
    }

    _isSyncing = true;
    _syncError = null;
    notifyListeners();

    try {
      debugPrint('🔄 Sync boshlandi...');

      // Pending items sonini hisoblash
      await _updatePendingSyncCount(user.uid);

      // Qadamlarni sync qilish
      await _syncSteps(user.uid);

      // Tranzaksiyalarni sync qilish
      await _syncTransactions(user.uid);

      // User stats ni sync qilish
      await _syncUserStats(user.uid);

      // Sync queue ni qayta ishlash
      await _processSyncQueue();

      _lastSyncTime = DateTime.now();
      await _updatePendingSyncCount(user.uid);

      debugPrint('Sync muvaffaqiyatli yakunlandi');
    } catch (e) {
      _syncError = e.toString();
      debugPrint('Sync xatoligi: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  // Qadamlarni sinxronlashtirish
  Future<void> _syncSteps(String userId) async {
    try {
      final unsyncedSteps = await _offlineStorage.getUnsyncedSteps(userId);

      if (unsyncedSteps.isEmpty) return;

      debugPrint('${unsyncedSteps.length} ta qadamni sync qilish...');

      final batch = _firestore.batch();
      final syncedIds = <int>[];

      for (final stepData in unsyncedSteps) {
        final docRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('daily_steps')
            .doc(stepData['date']);

        batch.set(
            docRef,
            {
              'date': stepData['date'],
              'steps': stepData['steps'],
              'timestamp':
                  Timestamp.fromMillisecondsSinceEpoch(stepData['timestamp']),
              'synced': true,
            },
            SetOptions(merge: true));

        syncedIds.add(stepData['id']);
      }

      await batch.commit();
      await _offlineStorage.markStepsSynced(syncedIds);

      debugPrint('Qadamlar muvaffaqiyatli sync qilindi');
    } catch (e) {
      debugPrint('Qadamlarni sync qilishda xatolik: $e');
      rethrow;
    }
  }

  // Tranzaksiyalarni sinxronlashtirish
  Future<void> _syncTransactions(String userId) async {
    try {
      final unsyncedTransactions =
          await _offlineStorage.getUnsyncedTransactions(userId);

      if (unsyncedTransactions.isEmpty) return;

      debugPrint(
          '${unsyncedTransactions.length} ta tranzaksiyani sync qilish...');

      for (final transactionData in unsyncedTransactions) {
        final docRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('transactions')
            .doc(transactionData['id']);

        await docRef.set({
          'userId': transactionData['user_id'],
          'type': transactionData['type'],
          'amount': transactionData['amount'],
          'description': transactionData['description'],
          'timestamp': Timestamp.fromMillisecondsSinceEpoch(
              transactionData['timestamp']),
          'metadata': transactionData['metadata'],
          'synced': true,
        });

        // Local da synced deb belgilash
        await _offlineStorage.updateRecord(
          'transactions',
          {'synced': 1},
          'id = ?',
          [transactionData['id']],
        );
      }

      debugPrint('Tranzaksiyalar muvaffaqiyatli sync qilindi');
    } catch (e) {
      debugPrint('Tranzaksiyalarni sync qilishda xatolik: $e');
      rethrow;
    }
  }

  // User stats ni sinxronlashtirish
  Future<void> _syncUserStats(String userId) async {
    try {
      final localStats = await _offlineStorage.getUserStatsOffline(userId);
      if (localStats == null || localStats['synced'] == 1) return;

      debugPrint('User stats ni sync qilish...');

      await _firestore.collection('users').doc(userId).update({
        'level': localStats['level'],
        'xp': localStats['xp'],
        'totalSteps': localStats['total_steps'],
        'totalCoins': localStats['total_coins'],
        'dailyStreak': localStats['daily_streak'],
        'lastActive':
            Timestamp.fromMillisecondsSinceEpoch(localStats['last_active']),
        'lastSyncTime': FieldValue.serverTimestamp(),
      });

      // Local da synced deb belgilash
      await _offlineStorage.updateRecord(
        'user_stats',
        {'synced': 1},
        'user_id = ?',
        [userId],
      );

      debugPrint('User stats muvaffaqiyatli sync qilindi');
    } catch (e) {
      debugPrint('User stats ni sync qilishda xatolik: $e');
      rethrow;
    }
  }

  // Sync queue ni qayta ishlash
  Future<void> _processSyncQueue() async {
    try {
      final queueItems = await _offlineStorage.getSyncQueue();

      if (queueItems.isEmpty) return;

      debugPrint('${queueItems.length} ta sync queue item ni qayta ishlash...');

      for (final item in queueItems) {
        try {
          await _processSyncQueueItem(item);
          await _offlineStorage.removeSyncQueueItem(item['id']);
        } catch (e) {
          debugPrint('Sync queue item xatoligi: $e');

          // Retry count ni oshirish
          await _offlineStorage.incrementSyncRetryCount(item['id']);

          // 5 martadan ko'p urinish bo'lsa, o'chirish
          if (item['retry_count'] >= 5) {
            await _offlineStorage.removeSyncQueueItem(item['id']);
            debugPrint(
                'Sync queue item 5 martadan ko\'p urinildi, o\'chirildi');
          }
        }
      }
    } catch (e) {
      debugPrint('Sync queue ni qayta ishlashda xatolik: $e');
    }
  }

  Future<void> _processSyncQueueItem(Map<String, dynamic> item) async {
    final tableName = item['table_name'];
    final recordId = item['record_id'];
    final action = item['action'];
    final data = Map<String, dynamic>.from(jsonDecode(item['data']));

    switch (tableName) {
      case 'achievements':
        if (action == 'insert') {
          await _firestore
              .collection('users')
              .doc(data['userId'])
              .collection('achievements')
              .doc(recordId)
              .set(data);
        }
        break;
      case 'challenges':
        if (action == 'update') {
          await _firestore
              .collection('users')
              .doc(data['userId'])
              .collection('challenge_progress')
              .doc(recordId)
              .set(data, SetOptions(merge: true));
        }
        break;
      // Boshqa table'lar uchun ham qo'shish mumkin
    }
  }

  // Pending sync items sonini yangilash
  Future<void> _updatePendingSyncCount(String userId) async {
    try {
      final unsyncedSteps = await _offlineStorage.getUnsyncedSteps(userId);
      final unsyncedTransactions =
          await _offlineStorage.getUnsyncedTransactions(userId);
      final queueItems = await _offlineStorage.getSyncQueue();

      _pendingSyncItems = unsyncedSteps.length +
          unsyncedTransactions.length +
          queueItems.length;
    } catch (e) {
      debugPrint('Pending sync count yangilashda xatolik: $e');
    }
  }

  // Manual sync
  Future<void> forcSync() async {
    if (_isSyncing) return;

    debugPrint('Manual sync boshlandi');
    await syncAll();
  }

  // Sync status string
  String getSyncStatusString() {
    if (_isSyncing) {
      return 'Sinxronlashtirilmoqda...';
    } else if (_syncError != null) {
      return 'Sinxronlashda xatolik';
    } else if (_pendingSyncItems > 0) {
      return '$_pendingSyncItems ta element kutilmoqda';
    } else {
      return 'Barcha ma\'lumotlar sinxronlashtirilgan';
    }
  }

  // Last sync time string
  String getLastSyncTimeString() {
    if (_lastSyncTime == null) {
      return 'Hech qachon sinxronlashtirilmagan';
    }

    final now = DateTime.now();
    final difference = now.difference(_lastSyncTime!);

    if (difference.inMinutes < 1) {
      return 'Hozirgina sinxronlashtirildi';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} daqiqa oldin';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} soat oldin';
    } else {
      return '${difference.inDays} kun oldin';
    }
  }

  @override
  void dispose() {
    _autoSyncTimer?.cancel();
    _connectivityService.removeListener(_onConnectivityChanged);
    super.dispose();
  }
}
