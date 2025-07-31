// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/referral_service.dart';
import '../services/auth_service.dart';
import 'package:qadam_app/app/components/loading_widget.dart';
import 'package:qadam_app/app/components/error_widget.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:qadam_app/app/screens/register_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({Key? key}) : super(key: key);

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  Map<String, dynamic> _stats = {};
  bool _isLoadingStats = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final user = Provider.of<AuthService>(context, listen: false).user;
    if (user != null) {
      await Provider.of<ReferralService>(context, listen: false)
          .fetchReferrals(user.uid);
      await _loadStats(user.uid);
    }
  }

  Future<void> _loadStats(String userId) async {
    setState(() {
      _isLoadingStats = true;
    });

    final stats = await Provider.of<ReferralService>(context, listen: false)
        .getReferralStats(userId);

    setState(() {
      _stats = stats;
      _isLoadingStats = false;
    });
  }

  Future<void> _shareReferral() async {
    final user = Provider.of<AuthService>(context, listen: false).user;
    if (user == null) return;

    final referralCode = Provider.of<ReferralService>(context, listen: false)
        .getReferralCode(user.uid);
    // Always generate a dynamic link
    String referralLink;
    try {
      referralLink = await createReferralDynamicLink(user.uid);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dynamic link yaratishda xatolik: $e')),
      );
      return;
    }

    final shareText = '''
🎉 Qadam++ ilovasini yuklab oling!

Do'stlaringizni taklif qiling va har bir do'stingiz uchun 200 tanga oling!

📱 Referral kodingiz: $referralCode
🔗 Havola: $referralLink

Yangi foydalanuvchilar ham 50 tanga bonus oladi!
''';

    try {
      await Share.share(shareText,
          subject: 'Qadam++ - Do\'stlaringizni taklif qiling!');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ulashishda xatolik: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final referralService = Provider.of<ReferralService>(context);
    final user = authService.user;
    final referralCode =
        user != null ? referralService.getReferralCode(user.uid) : '';
    final referralLink =
        user != null ? 'https://qadam.app/ref/${user.uid}' : '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Do\'stlarni taklif qilish'),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('Foydalanuvchi maʼlumotlari topilmadi.'))
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Referral banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).primaryColor,
                            Theme.of(context).primaryColor.withOpacity(0.8),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.people,
                              color: Colors.white,
                              size: 50,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Do\'stlaringizni taklif qiling',
                            style: Theme.of(context)
                                .textTheme
                                .displayMedium
                                ?.copyWith(
                                  color: Colors.white,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Har bir do\'stingiz uchun 200 tanga oling',
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Colors.white,
                                    ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    // Statistics section
                    if (!_isLoadingStats) ...[
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Jami takliflar',
                                '${_stats['totalReferrals'] ?? 0}',
                                Icons.people,
                                Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildStatCard(
                                'Jami tanga',
                                '${_stats['totalReward'] ?? 0}',
                                Icons.monetization_on,
                                Colors.green,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildStatCard(
                                'Bu oy',
                                '${_stats['thisMonth'] ?? 0}',
                                Icons.calendar_today,
                                Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Referral code section
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Referral kodingiz',
                              style: Theme.of(context)
                                  .textTheme
                                  .displayMedium
                                  ?.copyWith(fontSize: 18),
                            ),
                            const SizedBox(height: 15),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 15, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: Theme.of(context)
                                        .primaryColor
                                        .withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      referralCode,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        letterSpacing: 1.2,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.copy,
                                        color: Colors.green),
                                    onPressed: () {
                                      Clipboard.setData(
                                          ClipboardData(text: referralCode));
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content:
                                              Text('Referral kod nusxalandi'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Referral havola',
                              style: Theme.of(context)
                                  .textTheme
                                  .displayMedium
                                  ?.copyWith(fontSize: 18),
                            ),
                            const SizedBox(height: 15),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 15, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: Theme.of(context)
                                        .primaryColor
                                        .withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      referralLink,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.copy,
                                        color: Colors.green),
                                    onPressed: () {
                                      Clipboard.setData(
                                          ClipboardData(text: referralLink));
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Referral havola nusxalandi'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 25),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.share),
                                label: const Text('Ulashish'),
                                onPressed: _shareReferral,
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 15),
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Referral list section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          Text(
                            'Siz taklif qilgan do\'stlar',
                            style: Theme.of(context)
                                .textTheme
                                .displayMedium
                                ?.copyWith(fontSize: 18),
                          ),
                          const SizedBox(height: 10),
                          referralService.isLoading
                              ? const LoadingWidget(
                                  message: 'Do\'stlar yuklanmoqda...')
                              : referralService.error != null
                                  ? AppErrorWidget(
                                      message: referralService.error ??
                                          'Noma\'lum xatolik',
                                      onRetry: () =>
                                          referralService.fetchReferrals(
                                              Provider.of<AuthService>(context,
                                                          listen: false)
                                                      .user
                                                      ?.uid ??
                                                  ''),
                                    )
                                  : referralService.referrals.isEmpty
                                      ? Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Column(
                                            children: [
                                              Icon(
                                                Icons.people_outline,
                                                size: 50,
                                                color: Colors.grey[600],
                                              ),
                                              const SizedBox(height: 10),
                                              Text(
                                                'Hali do\'stlar taklif qilinmagan',
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(height: 5),
                                              Text(
                                                'Do\'stlaringizni taklif qiling va tanga oling!',
                                                style: TextStyle(
                                                  color: Colors.grey[500],
                                                  fontSize: 14,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        )
                                      : ListView.separated(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          itemCount:
                                              referralService.referrals.length,
                                          separatorBuilder: (_, __) =>
                                              const Divider(),
                                          itemBuilder: (context, index) {
                                            final ref = referralService
                                                .referrals[index];
                                            return ListTile(
                                              leading: CircleAvatar(
                                                backgroundColor:
                                                    Theme.of(context)
                                                        .primaryColor,
                                                child: const Icon(Icons.person,
                                                    color: Colors.white),
                                              ),
                                              title: Text(
                                                ref.referredUserName ??
                                                    'Noma\'lum foydalanuvchi',
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              subtitle: Text(
                                                'Sana: ${ref.date.toLocal().toString().split(' ')[0]}',
                                                style: TextStyle(
                                                    color: Colors.grey[600]),
                                              ),
                                              trailing: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.green,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: const Text(
                                                  '+200',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

Future<String> createReferralDynamicLink(String userId) async {
  final DynamicLinkParameters parameters = DynamicLinkParameters(
    uriPrefix: 'https://qadamapp.page.link', // Firebase'da sozlagan prefix
    link: Uri.parse('https://qadam.app/ref/$userId'),
    androidParameters: const AndroidParameters(
      packageName: 'com.example.qadam_app', // o'z package name'ingiz
      minimumVersion: 1,
    ),
    iosParameters: const IOSParameters(
      bundleId: 'com.example.qadamApp', // o'z bundle id'ingiz
      minimumVersion: '1.0.0',
    ),
  );
  final ShortDynamicLink shortLink =
      await FirebaseDynamicLinks.instance.buildShortLink(parameters);
  return shortLink.shortUrl.toString();
}

void initDynamicLinks(BuildContext context) {
  FirebaseDynamicLinks.instance.onLink.listen((PendingDynamicLinkData? data) {
    final Uri? deepLink = data?.link;
    if (deepLink != null && deepLink.pathSegments.contains('ref')) {
      final referralCode = deepLink.pathSegments.last;
      // RegisterScreen'ga referralCode uzating
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RegisterScreen(referralCode: referralCode),
          ));
    }
  });
}

Future<void> _saveUserData(User? user) async {
  if (user != null) {
    await FirebaseFirestore.instance.collection("users").doc(user.uid).set({
      'uid': user.uid,
      'email': user.email,
      'name': user.displayName,
      'created_at': FieldValue.serverTimestamp(),
      'coins': 0,
      'totalReferrals': 0,
      'phone': user.phoneNumber
    }, SetOptions(merge: true));
  }
}
