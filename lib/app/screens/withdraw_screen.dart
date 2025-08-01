import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/withdraw_service.dart';
import '../services/coin_service.dart';

class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({Key? key}) : super(key: key);

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _phoneController = TextEditingController();

  String _selectedMethod = 'card';
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _cardNumberController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coinService = Provider.of<CoinService>(context);
    final withdrawService = Provider.of<WithdrawService>(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Pul yechish'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Balance Card
              _buildBalanceCard(coinService.coins),
              const SizedBox(height: 24),

              // Amount Input
              _buildAmountInput(),
              const SizedBox(height: 24),

              // Payment Method Selection
              _buildPaymentMethodSelection(),
              const SizedBox(height: 24),

              // Payment Details
              _buildPaymentDetails(),
              const SizedBox(height: 32),

              // Withdraw Button
              _buildWithdrawButton(withdrawService, coinService),
              const SizedBox(height: 24),

              // Withdraw History
              _buildWithdrawHistory(withdrawService),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(int coins) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.blue, Colors.blueAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.account_balance_wallet,
            color: Colors.white,
            size: 48,
          ),
          const SizedBox(height: 12),
          const Text(
            'Mavjud balans',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$coins tanga',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '≈ ${(coins * 0.01).toStringAsFixed(2)} so\'m',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Yechish miqdori',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Tanga miqdorini kiriting',
            prefixIcon: const Icon(Icons.monetization_on),
            suffixText: 'tanga',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Miqdorni kiriting';
            }
            final amount = int.tryParse(value);
            if (amount == null || amount <= 0) {
              return 'To\'g\'ri miqdor kiriting';
            }
            if (amount < 1000) {
              return 'Minimal miqdor 1000 tanga';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPaymentMethodSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'To\'lov usuli',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMethodCard(
                'card',
                'Bank karta',
                Icons.credit_card,
                _selectedMethod == 'card',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMethodCard(
                'phone',
                'Telefon raqam',
                Icons.phone_android,
                _selectedMethod == 'phone',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMethodCard(
      String method, String title, IconData icon, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = method),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withValues(alpha: 0.1) : Colors.white,
          border: Border.all(
            color:
                isSelected ? Colors.blue : Colors.grey.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.blue : Colors.grey,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.blue : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _selectedMethod == 'card' ? 'Karta ma\'lumotlari' : 'Telefon raqam',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        if (_selectedMethod == 'card') ...[
          TextFormField(
            controller: _cardNumberController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: '8600 1234 5678 9012',
              prefixIcon: const Icon(Icons.credit_card),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Karta raqamini kiriting';
              }
              if (value.length < 16) {
                return 'To\'liq karta raqamini kiriting';
              }
              return null;
            },
          ),
        ] else ...[
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: '+998 90 123 45 67',
              prefixIcon: const Icon(Icons.phone),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Telefon raqamini kiriting';
              }
              return null;
            },
          ),
        ],
      ],
    );
  }

  Widget _buildWithdrawButton(
      WithdrawService withdrawService, CoinService coinService) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading
            ? null
            : () => _handleWithdraw(withdrawService, coinService),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'Pul yechish',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildWithdrawHistory(WithdrawService withdrawService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'So\'nggi so\'rovlar',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          child: const Text(
            'Hozircha so\'rovlar yo\'q',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Future<void> _handleWithdraw(
      WithdrawService withdrawService, CoinService coinService) async {
    if (!_formKey.currentState!.validate()) return;

    final amount = int.parse(_amountController.text);
    if (amount > coinService.coins) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yetarli balans yo\'q')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final success = await withdrawService.requestWithdraw(
      amount: amount,
      method: _selectedMethod,
      cardNumber: _cardNumberController.text,
      phoneNumber: _phoneController.text,
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('So\'rov muvaffaqiyatli yuborildi!')),
      );
      _amountController.clear();
      _cardNumberController.clear();
      _phoneController.clear();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(withdrawService.error ?? 'Xatolik yuz berdi')),
      );
    }
  }
}
