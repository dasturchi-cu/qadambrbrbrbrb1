import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../services/connectivity_service.dart';
import '../services/offline_game_service.dart';

class AutoGameTriggerWidget extends StatefulWidget {
  final Widget child;
  
  const AutoGameTriggerWidget({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<AutoGameTriggerWidget> createState() => _AutoGameTriggerWidgetState();
}

class _AutoGameTriggerWidgetState extends State<AutoGameTriggerWidget>
    with TickerProviderStateMixin {
  
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  
  @override
  void initState() {
    super.initState();
    _initAnimations();
  }
  
  void _initAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.5, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        
        // Auto-trigger game widget
        Consumer2<ConnectivityService, OfflineGameService>(
          builder: (context, connectivity, gameService, child) {
            // Show game trigger when offline and game is triggered
            if (!connectivity.isOffline || !gameService.isGameTriggered) {
              _slideController.reverse();
              return const SizedBox.shrink();
            }
            
            _slideController.forward();
            
            return Positioned(
              top: MediaQuery.of(context).padding.top + 80,
              right: 16,
              child: SlideTransition(
                position: _slideAnimation,
                child: _buildGameTriggerCard(context, connectivity, gameService),
              ),
            );
          },
        ),
      ],
    );
  }
  
  Widget _buildGameTriggerCard(
    BuildContext context,
    ConnectivityService connectivity,
    OfflineGameService gameService,
  ) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.purple, Colors.blue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.games,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Internet yo\'q!',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'O\'yin o\'ynab vaqt o\'tkazing',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      gameService.setAutoTriggerEnabled(false);
                    },
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white70,
                      size: 20,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Game options
              Row(
                children: [
                  Expanded(
                    child: _buildGameButton(
                      context,
                      gameService,
                      GameType.dinosaur,
                      'Dinosaur',
                      Icons.directions_run,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildGameButton(
                      context,
                      gameService,
                      GameType.bubble,
                      'Bubble',
                      Icons.bubble_chart,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Status
              Row(
                children: [
                  Icon(
                    Icons.wifi_off,
                    color: Colors.white70,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      gameService.getOfflineTimeString(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildGameButton(
    BuildContext context,
    OfflineGameService gameService,
    GameType gameType,
    String title,
    IconData icon,
  ) {
    final isSelected = gameService.preferredGame == gameType;
    
    return GestureDetector(
      onTap: () {
        gameService.setPreferredGame(gameType);
        gameService.triggerGame(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected 
              ? Colors.white.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: isSelected 
              ? Border.all(color: Colors.white.withValues(alpha: 0.5))
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Floating game button for manual access
class FloatingGameButton extends StatefulWidget {
  const FloatingGameButton({Key? key}) : super(key: key);

  @override
  State<FloatingGameButton> createState() => _FloatingGameButtonState();
}

class _FloatingGameButtonState extends State<FloatingGameButton>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;
  
  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * pi,
    ).animate(_rotationController);
  }
  
  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer2<ConnectivityService, OfflineGameService>(
      builder: (context, connectivity, gameService, child) {
        if (!gameService.shouldShowGameButton()) {
          return const SizedBox.shrink();
        }
        
        return Positioned(
          bottom: 100,
          right: 16,
          child: AnimatedBuilder(
            animation: _rotationAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationAnimation.value,
                child: FloatingActionButton(
                  onPressed: () => gameService.triggerGame(context),
                  backgroundColor: Colors.purple,
                  child: const Icon(
                    Icons.games,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
