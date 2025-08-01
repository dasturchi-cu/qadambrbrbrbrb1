import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'referral_service.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
  );
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _user != null;

  AuthService() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  // Email va parol bilan ro'yxatdan o'tish
  Future<bool> signUpWithEmail(String email, String password, String username,
      {String? referralCode}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);

      // Username saqlash
      await result.user?.updateDisplayName(username);

      // Profil yangilash uchun reload qilish
      await result.user?.reload();
      _user = _auth.currentUser;

      // User ma'lumotlarini localStorage ga saqlash
      await _saveUserData(result.user);

      // FCM tokenni Firestore'ga saqlash
      if (result.user != null) {
        await saveFcmTokenToFirestore(result.user!.uid);

        // User ni darhol active qilish
        await _markUserAsActive(result.user!.uid);

        // Referral code bo'lsa, referral tizimini ishlatish
        if (referralCode != null && referralCode.isNotEmpty) {
          await _processReferral(result.user!.uid, referralCode);
        }
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;

      if (e.code == 'weak-password') {
        _errorMessage = 'Parol juda oson';
      } else if (e.code == 'email-already-in-use') {
        _errorMessage = 'Bu email allaqachon ro\'yxatdan o\'tkazilgan';
      } else {
        _errorMessage = e.message;
      }

      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Referral code ni qayta ishlash
  Future<void> _processReferral(String newUserId, String referralCode) async {
    try {
      final referralService = ReferralService();

      // Referral code dan foydalanuvchi ID ni olish
      final referrerId =
          await referralService.getUserIdFromReferralCode(referralCode);

      if (referrerId != null) {
        // Referral qo'shish
        final success =
            await referralService.addReferral(referrerId, newUserId);

        if (success) {
          print(
              'Referral muvaffaqiyatli qo\'shildi: $referrerId -> $newUserId');
        } else {
          print('Referral qo\'shishda xatolik: ${referralService.error}');
        }
      }
    } catch (e) {
      print('Referral qayta ishlashda xatolik: $e');
    }
  }

  // Email va parol bilan kirish
  Future<bool> signInWithEmail(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    debugPrint('🔐 AuthService: Attempting login for $email');

    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);

      debugPrint('✅ AuthService: Login successful for ${result.user?.uid}');

      // User ma'lumotlarini localStorage ga saqlash
      await _saveUserData(result.user);
      // FCM tokenni Firestore'ga saqlash
      if (result.user != null) {
        await saveFcmTokenToFirestore(result.user!.uid);

        // User ni darhol active qilish
        await _markUserAsActive(result.user!.uid);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;

      debugPrint(
          '❌ AuthService: Firebase auth error: ${e.code} - ${e.message}');

      if (e.code == 'user-not-found') {
        _errorMessage = 'Bu email bilan ro\'yxatdan o\'tilmagan';
      } else if (e.code == 'wrong-password') {
        _errorMessage = 'Noto\'g\'ri parol kiritildi';
      } else if (e.code == 'invalid-email') {
        _errorMessage = 'Email formati noto\'g\'ri';
      } else if (e.code == 'user-disabled') {
        _errorMessage = 'Bu akkaunt bloklangan';
      } else if (e.code == 'too-many-requests') {
        _errorMessage = 'Juda ko\'p urinish. Keyinroq qayta urinib ko\'ring';
      } else {
        _errorMessage = e.message ?? 'Login xatoligi yuz berdi';
      }

      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Google bilan kirish
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Credential bilan Firebase ga kirish
      UserCredential result = await _auth.signInWithCredential(credential);

      // User ma'lumotlarini localStorage ga saqlash
      if (result.user != null) {
        await _saveUserData(result.user!);
        await saveFcmTokenToFirestore(result.user!.uid);

        // User ni darhol active qilish
        await _markUserAsActive(result.user!.uid);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = "Firebase auth xato: ${e.message}";
      print("Firebase auth error: ${e.code} - ${e.message}");
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      print("Google sign in error: $_errorMessage");
      notifyListeners();
      return false;
    }
  }

  // Chiqish
  Future<void> signOut() async {
    try {
      // Google sign out
      await _googleSignIn.signOut();
      // Firebase sign out
      await _auth.signOut();

      // Local storage dan o'chirish
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_id');
      await prefs.remove('user_email');
      await prefs.remove('user_name');
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Parolni tiklash
  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _auth.sendPasswordResetEmail(email: email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // User ma'lumotlarini localStorage ga saqlash
  Future<void> _saveUserData(User? user) async {
    if (user == null) return;

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', user.uid);
      await prefs.setString('user_name', user.displayName ?? '');
      await prefs.setString('user_email', user.email ?? '');

      // Firestore ga to'liq user ma'lumotlarini saqlash
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'name': user.displayName ?? 'User',
        'photoURL': user.photoURL,
        'lastLogin': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'coins': 0, // Default coins
        'totalSteps': 0, // Default steps
        'todaySteps': 0, // Today's steps
        'isActive': true, // Active user
        'lastSeen': FieldValue.serverTimestamp(),
        'level': 1, // Default level
        'experience': 0, // Default experience
        'achievements': [], // Empty achievements
        'friends': [], // Empty friends list
        'loginStreak': 0, // Login streak
        'lastLoginDate': FieldValue.serverTimestamp(),
        'weeklySteps': 0, // Weekly steps
        'monthlySteps': 0, // Monthly steps
        'realStepsDetected': false, // Real steps detection
      }, SetOptions(merge: true));

      // Active users collection ga ham qo'shish
      await FirebaseFirestore.instance
          .collection('active_users')
          .doc(user.uid)
          .set({
        'uid': user.uid,
        'name': user.displayName ?? 'User',
        'email': user.email,
        'photoURL': user.photoURL,
        'isActive': true,
        'lastSeen': FieldValue.serverTimestamp(),
        'totalSteps': 0,
        'todaySteps': 0,
        'realStepsDetected': false,
        'joinedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('✅ User successfully created in Firestore: ${user.uid}');
    } catch (e) {
      debugPrint('❌ User ma\'lumotlarini saqlashda xatolik: $e');
      _errorMessage = e.toString();
    }
  }

  /// Mark user as active immediately after login
  Future<void> _markUserAsActive(String userId) async {
    try {
      final now = DateTime.now();

      // Update active_users collection
      await FirebaseFirestore.instance
          .collection('active_users')
          .doc(userId)
          .set({
        'uid': userId,
        'userId': userId,
        'isActive': true,
        'lastSeen': now.millisecondsSinceEpoch,
        'lastStepUpdate': now.millisecondsSinceEpoch,
        'currentSteps': 0,
        'realStepsDetected': false,
        'joinedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('✅ User marked as active: $userId');
    } catch (e) {
      debugPrint('❌ Error marking user as active: $e');
    }
  }

  // Username olish
  Future<String> getUsername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("user_name") ?? "";
  }

  // Foydalanuvchi profilini yangilash
  Future<bool> updateProfile(
      {String? name, String? email, String? phone}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      if (name != null && name.isNotEmpty) {
        await user.updateDisplayName(name);
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'name': name});
      }

      if (email != null && email.isNotEmpty && email != user.email) {
        await user.updateEmail(email);
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'email': email});
      }

      if (phone != null && phone.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'phone': phone});
      }

      await user.reload();
      _user = _auth.currentUser;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // FCM token saqlash
  Future<void> saveFcmTokenToFirestore(String userId) async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'fcmToken': fcmToken,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print('FCM token saqlashda xatolik: $e');
    }
  }
}

class AchievementService extends ChangeNotifier {
  List<AchievementModel> _achievements = [];
  bool _isLoading = false;
  String? _error;

  List<AchievementModel> get achievements => _achievements;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchAchievements(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .orderBy('date', descending: true)
          .get();

      _achievements = snapshot.docs
          .map((doc) => AchievementModel.fromMap(doc.data(), doc.id))
          .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> addAchievement(
      String userId, AchievementModel achievement) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .add(achievement.toMap());

      await fetchAchievements(userId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
