import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/connectivity_service.dart';
import '../services/sync_service.dart';
import '../services/offline_game_service.dart';
import '../screens/offline_game_screen.dart';
import '../screens/dinosaur_game_screen.dart';

class ConnectionStatusWidget extends StatelessWidget {
  final bool showDetails;
  final bool showSyncStatus;

  const ConnectionStatusWidget({
    Key? key,
    this.showDetails = false,
    this.showSyncStatus = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer2<ConnectivityService, SyncService>(
      builder: (context, connectivityService, syncService, child) {
        if (connectivityService.isOnline && !syncService.hasPendingSync) {
          return const SizedBox
              .shrink(); // Online va sync bo'lsa, hech narsa ko'rsatmaslik
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _getStatusColor(connectivityService, syncService),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                Icon(
                  _getStatusIcon(connectivityService, syncService),
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getStatusTitle(connectivityService, syncService),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      if (showDetails) ...[
                        const SizedBox(height: 2),
                        Text(
                          _getStatusSubtitle(connectivityService, syncService),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (connectivityService.isOffline) ...[
                  Consumer<OfflineGameService>(
                    builder: (context, gameService, child) {
                      return PopupMenuButton<GameType>(
                        onSelected: (GameType game) {
                          gameService.setPreferredGame(game);
                          _navigateToGame(context, game);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.games, color: Colors.white, size: 16),
                              SizedBox(width: 4),
                              Text('O\'yin',
                                  style: TextStyle(color: Colors.white)),
                              Icon(Icons.arrow_drop_down,
                                  color: Colors.white, size: 16),
                            ],
                          ),
                        ),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: GameType.dinosaur,
                            child: Row(
                              children: [
                                Icon(GameType.dinosaur.icon),
                                const SizedBox(width: 8),
                                Text(GameType.dinosaur.name),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: GameType.bubble,
                            child: Row(
                              children: [
                                Icon(GameType.bubble.icon),
                                const SizedBox(width: 8),
                                Text(GameType.bubble.name),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  TextButton(
                    onPressed: () =>
                        _showOfflineDialog(context, connectivityService),
                    child: const Text(
                      'Batafsil',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
                if (syncService.hasPendingSync && connectivityService.isOnline)
                  TextButton(
                    onPressed: () => syncService.forcSync(),
                    child: const Text(
                      'Sync',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(ConnectivityService connectivity, SyncService sync) {
    if (connectivity.isOffline) {
      return Colors.red;
    } else if (sync.isSyncing) {
      return Colors.orange;
    } else if (sync.hasPendingSync) {
      return Colors.amber;
    } else {
      return Colors.green;
    }
  }

  IconData _getStatusIcon(ConnectivityService connectivity, SyncService sync) {
    if (connectivity.isOffline) {
      return Icons.wifi_off;
    } else if (sync.isSyncing) {
      return Icons.sync;
    } else if (sync.hasPendingSync) {
      return Icons.sync_problem;
    } else {
      return Icons.wifi;
    }
  }

  String _getStatusTitle(ConnectivityService connectivity, SyncService sync) {
    if (connectivity.isOffline) {
      return 'Internet aloqasi yo\'q';
    } else if (sync.isSyncing) {
      return 'Sinxronlashtirilmoqda...';
    } else if (sync.hasPendingSync) {
      return '${sync.pendingSyncItems} ta element kutilmoqda';
    } else {
      return 'Onlayn';
    }
  }

  String _getStatusSubtitle(
      ConnectivityService connectivity, SyncService sync) {
    if (connectivity.isOffline) {
      return 'Oflayn rejimda ishlayapti • ${connectivity.getOfflineDurationString()}';
    } else if (sync.isSyncing) {
      return 'Ma\'lumotlar sinxronlashtirilmoqda';
    } else if (sync.hasPendingSync) {
      return 'Sinxronlashtirish uchun bosing';
    } else {
      return '${connectivity.getConnectionTypeString()} • ${sync.getLastSyncTimeString()}';
    }
  }

  void _navigateToGame(BuildContext context, GameType gameType) {
    Widget gameScreen;

    switch (gameType) {
      case GameType.dinosaur:
        gameScreen = const DinosaurGameScreen();
        break;
      case GameType.bubble:
        gameScreen = const OfflineGameScreen();
        break;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => gameScreen,
        fullscreenDialog: true,
      ),
    );
  }

  void _showOfflineDialog(
      BuildContext context, ConnectivityService connectivity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.red),
            SizedBox(width: 8),
            Text('Internet aloqasi yo\'q'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Holat: ${connectivity.getConnectionStatusString()}'),
            const SizedBox(height: 8),
            Text('Oflayn vaqt: ${connectivity.getOfflineDurationString()}'),
            const SizedBox(height: 8),
            if (connectivity.lastOnlineTime != null)
              Text(
                  'Oxirgi onlayn: ${_formatDateTime(connectivity.lastOnlineTime!)}'),
            const SizedBox(height: 16),
            const Text(
              'Oflayn rejimda ham ishlay olasiz. Internet qaytganda barcha ma\'lumotlar avtomatik sinxronlashtiriladi.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Yopish'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              connectivity.checkConnection();
            },
            child: const Text('Qayta tekshirish'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Hozirgina';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} daqiqa oldin';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} soat oldin';
    } else {
      return '${dateTime.day}.${dateTime.month}.${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}

// Floating connection status
class FloatingConnectionStatus extends StatelessWidget {
  const FloatingConnectionStatus({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityService>(
      builder: (context, connectivity, child) {
        if (connectivity.isOnline) {
          return const SizedBox.shrink();
        }

        return Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 16,
          right: 16,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.wifi_off, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Internet aloqasi yo\'q - Oflayn rejimda',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const OfflineGameScreen()),
                    ),
                    child: const Text(
                      'O\'yin',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  TextButton(
                    onPressed: () => connectivity.checkConnection(),
                    child: const Text(
                      'Tekshirish',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Sync status indicator
class SyncStatusIndicator extends StatelessWidget {
  const SyncStatusIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncService>(
      builder: (context, syncService, child) {
        if (!syncService.hasPendingSync && !syncService.isSyncing) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: syncService.isSyncing ? Colors.orange : Colors.amber,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (syncService.isSyncing)
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else
                const Icon(Icons.sync_problem, color: Colors.white, size: 12),
              const SizedBox(width: 4),
              Text(
                syncService.isSyncing
                    ? 'Sync'
                    : '${syncService.pendingSyncItems}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
