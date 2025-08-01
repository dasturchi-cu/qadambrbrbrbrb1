import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'dart:io';
import '../models/transaction_model.dart';

class OfflineStorageService {
  static final OfflineStorageService _instance =
      OfflineStorageService._internal();
  factory OfflineStorageService() => _instance;
  OfflineStorageService._internal();

  Database? _database;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, 'qadam_offline.db');

      _database = await openDatabase(
        path,
        version: 1,
        onCreate: _createTables,
        onUpgrade: _upgradeDatabase,
      );

      _isInitialized = true;
      debugPrint('Offline database initialized');
    } catch (e) {
      debugPrint('Offline database initialization error: $e');
    }
  }

  Future<void> _createTables(Database db, int version) async {
    // Steps table
    await db.execute('''
      CREATE TABLE steps (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        steps INTEGER NOT NULL,
        date TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        synced INTEGER DEFAULT 0
      )
    ''');

    // Transactions table
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        type TEXT NOT NULL,
        amount INTEGER NOT NULL,
        description TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        metadata TEXT,
        synced INTEGER DEFAULT 0
      )
    ''');

    // Challenges table
    await db.execute('''
      CREATE TABLE challenges (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        challenge_id TEXT NOT NULL,
        progress INTEGER NOT NULL,
        completed INTEGER DEFAULT 0,
        completed_at INTEGER,
        synced INTEGER DEFAULT 0
      )
    ''');

    // Achievements table
    await db.execute('''
      CREATE TABLE achievements (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        achievement_id TEXT NOT NULL,
        unlocked_at INTEGER NOT NULL,
        synced INTEGER DEFAULT 0
      )
    ''');

    // User stats table
    await db.execute('''
      CREATE TABLE user_stats (
        user_id TEXT PRIMARY KEY,
        level INTEGER DEFAULT 1,
        xp INTEGER DEFAULT 0,
        total_steps INTEGER DEFAULT 0,
        total_coins INTEGER DEFAULT 0,
        daily_streak INTEGER DEFAULT 0,
        last_active INTEGER,
        synced INTEGER DEFAULT 0
      )
    ''');

    // Sync queue table
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        action TEXT NOT NULL,
        data TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        retry_count INTEGER DEFAULT 0
      )
    ''');
  }

  Future<void> _upgradeDatabase(
      Database db, int oldVersion, int newVersion) async {
    // Database upgrade logic
    debugPrint('Upgrading database from $oldVersion to $newVersion');
  }

  // Steps operations
  Future<void> saveStepsOffline(String userId, int steps, DateTime date) async {
    if (!_isInitialized || _database == null) return;

    try {
      await _database!.insert(
        'steps',
        {
          'user_id': userId,
          'steps': steps,
          'date': date.toIso8601String().split('T')[0],
          'timestamp': date.millisecondsSinceEpoch,
          'synced': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      debugPrint('Steps saved offline: $steps for $userId');
    } catch (e) {
      debugPrint('Error saving steps offline: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getUnsyncedSteps(String userId) async {
    if (!_isInitialized || _database == null) return [];

    try {
      return await _database!.query(
        'steps',
        where: 'user_id = ? AND synced = 0',
        whereArgs: [userId],
        orderBy: 'timestamp ASC',
      );
    } catch (e) {
      debugPrint('Error getting unsynced steps: $e');
      return [];
    }
  }

  Future<void> markStepsSynced(List<int> stepIds) async {
    if (!_isInitialized || _database == null) return;

    try {
      final batch = _database!.batch();
      for (final id in stepIds) {
        batch.update(
          'steps',
          {'synced': 1},
          where: 'id = ?',
          whereArgs: [id],
        );
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error marking steps as synced: $e');
    }
  }

  // Transaction operations
  Future<void> saveTransactionOffline(TransactionModel transaction) async {
    if (!_isInitialized || _database == null) return;

    try {
      await _database!.insert(
        'transactions',
        {
          'id': transaction.id.isEmpty
              ? DateTime.now().millisecondsSinceEpoch.toString()
              : transaction.id,
          'user_id': transaction.userId,
          'type': transaction.type.toString(),
          'amount': transaction.amount,
          'description': transaction.description,
          'timestamp': transaction.timestamp.millisecondsSinceEpoch,
          'metadata': transaction.metadata != null
              ? jsonEncode(transaction.metadata)
              : null,
          'synced': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      debugPrint('Transaction saved offline: ${transaction.description}');
    } catch (e) {
      debugPrint('Error saving transaction offline: $e');
    }
  }

  Future<List<TransactionModel>> getOfflineTransactions(String userId) async {
    if (!_isInitialized || _database == null) return [];

    try {
      final maps = await _database!.query(
        'transactions',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'timestamp DESC',
      );

      return maps.map((map) {
        return TransactionModel(
          id: map['id'] as String,
          userId: map['user_id'] as String,
          type: TransactionType.values.firstWhere(
            (e) => e.toString() == map['type'],
            orElse: () => TransactionType.earned,
          ),
          amount: map['amount'] as int,
          description: map['description'] as String,
          timestamp:
              DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
          metadata: map['metadata'] != null
              ? jsonDecode(map['metadata'] as String)
              : null,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error getting offline transactions: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getUnsyncedTransactions(
      String userId) async {
    if (!_isInitialized || _database == null) return [];

    try {
      return await _database!.query(
        'transactions',
        where: 'user_id = ? AND synced = 0',
        whereArgs: [userId],
        orderBy: 'timestamp ASC',
      );
    } catch (e) {
      debugPrint('Error getting unsynced transactions: $e');
      return [];
    }
  }

  // User stats operations
  Future<void> saveUserStatsOffline(
      String userId, Map<String, dynamic> stats) async {
    if (!_isInitialized || _database == null) return;

    try {
      await _database!.insert(
        'user_stats',
        {
          'user_id': userId,
          'level': stats['level'] ?? 1,
          'xp': stats['xp'] ?? 0,
          'total_steps': stats['totalSteps'] ?? 0,
          'total_coins': stats['totalCoins'] ?? 0,
          'daily_streak': stats['dailyStreak'] ?? 0,
          'last_active': DateTime.now().millisecondsSinceEpoch,
          'synced': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('Error saving user stats offline: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserStatsOffline(String userId) async {
    if (!_isInitialized || _database == null) return null;

    try {
      final maps = await _database!.query(
        'user_stats',
        where: 'user_id = ?',
        whereArgs: [userId],
        limit: 1,
      );

      return maps.isNotEmpty ? maps.first : null;
    } catch (e) {
      debugPrint('Error getting user stats offline: $e');
      return null;
    }
  }

  // Sync queue operations
  Future<void> addToSyncQueue(String tableName, String recordId, String action,
      Map<String, dynamic> data) async {
    if (!_isInitialized || _database == null) return;

    try {
      await _database!.insert('sync_queue', {
        'table_name': tableName,
        'record_id': recordId,
        'action': action,
        'data': jsonEncode(data),
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'retry_count': 0,
      });
    } catch (e) {
      debugPrint('Error adding to sync queue: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getSyncQueue() async {
    if (!_isInitialized || _database == null) return [];

    try {
      return await _database!.query(
        'sync_queue',
        orderBy: 'created_at ASC',
        limit: 50, // Batch size
      );
    } catch (e) {
      debugPrint('Error getting sync queue: $e');
      return [];
    }
  }

  Future<void> removeSyncQueueItem(int id) async {
    if (!_isInitialized || _database == null) return;

    try {
      await _database!.delete(
        'sync_queue',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      debugPrint('Error removing sync queue item: $e');
    }
  }

  Future<void> incrementSyncRetryCount(int id) async {
    if (!_isInitialized || _database == null) return;

    try {
      await _database!.update(
        'sync_queue',
        {'retry_count': 'retry_count + 1'},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      debugPrint('Error incrementing retry count: $e');
    }
  }

  // Database maintenance
  Future<void> clearOldData({int daysToKeep = 30}) async {
    if (!_isInitialized || _database == null) return;

    try {
      final cutoffTime = DateTime.now()
          .subtract(Duration(days: daysToKeep))
          .millisecondsSinceEpoch;

      await _database!.delete(
        'steps',
        where: 'timestamp < ? AND synced = 1',
        whereArgs: [cutoffTime],
      );

      await _database!.delete(
        'sync_queue',
        where: 'created_at < ? AND retry_count > 5',
        whereArgs: [cutoffTime],
      );

      debugPrint('Old offline data cleared');
    } catch (e) {
      debugPrint('Error clearing old data: $e');
    }
  }

  Future<int> getDatabaseSize() async {
    if (!_isInitialized || _database == null) return 0;

    try {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, 'qadam_offline.db');
      final file = await File(path).stat();
      return file.size;
    } catch (e) {
      debugPrint('Error getting database size: $e');
      return 0;
    }
  }

  // Public method for database access
  Future<void> updateRecord(String table, Map<String, dynamic> values,
      String where, List<dynamic> whereArgs) async {
    if (!_isInitialized || _database == null) return;

    try {
      await _database!
          .update(table, values, where: where, whereArgs: whereArgs);
    } catch (e) {
      debugPrint('Error updating record: $e');
    }
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
    _isInitialized = false;
  }
}
