import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/ranking_model.dart';

class RankingService extends ChangeNotifier {
  List<RankingModel> _rankings = [];
  bool _isLoading = false;
  String? _error;

  List<RankingModel> get rankings => _rankings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchRankings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .orderBy('steps', descending: true)
          .get();
      _rankings = [];
      int rank = 1;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        _rankings.add(RankingModel(
          userId: doc.id,
          name: data['name'] ?? '',
          steps: data['steps'] ?? 0,
          rank: rank,
        ));
        rank++;
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }
} 