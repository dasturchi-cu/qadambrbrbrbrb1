import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/transaction_service.dart';
import '../services/auth_service.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({Key? key}) : super(key: key);

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  bool _fetched = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_fetched) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final transactionService =
              Provider.of<TransactionService>(context, listen: false);
          final user = Provider.of<AuthService>(context, listen: false).user;
          if (user != null) {
            transactionService.fetchTransactions(user.uid);
          }
        }
      });
      _fetched = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactionService = Provider.of<TransactionService>(context);
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Tranzaksiyalar tarixi'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: transactionService.isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Tranzaksiyalar yuklanmoqda...'),
                ],
              ),
            )
          : transactionService.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text('Xatolik: ${transactionService.error}'),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          final user =
                              Provider.of<AuthService>(context, listen: false)
                                  .user;
                          if (user != null) {
                            transactionService.fetchTransactions(user.uid);
                          }
                        },
                        child: Text('Qayta urinish'),
                      ),
                    ],
                  ),
                )
              : transactionService.transactions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long,
                              size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Tranzaksiyalar topilmadi',
                            style: TextStyle(
                                fontSize: 18, color: Colors.grey[600]),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Qadam tashlang va tanga yig\'ing!',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: transactionService.transactions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final t = transactionService.transactions[i];
                        return _buildTransactionCard(t);
                      },
                    ),
    );
  }

  Widget _buildTransactionCard(transaction) {
    final String type = transaction.typeDisplayName;
    final String desc = transaction.description;
    final String date = _formatDate(transaction.timestamp);
    final String time = _formatTime(transaction.timestamp);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: (transaction.isPositive ? Colors.green : Colors.red)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getTransactionIcon(transaction.type),
                color: transaction.isPositive ? Colors.green : Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),

            // Transaction details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  if (desc.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      desc,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time,
                          size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        '$date • $time',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${transaction.amountDisplay}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: transaction.isPositive ? Colors.green : Colors.red,
                  ),
                ),
                Text(
                  'tanga',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (date == today) {
      return 'Bugun';
    } else if (date == yesterday) {
      return 'Kecha';
    } else {
      return '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year}';
    }
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  IconData _getTransactionIcon(transactionType) {
    switch (transactionType.toString()) {
      case 'TransactionType.earned':
        return Icons.directions_walk;
      case 'TransactionType.spent':
        return Icons.shopping_cart;
      case 'TransactionType.reward':
        return Icons.card_giftcard;
      case 'TransactionType.challenge':
        return Icons.emoji_events;
      case 'TransactionType.referral':
        return Icons.people;
      case 'TransactionType.daily':
        return Icons.today;
      case 'TransactionType.achievement':
        return Icons.star;
      case 'TransactionType.shop':
        return Icons.store;
      case 'TransactionType.withdraw':
        return Icons.account_balance_wallet;
      default:
        return Icons.monetization_on;
    }
  }
}
