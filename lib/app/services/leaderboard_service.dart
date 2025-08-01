import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class LeaderboardService extends ChangeNotifier {
  List<Map<String, dynamic>> _weeklyLeaders = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get weeklyLeaders => _weeklyLeaders;
  bool get isLoading => _isLoading;

  Future<void> fetchWeeklyLeaderboard() async {
    _isLoading = true;
    notifyListeners();

    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));

    final snapshot = await FirebaseFirestore.instance
        .collection('user_stats')
        .where('date', isGreaterThanOrEqualTo: weekStart)
        .orderBy('steps', descending: true)
        .limit(10)
        .get();

    _weeklyLeaders = snapshot.docs.map((doc) => doc.data()).toList();
    _isLoading = false;
    notifyListeners();
  }
}
