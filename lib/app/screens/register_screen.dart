import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qadam_app/app/services/auth_service.dart';
import 'package:qadam_app/app/services/referral_service.dart';
import 'package:qadam_app/app/screens/home_screen.dart';
import 'package:qadam_app/app/screens/login_screen.dart';
import 'package:qadam_app/app/components/loading_widget.dart';
import 'package:qadam_app/app/components/error_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  final String? referralCode;

  const RegisterScreen({Key? key, this.referralCode}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _referralCodeController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isValidatingReferral = false;
  bool _isReferralValid = false;

  @override
  void initState() {
    super.initState();
    if (widget.referralCode != null) {
      _referralCodeController.text = widget.referralCode!;
      _validateReferralCode(widget.referralCode!);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    _referralCodeController.dispose();
    super.dispose();
  }

  Future<void> _validateReferralCode(String code) async {
    if (code.isEmpty) {
      setState(() {
        _isValidatingReferral = false;
        _isReferralValid = false;
      });
      return;
    }

    setState(() {
      _isValidatingReferral = true;
    });

    final referralService =
        Provider.of<ReferralService>(context, listen: false);
    final isValid = await referralService.isReferralCodeValid(code);

    setState(() {
      _isValidatingReferral = false;
      _isReferralValid = isValid;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Ro\'yxatdan o\'tish',
          style: TextStyle(color: Theme.of(context).primaryColor),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Username field
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Foydalanuvchi nomi',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Foydalanuvchi nomini kiriting';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),

                // Email field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Emailni kiriting';
                    }
                    if (!value.contains('@')) {
                      return 'To\'g\'ri email kiriting';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),

                // Password field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Parol',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Parolni kiriting';
                    }
                    if (value.length < 6) {
                      return 'Parol kamida 6 ta belgidan iborat bo\'lishi kerak';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),

                // Confirm Password field
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Parolni tasdiqlash',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Parolni tasdiqlang';
                    }
                    if (value != _passwordController.text) {
                      return 'Parollar mos kelmadi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),

                // Referral Code field
                TextFormField(
                  controller: _referralCodeController,
                  decoration: InputDecoration(
                    labelText: 'Referral kod (ixtiyoriy)',
                    prefixIcon: const Icon(Icons.card_giftcard),
                    suffixIcon: _isValidatingReferral
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : _referralCodeController.text.isNotEmpty
                            ? Icon(
                                _isReferralValid
                                    ? Icons.check_circle
                                    : Icons.error,
                                color: _isReferralValid
                                    ? Colors.green
                                    : Colors.red,
                              )
                            : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    hintText: 'QADAM12345678',
                  ),
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      _validateReferralCode(value);
                    } else {
                      setState(() {
                        _isReferralValid = false;
                      });
                    }
                  },
                ),
                if (_referralCodeController.text.isNotEmpty &&
                    !_isValidatingReferral)
                  Padding(
                    padding: const EdgeInsets.only(top: 5, left: 12),
                    child: Text(
                      _isReferralValid
                          ? '✅ To\'g\'ri referral kod! +50 tanga bonus olasiz'
                          : '❌ Noto\'g\'ri referral kod',
                      style: TextStyle(
                        color: _isReferralValid ? Colors.green : Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(height: 25),

                // Register button
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: authService.isLoading
                        ? null
                        : () async {
                            if (_formKey.currentState!.validate()) {
                              final success = await authService.signUpWithEmail(
                                _emailController.text.trim(),
                                _passwordController.text.trim(),
                                _usernameController.text.trim(),
                                referralCode:
                                    _referralCodeController.text.trim(),
                              );
                              if (success && mounted) {
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (_) => const HomeScreen(),
                                  ),
                                  (route) => false,
                                );
                              }
                            }
                          },
                    child: authService.isLoading
                        ? const LoadingWidget(
                            message: "Ro'yxatdan o'tilmoqda...")
                        : const Text(
                            "Ro'yxatdan o'tish",
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                if (authService.errorMessage != null)
                  AppErrorWidget(
                    message: authService.errorMessage!,
                  ),
                const SizedBox(height: 30),

                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Allaqachon hisobingiz bormi?'),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      child: const Text('Kirish'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class InviteModel {
  final String id;
  final String inviterId;
  final String invitedEmail;
  final String status;
  final DateTime date;

  InviteModel({
    required this.id,
    required this.inviterId,
    required this.invitedEmail,
    required this.status,
    required this.date,
  });

  factory InviteModel.fromMap(Map<String, dynamic> map, String id) {
    return InviteModel(
      id: id,
      inviterId: map['inviterId'] ?? '',
      invitedEmail: map['invitedEmail'] ?? '',
      status: map['status'] ?? 'pending',
      date: (map['date'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'inviterId': inviterId,
      'invitedEmail': invitedEmail,
      'status': status,
      'date': date,
    };
  }
}

Future<void> sendChallengeInvite({
  required String fromUserId,
  required String toUserId,
  required String challengeId,
}) async {
  await FirebaseFirestore.instance.collection('challenge_invites').add({
    'fromUserId': fromUserId,
    'toUserId': toUserId,
    'challengeId': challengeId,
    'status': 'pending',
    'date': FieldValue.serverTimestamp(),
  });
}
