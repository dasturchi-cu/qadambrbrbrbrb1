import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType {
  earned, // Tanga toplash
  spent, // Tanga sarflash
  reward, // Mukofot
  challenge, // Challenge mukofoti
  referral, // Referral mukofoti
  daily, // Kunlik bonus
  achievement, // Yutuq mukofoti
  shop, // Shop dan xarid
  withdraw // Pul yechish
}

class TransactionModel {
  final String id;
  final String userId;
  final TransactionType type;
  final int amount;
  final String description;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.description,
    required this.timestamp,
    this.metadata,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map, String id) {
    return TransactionModel(
      id: id,
      userId: map['userId'] ?? '',
      type: TransactionType.values.firstWhere(
        (e) => e.toString() == 'TransactionType.${map['type']}',
        orElse: () => TransactionType.earned,
      ),
      amount: map['amount'] is String
          ? int.tryParse(map['amount']) ?? 0
          : (map['amount'] as num).toInt(),
      description: map['description'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      metadata: map['metadata'],
    );
  }

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: TransactionType.values.firstWhere(
        (e) => e.toString() == 'TransactionType.${data['type']}',
        orElse: () => TransactionType.earned,
      ),
      amount: data['amount'] ?? 0,
      description: data['description'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type.toString().split('.').last,
      'amount': amount,
      'description': description,
      'timestamp': Timestamp.fromDate(timestamp),
      'metadata': metadata,
    };
  }

  String get typeDisplayName {
    switch (type) {
      case TransactionType.earned:
        return 'Qadam uchun tanga';
      case TransactionType.spent:
        return 'Tanga sarflandi';
      case TransactionType.reward:
        return 'Mukofot';
      case TransactionType.challenge:
        return 'Challenge mukofoti';
      case TransactionType.referral:
        return 'Referral mukofoti';
      case TransactionType.daily:
        return 'Kunlik bonus';
      case TransactionType.achievement:
        return 'Yutuq mukofoti';
      case TransactionType.shop:
        return 'Shop xaridi';
      case TransactionType.withdraw:
        return 'Pul yechish';
    }
  }

  String get amountDisplay {
    return amount >= 0 ? '+$amount' : '$amount';
  }

  bool get isPositive => amount >= 0;
}
