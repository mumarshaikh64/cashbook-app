import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'dashboard_screen.dart';
import '../utils/theme.dart';

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingItem> _items = [
    OnboardingItem(
      title: 'Offline First',
      description: 'Your data stays with you. No internet required to record transactions.',
      icon: Icons.offline_bolt_rounded,
      color: AppTheme.primaryColor,
    ),
    OnboardingItem(
      title: 'Google Drive Backup',
      description: 'Never lose your data. Automatic backup when you are online.',
      icon: Icons.cloud_upload_rounded,
      color: AppTheme.accentColor,
    ),
    OnboardingItem(
      title: 'Simple Calculations',
      description: 'Get instant insights into your cash in, cash out, and balance.',
      icon: Icons.calculate_rounded,
      color: AppTheme.errorColor,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _items.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FadeInDown(
                          child: CircleAvatar(
                            radius: 100,
                            backgroundColor: item.color.withOpacity(0.1),
                            child: Icon(item.icon, size: 100, color: item.color),
                          ),
                        ),
                        const SizedBox(height: 48),
                        FadeInUp(
                          child: Text(
                            item.title,
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                        ),
                        const SizedBox(height: 16),
                        FadeInUp(
                          delay: const Duration(milliseconds: 300),
                          child: Text(
                            item.description,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: List.generate(
              _items.length,
              (index) => Container(
                margin: const EdgeInsets.only(right: 6),
                width: _currentPage == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == index ? AppTheme.primaryColor : Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (_currentPage < _items.length - 1) {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                );
              } else {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => DashboardScreen()));
              }
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(_currentPage == _items.length - 1 ? 'Get Started' : 'Next'),
          ),
        ],
      ),
    );
  }
}

class OnboardingItem {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingItem({required this.title, required this.description, required this.icon, required this.color});
}
