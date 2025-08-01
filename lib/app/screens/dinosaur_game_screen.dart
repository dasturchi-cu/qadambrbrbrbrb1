import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math';
import '../services/coin_service.dart';
import '../services/connectivity_service.dart';

class DinosaurGameScreen extends StatefulWidget {
  const DinosaurGameScreen({Key? key}) : super(key: key);

  @override
  State<DinosaurGameScreen> createState() => _DinosaurGameScreenState();
}

class _DinosaurGameScreenState extends State<DinosaurGameScreen>
    with TickerProviderStateMixin {
  
  // Game state
  bool _isPlaying = false;
  bool _gameOver = false;
  bool _isJumping = false;
  int _score = 0;
  int _highScore = 0;
  double _gameSpeed = 3.0;
  
  // Dinosaur position
  double _dinoY = 0;
  double _dinoX = 50;
  
  // Obstacles
  final List<Obstacle> _obstacles = [];
  final Random _random = Random();
  
  // Animations
  late AnimationController _jumpController;
  late AnimationController _runController;
  late Animation<double> _jumpAnimation;
  
  // Timers
  Timer? _gameTimer;
  Timer? _obstacleTimer;
  
  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadHighScore();
  }
  
  void _initAnimations() {
    _jumpController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _runController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    )..repeat(reverse: true);
    
    _jumpAnimation = Tween<double>(
      begin: 0,
      end: -100,
    ).animate(CurvedAnimation(
      parent: _jumpController,
      curve: Curves.easeOut,
    ));
    
    _jumpAnimation.addListener(() {
      setState(() {
        _dinoY = _jumpAnimation.value;
      });
    });
    
    _jumpController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _jumpController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _isJumping = false;
      }
    });
  }
  
  void _loadHighScore() async {
    // Load high score from SharedPreferences
    _highScore = 0; // Placeholder
  }
  
  void _startGame() {
    setState(() {
      _isPlaying = true;
      _gameOver = false;
      _score = 0;
      _gameSpeed = 3.0;
      _obstacles.clear();
      _dinoY = 0;
    });
    
    _runController.repeat(reverse: true);
    
    // Game loop
    _gameTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      _updateGame();
    });
    
    // Spawn obstacles
    _obstacleTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      _spawnObstacle();
    });
  }
  
  void _updateGame() {
    if (!_isPlaying) return;
    
    setState(() {
      // Update score
      _score += 1;
      
      // Increase speed gradually
      if (_score % 100 == 0) {
        _gameSpeed += 0.2;
      }
      
      // Move obstacles
      for (int i = _obstacles.length - 1; i >= 0; i--) {
        _obstacles[i].x -= _gameSpeed;
        
        // Remove off-screen obstacles
        if (_obstacles[i].x < -50) {
          _obstacles.removeAt(i);
        }
      }
      
      // Check collisions
      _checkCollisions();
    });
  }
  
  void _spawnObstacle() {
    if (!_isPlaying) return;
    
    final obstacle = Obstacle(
      x: MediaQuery.of(context).size.width,
      y: 0,
      width: 20,
      height: _random.nextInt(30) + 40,
      type: _random.nextBool() ? ObstacleType.cactus : ObstacleType.bird,
    );
    
    setState(() {
      _obstacles.add(obstacle);
    });
  }
  
  void _checkCollisions() {
    const dinoWidth = 40.0;
    const dinoHeight = 40.0;
    
    for (final obstacle in _obstacles) {
      if (obstacle.x < _dinoX + dinoWidth &&
          obstacle.x + obstacle.width > _dinoX &&
          obstacle.y < _dinoY + dinoHeight + 150 &&
          obstacle.y + obstacle.height > _dinoY + 150) {
        _endGame();
        break;
      }
    }
  }
  
  void _jump() {
    if (!_isJumping && _isPlaying && !_gameOver) {
      _isJumping = true;
      _jumpController.forward();
      HapticFeedback.lightImpact();
    }
  }
  
  void _endGame() {
    _gameTimer?.cancel();
    _obstacleTimer?.cancel();
    _runController.stop();
    
    setState(() {
      _isPlaying = false;
      _gameOver = true;
      
      if (_score > _highScore) {
        _highScore = _score;
        // Save high score
      }
    });
    
    // Award coins
    final coinService = Provider.of<CoinService>(context, listen: false);
    final coinsEarned = (_score / 50).floor();
    if (coinsEarned > 0) {
      coinService.addCoins(coinsEarned, description: 'Dinosaur o\'yin');
    }
    
    HapticFeedback.mediumImpact();
  }
  
  @override
  void dispose() {
    _gameTimer?.cancel();
    _obstacleTimer?.cancel();
    _jumpController.dispose();
    _runController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Consumer<ConnectivityService>(
        builder: (context, connectivity, child) {
          return GestureDetector(
            onTap: _jump,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: connectivity.isOffline 
                      ? [Colors.grey[300]!, Colors.grey[100]!]
                      : [Colors.blue[100]!, Colors.white],
                ),
              ),
              child: Stack(
                children: [
                  // Background elements
                  _buildBackground(),
                  
                  // Game area
                  if (_isPlaying) ...[
                    // Dinosaur
                    _buildDinosaur(),
                    
                    // Obstacles
                    ..._obstacles.map((obstacle) => _buildObstacle(obstacle)),
                    
                    // Score
                    _buildScore(),
                  ],
                  
                  // Start/Game Over screen
                  if (!_isPlaying) _buildStartScreen(connectivity),
                  
                  // Connection status
                  _buildConnectionStatus(connectivity),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildBackground() {
    return Positioned(
      bottom: 100,
      left: 0,
      right: 0,
      child: Container(
        height: 2,
        color: Colors.grey[400],
      ),
    );
  }
  
  Widget _buildDinosaur() {
    return Positioned(
      left: _dinoX,
      bottom: 150 + _dinoY,
      child: AnimatedBuilder(
        animation: _runController,
        builder: (context, child) {
          return Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.green[600],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _isJumping ? Icons.flight_takeoff : Icons.directions_run,
              color: Colors.white,
              size: 24,
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildObstacle(Obstacle obstacle) {
    return Positioned(
      left: obstacle.x,
      bottom: 150 + obstacle.y,
      child: Container(
        width: obstacle.width,
        height: obstacle.height,
        decoration: BoxDecoration(
          color: obstacle.type == ObstacleType.cactus 
              ? Colors.green[800] 
              : Colors.brown[600],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          obstacle.type == ObstacleType.cactus 
              ? Icons.grass 
              : Icons.flight,
          color: Colors.white,
          size: 16,
        ),
      ),
    );
  }
  
  Widget _buildScore() {
    return Positioned(
      top: 100,
      right: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'Ball: $_score',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(
            'Eng yuqori: $_highScore',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStartScreen(ConnectivityService connectivity) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              connectivity.isOffline ? Icons.wifi_off : Icons.games,
              size: 80,
              color: connectivity.isOffline ? Colors.red : Colors.green,
            ),
            const SizedBox(height: 20),
            Text(
              connectivity.isOffline 
                  ? 'Internet aloqasi yo\'q' 
                  : 'Dinosaur Runner',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              connectivity.isOffline 
                  ? 'Internet qaytguncha o\'yin o\'ynang!' 
                  : 'Chrome Dinosaur ga o\'xshash o\'yin!',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            if (_gameOver) ...[
              const SizedBox(height: 20),
              Text(
                'Yakuniy ball: $_score',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              Text(
                'Tanga: ${(_score / 50).floor()}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _startGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Text(
                _gameOver ? 'Qayta o\'ynash' : 'O\'yinni boshlash',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Ekranni bosib sakrang!\nTo\'siqlardan qoching.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildConnectionStatus(ConnectivityService connectivity) {
    if (connectivity.isOnline) return const SizedBox.shrink();
    
    return Positioned(
      top: 50,
      left: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off, color: Colors.white, size: 16),
            SizedBox(width: 4),
            Text(
              'Oflayn',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class Obstacle {
  double x;
  double y;
  double width;
  double height;
  ObstacleType type;
  
  Obstacle({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.type,
  });
}

enum ObstacleType { cactus, bird }
