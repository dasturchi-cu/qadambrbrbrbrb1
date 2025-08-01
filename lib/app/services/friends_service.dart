import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Friend {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final int level;
  final int totalSteps;
  final int dailyStreak;
  final String levelTitle;
  final DateTime lastActive;
  final bool isOnline;

  Friend({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.level,
    required this.totalSteps,
    required this.dailyStreak,
    required this.levelTitle,
    required this.lastActive,
    required this.isOnline,
  });

  factory Friend.fromMap(Map<String, dynamic> map, String id) {
    return Friend(
      id: id,
      name: map['name'] ?? 'Noma\'lum',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'],
      level: map['level'] ?? 1,
      totalSteps: map['totalSteps'] ?? 0,
      dailyStreak: map['dailyStreak'] ?? 0,
      levelTitle: map['levelTitle'] ?? 'Yangi Boshlovchi',
      lastActive: (map['lastActive'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isOnline: map['isOnline'] ?? false,
    );
  }
}

class FriendRequest {
  final String id;
  final String fromUserId;
  final String fromUserName;
  final String fromUserEmail;
  final String? fromUserPhoto;
  final String toUserId;
  final DateTime sentAt;
  final String status; // 'pending', 'accepted', 'rejected'

  FriendRequest({
    required this.id,
    required this.fromUserId,
    required this.fromUserName,
    required this.fromUserEmail,
    this.fromUserPhoto,
    required this.toUserId,
    required this.sentAt,
    required this.status,
  });

  factory FriendRequest.fromMap(Map<String, dynamic> map, String id) {
    return FriendRequest(
      id: id,
      fromUserId: map['fromUserId'] ?? '',
      fromUserName: map['fromUserName'] ?? 'Noma\'lum',
      fromUserEmail: map['fromUserEmail'] ?? '',
      fromUserPhoto: map['fromUserPhoto'],
      toUserId: map['toUserId'] ?? '',
      sentAt: (map['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: map['status'] ?? 'pending',
    );
  }
}

class FriendsService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Friend> _friends = [];
  List<FriendRequest> _friendRequests = [];
  bool _isLoading = false;
  String? _error;

  List<Friend> get friends => _friends;
  List<FriendRequest> get friendRequests => _friendRequests;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get friendsCount => _friends.length;

  Future<void> initialize() async {
    await loadFriends();
    await loadFriendRequests();
  }

  // Do'stlarni yuklash
  Future<void> loadFriends() async {
    final user = _auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Foydalanuvchining do'stlar ro'yxatini olish
      final friendsDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('friends')
          .get();

      List<Friend> loadedFriends = [];

      for (final doc in friendsDoc.docs) {
        final friendId = doc.data()['friendId'];
        
        // Do'st ma'lumotlarini olish
        final friendDoc = await _firestore
            .collection('users')
            .doc(friendId)
            .get();

        if (friendDoc.exists) {
          loadedFriends.add(Friend.fromMap(friendDoc.data()!, friendId));
        }
      }

      _friends = loadedFriends;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Do'stlik so'rovlarini yuklash
  Future<void> loadFriendRequests() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final requestsSnapshot = await _firestore
          .collection('friend_requests')
          .where('toUserId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'pending')
          .orderBy('sentAt', descending: true)
          .get();

      _friendRequests = requestsSnapshot.docs
          .map((doc) => FriendRequest.fromMap(doc.data(), doc.id))
          .toList();

      notifyListeners();
    } catch (e) {
      debugPrint('Friend requests yuklashda xatolik: $e');
    }
  }

  // Email bo'yicha foydalanuvchi qidirish
  Future<List<Map<String, dynamic>>> searchUsersByEmail(String email) async {
    if (email.isEmpty) return [];

    try {
      final usersSnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase())
          .limit(10)
          .get();

      final currentUser = _auth.currentUser;
      List<Map<String, dynamic>> users = [];

      for (final doc in usersSnapshot.docs) {
        if (doc.id != currentUser?.uid) {
          final userData = doc.data();
          userData['id'] = doc.id;
          
          // Allaqachon do'st emasligini tekshirish
          final isFriend = _friends.any((friend) => friend.id == doc.id);
          userData['isFriend'] = isFriend;
          
          // So'rov yuborilganligini tekshirish
          final hasPendingRequest = await _checkPendingRequest(doc.id);
          userData['hasPendingRequest'] = hasPendingRequest;
          
          users.add(userData);
        }
      }

      return users;
    } catch (e) {
      debugPrint('Foydalanuvchi qidirishda xatolik: $e');
      return [];
    }
  }

  // Do'stlik so'rovi yuborish
  Future<bool> sendFriendRequest(String toUserId, String toUserName, String toUserEmail) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      // Allaqachon so'rov yuborilganligini tekshirish
      final existingRequest = await _firestore
          .collection('friend_requests')
          .where('fromUserId', isEqualTo: user.uid)
          .where('toUserId', isEqualTo: toUserId)
          .where('status', isEqualTo: 'pending')
          .get();

      if (existingRequest.docs.isNotEmpty) {
        _error = 'Allaqachon so\'rov yuborilgan';
        notifyListeners();
        return false;
      }

      // Yangi so'rov yaratish
      await _firestore.collection('friend_requests').add({
        'fromUserId': user.uid,
        'fromUserName': user.displayName ?? 'Noma\'lum',
        'fromUserEmail': user.email ?? '',
        'fromUserPhoto': user.photoURL,
        'toUserId': toUserId,
        'toUserName': toUserName,
        'toUserEmail': toUserEmail,
        'sentAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Do'stlik so'rovini qabul qilish
  Future<bool> acceptFriendRequest(String requestId, String fromUserId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      // So'rov holatini yangilash
      await _firestore
          .collection('friend_requests')
          .doc(requestId)
          .update({'status': 'accepted'});

      // Ikkala foydalanuvchiga ham do'st qo'shish
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('friends')
          .add({
        'friendId': fromUserId,
        'addedAt': FieldValue.serverTimestamp(),
      });

      await _firestore
          .collection('users')
          .doc(fromUserId)
          .collection('friends')
          .add({
        'friendId': user.uid,
        'addedAt': FieldValue.serverTimestamp(),
      });

      // Ro'yxatlarni yangilash
      await loadFriends();
      await loadFriendRequests();

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Do'stlik so'rovini rad etish
  Future<bool> rejectFriendRequest(String requestId) async {
    try {
      await _firestore
          .collection('friend_requests')
          .doc(requestId)
          .update({'status': 'rejected'});

      await loadFriendRequests();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Do'stni o'chirish
  Future<bool> removeFriend(String friendId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      // Ikkala tomondan ham o'chirish
      final userFriendsQuery = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('friends')
          .where('friendId', isEqualTo: friendId)
          .get();

      for (final doc in userFriendsQuery.docs) {
        await doc.reference.delete();
      }

      final friendFriendsQuery = await _firestore
          .collection('users')
          .doc(friendId)
          .collection('friends')
          .where('friendId', isEqualTo: user.uid)
          .get();

      for (final doc in friendFriendsQuery.docs) {
        await doc.reference.delete();
      }

      await loadFriends();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Pending request tekshirish
  Future<bool> _checkPendingRequest(String userId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final requestSnapshot = await _firestore
          .collection('friend_requests')
          .where('fromUserId', isEqualTo: user.uid)
          .where('toUserId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();

      return requestSnapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Do'stlar reytingi
  List<Friend> getFriendsRanking() {
    final sortedFriends = List<Friend>.from(_friends);
    sortedFriends.sort((a, b) {
      // Avval level bo'yicha, keyin total steps bo'yicha
      if (a.level != b.level) {
        return b.level.compareTo(a.level);
      }
      return b.totalSteps.compareTo(a.totalSteps);
    });
    return sortedFriends;
  }

  // Online do'stlar
  List<Friend> getOnlineFriends() {
    return _friends.where((friend) => friend.isOnline).toList();
  }

  // Faol do'stlar (oxirgi 24 soatda)
  List<Friend> getActiveFriends() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return _friends.where((friend) => friend.lastActive.isAfter(yesterday)).toList();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
