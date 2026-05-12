import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../utils/theme.dart';
import '../services/google_drive_service.dart';
import 'profile_setup_screen.dart';

class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final GoogleDriveService _googleDriveService = GoogleDriveService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => _handleSkip(context),
            child: const Text('SKIP', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              FadeInDown(
                child: Column(
                  children: [
                    // App Logo
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 8)),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.asset('assets/images/app_icon.png', fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Welcome to Cashbook',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -1),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Login/Signup to backup your data securely in your personal cloud.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF6B7280), fontSize: 16, height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 60),
              if (_isLoading)
                const CircularProgressIndicator(color: Color(0xFF6366F1))
              else ...[
                FadeInUp(
                  child: _buildLoginButton(
                    onPressed: () => _handleGoogleSignIn(context),
                    icon: Icons.g_mobiledata,
                    label: 'CONTINUE WITH GOOGLE',
                    color: const Color(0xFF4285F4),
                    elevation: 6,
                  ),
                ),
                const SizedBox(height: 16),
                FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  child: _buildLoginButton(
                    onPressed: () {},
                    icon: Icons.email_outlined,
                    label: 'CONTINUE WITH EMAIL',
                    color: Colors.white,
                    textColor: AppTheme.primaryColor,
                    hasBorder: true,
                  ),
                ),
              ],
              const Spacer(),
              _buildBottomAction(context),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomAction(BuildContext context) {
    return FadeIn(
      delay: const Duration(milliseconds: 600),
      child: TextButton(
        onPressed: () => _handleSkip(context),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('OTHER WAYS TO LOGIN', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.primaryColor, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
    Color textColor = Colors.white,
    bool hasBorder = false,
    double elevation = 0,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: hasBorder ? textColor : Colors.white, size: 24),
        label: Text(label, style: TextStyle(color: hasBorder ? textColor : Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 18),
          elevation: elevation,
          shadowColor: color.withOpacity(0.4),
          surfaceTintColor: Colors.transparent,
          side: hasBorder ? BorderSide(color: Colors.grey[200]!, width: 1.5) : BorderSide.none,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    setState(() => _isLoading = true);
    try {
      final account = await _googleDriveService.signIn();
      if (!mounted) return;
      if (account != null) {
        Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileSetupScreen()));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login failed: ${e.toString().replaceAll('Exception: ', '')}')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleSkip(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileSetupScreen(isSkip: true)));
  }
}
