import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qadam_app/app/services/coin_service.dart';

class ShopItem {
  final String id;
  final String name;
  final int cost;
  final String imageUrl;
  final bool available;
  final String? description;
  final String? category;

  ShopItem({
    required this.id,
    required this.name,
    required this.cost,
    required this.imageUrl,
    required this.available,
    this.description,
    this.category,
  });

  factory ShopItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ShopItem(
      id: doc.id,
      name: data['name'] ?? '',
      cost: data['cost'] ?? 0,
      imageUrl: data['imageUrl'] ?? '',
      available: data['available'] ?? true,
      description: data['description'],
      category: data['category'],
    );
  }
}

class ShopService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<ShopItem> _items = [];
  bool _isLoading = false;
  String? _error;

  List<ShopItem> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch shop items
  Future<void> fetchShopItems() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('shop_items')
          .where('available', isEqualTo: true)
          .orderBy('cost')
          .get();

      _items = snapshot.docs.map((doc) => ShopItem.fromFirestore(doc)).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Purchase item
  Future<bool> purchaseItem(ShopItem item, CoinService coinService) async {
    final user = _auth.currentUser;
    if (user == null) {
      _error = 'Foydalanuvchi aniqlanmadi';
      notifyListeners();
      return false;
    }

    if (coinService.coins < item.cost) {
      _error = 'Yetarli tangangiz yo\'q';
      notifyListeners();
      return false;
    }

    try {
      // User ma'lumotlarini olish
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};
      final userName =
          userData['name'] ?? userData['displayName'] ?? 'Noma\'lum';
      final userEmail = user.email ?? 'Email yo\'q';

      // Tangalarni ayirish
      await coinService.deductCoins(item.cost, 'Shop purchase: ${item.name}');

      // Purchase ma'lumotlarini saqlash
      await _firestore.collection('purchases').add({
        'userId': user.uid,
        'userName': userName,
        'userEmail': userEmail,
        'itemId': item.id,
        'itemName': item.name,
        'itemCategory': item.category,
        'cost': item.cost,
        'description': item.description,
        'imageUrl': item.imageUrl,
        'purchasedAt': FieldValue.serverTimestamp(),
        'status': 'completed',
      });

      // Coin transaction ham saqlash
      await _firestore.collection('coin_transactions').add({
        'userId': user.uid,
        'userName': userName,
        'userEmail': userEmail,
        'amount': -item.cost, // Minus chunki sarflandi
        'type': 'spent',
        'reason': 'Shop purchase: ${item.name}',
        'itemId': item.id,
        'timestamp': FieldValue.serverTimestamp(),
      });

      print('✅ Purchase successful: ${item.name}');
      print('👤 User: $userName ($userEmail)');
      print('💰 Cost: ${item.cost} coins');

      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ Purchase error: $e');
      _error = 'Sotib olishda xatolik: $e';
      notifyListeners();
      return false;
    }
  }

  // Get user purchases
  Future<List<Map<String, dynamic>>> getUserPurchases() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final snapshot = await _firestore
          .collection('purchases')
          .where('userId', isEqualTo: user.uid)
          .orderBy('purchaseDate', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      print('Error fetching purchases: $e');
      return [];
    }
  }
}
