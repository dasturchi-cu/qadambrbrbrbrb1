import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/transaction_model.dart';

class DailyStats {
  final String day;
  final int steps;
  final int coins;
  final DateTime date;
  DailyStats(
      {required this.day,
      required this.steps,
      required this.coins,
      required this.date});
}

class StatisticsData {
  final int totalEarned;
  final int totalSpent;
  final int totalSteps;
  final int totalDays;
  final int todayEarned;
  final int todaySteps;
  final int weeklyEarned;
  final int monthlyEarned;
  final Map<String, int> categoryBreakdown;

  StatisticsData({
    required this.totalEarned,
    required this.totalSpent,
    required this.totalSteps,
    required this.totalDays,
    required this.todayEarned,
    required this.todaySteps,
    required this.weeklyEarned,
    required this.monthlyEarned,
    required this.categoryBreakdown,
  });
}

class StatisticsService extends ChangeNotifier {
  List<DailyStats> _weeklyStats = [];
  StatisticsData? _statistics;
  bool _isLoading = false;
  String? _error;

  List<DailyStats> get weeklyStats => _weeklyStats;
  StatisticsData? get statistics => _statistics;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchWeeklyStats(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('stats')
          .orderBy('date', descending: true)
          .limit(7)
          .get();

      _weeklyStats = snapshot.docs
          .map((doc) {
            final data = doc.data();
            return DailyStats(
              day: _formatDay(data['day']),
              steps: _toInt(data['steps']),
              coins: _toInt(data['coins']),
              date: (data['date'] as Timestamp).toDate(),
            );
          })
          .toList()
          .reversed
          .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Umumiy statistikalarni yuklash
  Future<void> loadStatistics(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Tranzaksiyalarni olish
      final transactionsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .get();

      final transactions = transactionsSnapshot.docs
          .map((doc) => TransactionModel.fromFirestore(doc))
          .toList();

      // User ma'lumotlarini olish
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      final userData = userDoc.data() ?? {};
      final totalSteps = userData['totalSteps'] ?? 0;

      // Statistikalarni hisoblash
      _statistics = _calculateStatistics(transactions, totalSteps);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  StatisticsData _calculateStatistics(
      List<TransactionModel> transactions, int totalSteps) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: now.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);

    int totalEarned = 0;
    int totalSpent = 0;
    int todayEarned = 0;
    int weeklyEarned = 0;
    int monthlyEarned = 0;
    Map<String, int> categoryBreakdown = {};

    for (final transaction in transactions) {
      if (transaction.isPositive) {
        totalEarned += transaction.amount;

        // Bugungi daromad
        if (transaction.timestamp.isAfter(today)) {
          todayEarned += transaction.amount;
        }

        // Haftalik daromad
        if (transaction.timestamp.isAfter(weekStart)) {
          weeklyEarned += transaction.amount;
        }

        // Oylik daromad
        if (transaction.timestamp.isAfter(monthStart)) {
          monthlyEarned += transaction.amount;
        }
      } else {
        totalSpent += transaction.amount.abs();
      }

      // Kategoriya bo'yicha breakdown
      final category = transaction.typeDisplayName;
      categoryBreakdown[category] =
          (categoryBreakdown[category] ?? 0) + transaction.amount;
    }

    // Nechta kun ishlatganini hisoblash
    final firstTransaction =
        transactions.isNotEmpty ? transactions.last.timestamp : now;
    final totalDays = now.difference(firstTransaction).inDays + 1;

    // Bugungi qadamlar (hozirgi qadamlar)
    final todaySteps = totalSteps;

    return StatisticsData(
      totalEarned: totalEarned,
      totalSpent: totalSpent,
      totalSteps: totalSteps,
      totalDays: totalDays,
      todayEarned: todayEarned,
      todaySteps: todaySteps,
      weeklyEarned: weeklyEarned,
      monthlyEarned: monthlyEarned,
      categoryBreakdown: categoryBreakdown,
    );
  }

  // Helper metodlar
  String _formatDay(dynamic day) {
    if (day == null) return 'Noma\'lum';
    if (day is String) return day;
    if (day is int) {
      final weekdays = [
        'Yakshanba',
        'Dushanba',
        'Seshanba',
        'Chorshanba',
        'Payshanba',
        'Juma',
        'Shanba'
      ];
      return weekdays[day % 7];
    }
    return day.toString();
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }
}
