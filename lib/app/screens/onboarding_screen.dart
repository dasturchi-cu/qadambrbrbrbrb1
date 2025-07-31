import 'package:flutter/material.dart';
import 'package:qadam_app/app/screens/home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _numPages = 3;

  List<OnboardingPage> _pages = [];

  @override
  void initState() {
    super.initState();
    _pages = [
      OnboardingPage(
        title: 'Qadam sanang',
        description: 'Har bir qadamingizni kuzating va sog\'liq darajangizni oshiring',
        icon: Icons.directions_walk,
      ),
      OnboardingPage(
        title: 'Tanga yig\'ing',
        description: 'Qadamlaringiz uchun tangalar oling va turli sovg\'alar yutib oling',
        icon: Icons.monetization_on,
      ),
      OnboardingPage(
        title: 'Do\'stlaringizni taklif qiling',
        description: 'Referal havolangizni ulashing va qo\'shimcha tangalar yig\'ing',
        icon: Icons.people,
      ),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _numPages,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Skip button
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                      );
                    },
                    child: Text(
                      'O\'tkazib yuborish',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  
                  // Page indicator
                  Row(
                    children: List.generate(
                      _numPages,
                      (index) => _buildDot(index: index),
                    ),
                  ),
                  
                  // Next or Done button
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage != _numPages - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.ease,
                        );
                      } else {
                        // Request sensor permission here if needed
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(15),
                    ),
                    child: Icon(
                      _currentPage != _numPages - 1 ? Icons.arrow_forward : Icons.check,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              page.icon,
              size: 100,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            page.title,
            style: Theme.of(context).textTheme.displayMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            page.description,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDot({required int index}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(right: 5),
      height: 10,
      width: _currentPage == index ? 20 : 10,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? Theme.of(context).primaryColor
            : const Color(0xFFD8D8D8),
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
  });
} 