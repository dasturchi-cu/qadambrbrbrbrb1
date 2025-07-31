import 'package:cloud_firestore/cloud_firestore.dart';

class ReferralModel {
  final String id;
  final String referrerId;
  final String referredId;
  final DateTime date;
  final String? referredUserName;

  ReferralModel({
    required this.id,
    required this.referrerId,
    required this.referredId,
    required this.date,
    this.referredUserName,
  });

  factory ReferralModel.fromMap(Map<String, dynamic> map, String id) {
    return ReferralModel(
      id: id,
      referrerId: map['referrerId'] ?? '',
      referredId: map['referredId'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      referredUserName: map['referredUserName'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'referrerId': referrerId,
      'referredId': referredId,
      'date': date,
      'referredUserName': referredUserName,
    };
  }
}
