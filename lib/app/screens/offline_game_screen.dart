import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'dart:async';
import '../services/coin_service.dart';
import '../services/connectivity_service.dart';

class OfflineGameScreen extends StatefulWidget {
  const OfflineGameScreen({Key? key}) : super(key: key);

  @override
  State<OfflineGameScreen> createState() => _OfflineGameScreenState();
}

class _OfflineGameScreenState extends State<OfflineGameScreen>
    with TickerProviderStateMixin {
  int _score = 0;
  int _timeLeft = 30;
  bool _isPlaying = false;
  bool _gameOver = false;
  Timer? _gameTimer;
  Timer? _spawnTimer;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  final List<GameBubble> _bubbles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _spawnTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _score = 0;
      _timeLeft = 30;
      _isPlaying = true;
      _gameOver = false;
      _bubbles.clear();
    });

    // Game timer
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timeLeft--;
        if (_timeLeft <= 0) {
          _endGame();
        }
      });
    });

    // Spawn bubbles
    _spawnTimer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      if (_isPlaying) {
        _spawnBubble();
      }
    });
  }

  void _spawnBubble() {
    final bubble = GameBubble(
      id: DateTime.now().millisecondsSinceEpoch,
      x: _random.nextDouble() * 300,
      y: _random.nextDouble() * 400 + 100,
      color: _getRandomColor(),
      points: _random.nextInt(5) + 1,
    );

    setState(() {
      _bubbles.add(bubble);
    });

    // Remove bubble after 3 seconds
    Timer(const Duration(seconds: 3), () {
      setState(() {
        _bubbles.removeWhere((b) => b.id == bubble.id);
      });
    });
  }

  Color _getRandomColor() {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.pink,
    ];
    return colors[_random.nextInt(colors.length)];
  }

  void _popBubble(GameBubble bubble) {
    setState(() {
      _score += bubble.points;
      _bubbles.remove(bubble);
    });

    _animationController.forward().then((_) {
      _animationController.reverse();
    });
  }

  void _endGame() {
    _gameTimer?.cancel();
    _spawnTimer?.cancel();

    setState(() {
      _isPlaying = false;
      _gameOver = true;
      _bubbles.clear();
    });

    // Award coins based on score
    final coinService = Provider.of<CoinService>(context, listen: false);
    final coinsEarned = (_score / 10).floor();
    if (coinsEarned > 0) {
      coinService.addCoins(coinsEarned, description: 'Offline o\'yin');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        title:
            const Text('Offline O\'yin', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer<ConnectivityService>(
        builder: (context, connectivity, child) {
          return Stack(
            children: [
              // Background
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.indigo,
                      Colors.purple,
                      Colors.black87,
                    ],
                  ),
                ),
              ),

              // Game area
              if (_isPlaying) ...[
                // Bubbles
                ..._bubbles
                    .map((bubble) => Positioned(
                          left: bubble.x,
                          top: bubble.y,
                          child: GestureDetector(
                            onTap: () => _popBubble(bubble),
                            child: AnimatedBuilder(
                              animation: _scaleAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _bubbles.contains(bubble)
                                      ? _scaleAnimation.value
                                      : 1.0,
                                  child: Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color:
                                          bubble.color.withValues(alpha: 0.8),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: bubble.color
                                              .withValues(alpha: 0.3),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${bubble.points}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ))
                    .toList(),

                // Game UI
                Positioned(
                  top: 20,
                  left: 20,
                  right: 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Ball: $_score',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Vaqt: $_timeLeft',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Game over or start screen
              if (!_isPlaying) ...[
                Center(
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          connectivity.isOffline ? Icons.wifi_off : Icons.games,
                          size: 80,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          connectivity.isOffline
                              ? 'Internet aloqasi yo\'q'
                              : 'Offline O\'yin',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          connectivity.isOffline
                              ? 'Internet qaytguncha o\'yin o\'ynang!'
                              : 'Qiziqarli bubble o\'yini!',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_gameOver) ...[
                          const SizedBox(height: 20),
                          Text(
                            'Yakuniy ball: $_score',
                            style: const TextStyle(
                              color: Colors.yellow,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Tanga: ${(_score / 10).floor()}',
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                        const SizedBox(height: 30),
                        ElevatedButton(
                          onPressed: _startGame,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 40, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: Text(
                            _gameOver ? 'Qayta o\'ynash' : 'O\'yinni boshlash',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Rangdor pufakchalarni bosing!\nHar bir pufakcha ball beradi.',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class GameBubble {
  final int id;
  final double x;
  final double y;
  final Color color;
  final int points;

  GameBubble({
    required this.id,
    required this.x,
    required this.y,
    required this.color,
    required this.points,
  });
}
