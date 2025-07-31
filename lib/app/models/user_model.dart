import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;

  UserModel({required this.id, required this.name, required this.email});
}

class AchievementModel {
  final String id;
  final String type;
  final String title;
  final String description;
  final DateTime date;

  AchievementModel({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.date,
  });

  factory AchievementModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime date;
    final rawDate = map['date'];
    if (rawDate is Timestamp) {
      date = rawDate.toDate();
    } else if (rawDate is String) {
      date = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else if (rawDate is DateTime) {
      date = rawDate;
    } else {
      date = DateTime.now();
    }
    return AchievementModel(
      id: id,
      type: map['type'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      date: date,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'title': title,
      'description': description,
      'date': date,
    };
  }
} 