import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/shop_service.dart';
import '../services/coin_service.dart';

class ShopScreen extends StatefulWidget {
  @override
  _ShopScreenState createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  late ScaffoldMessengerState _scaffoldMessenger;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scaffoldMessenger = ScaffoldMessenger.of(context);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<ShopService>(context, listen: false).fetchShopItems();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Do\'kon'),
        backgroundColor: Colors.blue,
        actions: [
          Consumer<CoinService>(
            builder: (context, coinService, child) {
              return Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.monetization_on, color: Colors.yellow),
                    SizedBox(width: 4),
                    Text(
                      '${coinService.coins}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<ShopService>(
        builder: (context, shopService, child) {
          if (shopService.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          if (shopService.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Xatolik: ${shopService.error}'),
                  ElevatedButton(
                    onPressed: () => shopService.fetchShopItems(),
                    child: Text('Qayta urinish'),
                  ),
                ],
              ),
            );
          }

          if (shopService.items.isEmpty) {
            return Center(
              child: Text('Hozircha mahsulotlar yo\'q'),
            );
          }

          return GridView.builder(
            padding: EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.65, // Bu qiymatni kichikroq qiling
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: shopService.items.length,
            itemBuilder: (context, index) {
              final item = shopService.items[index];
              return _buildShopItem(context, item);
            },
          );
        },
      ),
    );
  }

  Widget _buildShopItem(BuildContext context, ShopItem item) {
    return Consumer<CoinService>(
      builder: (context, coinService, child) {
        final canAfford = coinService.coins >= item.cost;

        return Card(
          elevation: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                  child: Image.network(
                    item.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: Icon(Icons.image_not_supported),
                      );
                    },
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.monetization_on,
                              color: Colors.yellow, size: 14),
                          SizedBox(width: 2),
                          Text(
                            '${item.cost}',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      Spacer(),
                      SizedBox(
                        width: double.infinity,
                        height: 28,
                        child: ElevatedButton(
                          onPressed:
                              canAfford ? () => _purchaseItem(item) : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                canAfford ? Colors.blue : Colors.grey,
                            padding: EdgeInsets.symmetric(vertical: 2),
                          ),
                          child: Text(
                            canAfford ? 'Sotib olish' : 'Yetarli emas',
                            style: TextStyle(fontSize: 9),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _purchaseItem(ShopItem item) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sotib olish'),
        content: Text('${item.name} ni ${item.cost} tangaga sotib olasizmi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Bekor qilish'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              if (!mounted) return;

              final shopService =
                  Provider.of<ShopService>(context, listen: false);
              final coinService =
                  Provider.of<CoinService>(context, listen: false);

              final success = await shopService.purchaseItem(item, coinService);

              if (!mounted) return;

              if (success) {
                await coinService.initialize();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text('${item.name} muvaffaqiyatli sotib olindi!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(shopService.error ?? 'Xatolik yuz berdi'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text('Sotib olish'),
          ),
        ],
      ),
    );
  }

  // Sotib olish funksiyasi
  Future<void> _purchaseAirPods() async {
    if (!mounted) return;

    final coinService = Provider.of<CoinService>(context, listen: false);
    const airPodsPrice = 10;

    if (coinService.coins < airPodsPrice) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Yetarli tanga yo\'q! Kerak: $airPodsPrice, Mavjud: ${coinService.coins}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('AirPods sotib olish'),
        content: Text('AirPods ni $airPodsPrice tanga evaziga sotib olasizmi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Yo\'q'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Ha, sotib olaman'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success =
          await coinService.deductCoins(airPodsPrice, 'AirPods sotib olish');

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎧 AirPods muvaffaqiyatli sotib olindi!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Xatolik yuz berdi. Qayta urinib ko\'ring.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
