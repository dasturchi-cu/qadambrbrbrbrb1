import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qadam_app/app/services/auth_service.dart';
import 'package:qadam_app/app/services/coin_service.dart';
import 'package:qadam_app/app/screens/transaction_history_screen.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:qadam_app/app/screens/shop_screen.dart';
import 'package:qadam_app/app/services/withdraw_service.dart';

class CoinWalletScreen extends StatefulWidget {
  const CoinWalletScreen({Key? key}) : super(key: key);

  @override
  State<CoinWalletScreen> createState() => _CoinWalletScreenState();
}

class _CoinWalletScreenState extends State<CoinWalletScreen> {
  final TextEditingController _amountController = TextEditingController();
  RewardedAd? _rewardedAd;
  bool _isRewardedAdLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coinService = Provider.of<CoinService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tanga hamyoni'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Coin balance card
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFC107), Color(0xFFFFD54F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFC107).withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Joriy balans',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.monetization_on,
                        color: Colors.white,
                        size: 40,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${coinService.coins}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    '≈ 0 so\'m',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Actions
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tanga amaliyotlari',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontSize: 18,
                        ),
                  ),
                  const SizedBox(height: 20),
                  _buildActionCard(
                    context,
                    icon: Icons.shopping_cart,
                    title: 'Tangalarni sarflash',
                    description: 'Do\'konda mahsulot va xizmatlar sotib olish',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ShopScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 15),
                  _buildActionCard(
                    context,
                    icon: Icons.account_balance_wallet,
                    title: 'Pulga yechib olish',
                    description: 'Tangalarni so\'mga ayirboshlash',
                    onTap: () {
                      _showWithdrawDialog(context, coinService);
                    },
                  ),
                  const SizedBox(height: 15),
                  _buildActionCard(
                    context,
                    icon: Icons.history,
                    title: 'Tranzaksiya tarixi',
                    description: 'Barcha tanga operatsiyalari',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const TransactionHistoryScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Bonus actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon:
                          const Icon(Icons.ondemand_video, color: Colors.white),
                      label: const Text('Reklama ko‘r, bonus ol'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                      ),
                      onPressed: () async {
                        _loadRewardedAd(context);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.star, color: Colors.amber),
                      label: const Text('Premium'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.amber[800],
                        side: BorderSide(color: Colors.amber[800]!, width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Premium'),
                            content:
                                const Text('Premium funksiyasi tez orada!'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Yopish'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Coin info section
            Container(
              margin: const EdgeInsets.all(20),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tanga ma\'lumotlari',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontSize: 18,
                        ),
                  ),
                  const SizedBox(height: 15),
                  _buildInfoRow(
                      'Bugun yig\'ilgan', '${coinService.todayEarned} tanga'),
                  _buildInfoRow(
                      'Kunlik limit', '${coinService.dailyCoinLimit} tanga'),
                  _buildInfoRow('Qadam/tanga nisbati',
                      '${coinService.stepsPerCoin} qadam = 1 tanga'),
                  _buildInfoRow('Tanga qiymati', '1 tanga ≈ 10 so\'m'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _showWithdrawDialog(BuildContext context, CoinService coinService) {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController cardController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();
    String selectedMethod = 'click';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Tangalarni yechish'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Joriy balans: ${coinService.coins} tanga'),
                SizedBox(height: 16),

                // To'lov usuli
                DropdownButtonFormField<String>(
                  value: selectedMethod,
                  decoration: InputDecoration(
                    labelText: 'To\'lov usuli',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(value: 'click', child: Text('Click')),
                    DropdownMenuItem(value: 'payme', child: Text('Payme')),
                    DropdownMenuItem(value: 'uzcard', child: Text('UzCard')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedMethod = value!;
                    });
                  },
                ),
                SizedBox(height: 12),

                // Miqdor
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Miqdor (minimal: 1000)',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),

                // Karta raqami
                TextField(
                  controller: cardController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Karta raqami',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),

                // Telefon
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Telefon raqami',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 8),

                Text(
                  'To\'lov kartasi yoki telefon raqamini kiriting',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Bekor qilish'),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount = int.tryParse(amountController.text) ?? 0;

                if (amount < 1000) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Minimal miqdor 1000 tanga')),
                  );
                  return;
                }

                if (cardController.text.isEmpty &&
                    phoneController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Karta yoki telefon raqamini kiriting')),
                  );
                  return;
                }

                Navigator.pop(context);

                final withdrawService =
                    Provider.of<WithdrawService>(context, listen: false);
                final success = await withdrawService.requestWithdraw(
                  amount: amount,
                  method: selectedMethod,
                  cardNumber: cardController.text,
                  phoneNumber: phoneController.text,
                );

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Yechish so\'rovi yuborildi!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  coinService.initialize(); // Balansni yangilash
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(withdrawService.error ??
                          'Pul yechishda xatolik yuz berdi'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text('Yuborish'),
            ),
          ],
        ),
      ),
    );
  }

  void _loadRewardedAd(BuildContext context) {
    RewardedAd.load(
      adUnitId: 'ca-app-pub-7180097986291909/1830667352',
      request: AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _showRewardedAd(context);
        },
        onAdFailedToLoad: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Reklama yuklanmadi')),
          );
        },
      ),
    );
  }

  void _showRewardedAd(BuildContext context) {
    if (_rewardedAd == null) return;
    final coinService = Provider.of<CoinService>(context, listen: false);
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
      },
    );
    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) async {
        await coinService.addCoins(15);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tabriklaymiz! +15 tanga oldingiz!')),
        );
      },
    );
    _rewardedAd = null;
  }
}
