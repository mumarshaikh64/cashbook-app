import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import 'cashbooks_screen.dart';
import 'auth_screen.dart';
import '../providers/app_provider.dart';
import '../services/device_security_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final appProvider = context.read<AppProvider>();
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? appProvider.email;

    if (email != null) {
      // Perform Device Security Check
      final securityService = DeviceSecurityService();
      final result = await securityService.verifyDevice(email);

      if (result != "success") {
        if (mounted) {
          _showLockedDialog(result);
        }
        return;
      }
    }

    if (appProvider.isOnboarded) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => CashbooksScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AuthScreen()),
      );
    }
  }

  void _showLockedDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.lock_person, color: Colors.red),
            SizedBox(width: 10),
            Text('Security Alert'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            const Text(
              'Please contact support if you have changed your phone.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF6366F1).withOpacity(0.05),
                  Colors.white,
                ],
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FadeInDown(
                  duration: const Duration(seconds: 1),
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withOpacity(0.15),
                          blurRadius: 40,
                          offset: const Offset(0, 20),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Image.asset(
                      'assets/images/app_icon.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                FadeInUp(
                  duration: const Duration(seconds: 1),
                  child: Column(
                    children: [
                      const Text(
                        'CASHBOOK',
                        style: TextStyle(
                          color: Color(0xFF1F2937),
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 40,
                        height: 3,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: FadeIn(
              delay: const Duration(seconds: 2),
              child: Column(
                children: [
                  const Text(
                    'POWERED BY',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'SOFTGRID SOLUTIONS',
                    style: TextStyle(
                      color: const Color(0xFF6366F1).withOpacity(0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
