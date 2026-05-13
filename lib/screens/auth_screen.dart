import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/theme.dart';
import '../services/google_drive_service.dart';
import 'profile_setup_screen.dart';
import 'terms_screen.dart';
import 'privacy_policy_screen.dart';

class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final GoogleDriveService _googleDriveService = GoogleDriveService();
  bool _isLoading = false;
  bool _isEmailLoading = false;
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _version = 'v${info.version}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // actions: [
        //   TextButton(
        //     onPressed: () => _handleSkip(context),
        //     child: const Text(
        //       'SKIP',
        //       style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
        //     ),
        //   ),
        // ],
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
                          BoxShadow(
                            color: const Color(0xFF6366F1).withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.asset(
                          'assets/images/app_icon.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Naya Khata',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'اپنا ڈیجیٹل کھاتہ شروع کریں',
                      style: TextStyle(
                        color: Color(0xFF6366F1),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Login/Signup to backup your data securely in your personal cloud.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              if (_isLoading || _isEmailLoading)
                const CircularProgressIndicator(color: Color(0xFF6366F1))
              else ...[
                // ── Google Button (Proper Google Colors) ──
                FadeInUp(child: _buildGoogleButton()),
                const SizedBox(height: 14),
                // ── Divider ──
                FadeInUp(
                  delay: const Duration(milliseconds: 150),
                  child: Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey[200])),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey[200])),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // ── Email Button ──
                FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  child: _buildEmailButton(),
                ),
              ],
              const Spacer(),
              FadeIn(
                delay: const Duration(milliseconds: 600),
                child: Column(
                  children: [
                    Text(
                      'By continuing, you agree to Naya Khata\'s',
                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsScreen())),
                          child: const Text(
                            'Terms & Conditions',
                            style: TextStyle(
                              color: Color(0xFF6366F1),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        Text('  •  ', style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
                          child: const Text(
                            'Privacy Policy',
                            style: TextStyle(
                              color: Color(0xFF6366F1),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _version.isEmpty ? '' : _version,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () => _handleGoogleSignIn(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF3C4043),
          elevation: 2,
          shadowColor: Colors.black26,
          side: const BorderSide(color: Color(0xFFDADCE0), width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildGoogleGIcon(),
            const SizedBox(width: 12),
            const Text(
              'Continue with Google',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3C4043),
                letterSpacing: 0.25,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Pixel-perfect Google G logo custom painter
  Widget _buildGoogleGIcon() {
    return SizedBox(
      width: 24,
      height: 24,
      child: ClipOval(
        child: CustomPaint(
          painter: _GoogleLogoPainter(),
        ),
      ),
    );
  }

  Widget _buildEmailButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () => _showEmailAuthModal(context),
        icon: const Icon(Icons.email_outlined, size: 22, color: Colors.white),
        label: const Text(
          'Continue with Email',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.25,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: AppTheme.primaryColor.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────
  //  Email Auth Bottom Sheet
  // ────────────────────────────────────────────────
  void _showEmailAuthModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EmailAuthSheet(
        onAuthSuccess: () {
          Navigator.pop(context); // close sheet
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => ProfileSetupScreen()),
          );
        },
      ),
    );
  }

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    setState(() => _isLoading = true);
    try {
      final account = await _googleDriveService.signIn();
      if (!mounted) return;
      if (account != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProfileSetupScreen()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Login failed: ${e.toString().replaceAll('Exception: ', '')}',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleSkip(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProfileSetupScreen(isSkip: true)),
    );
  }
}

// ────────────────────────────────────────────────
//  Email Auth Bottom Sheet Widget
// ────────────────────────────────────────────────
class _EmailAuthSheet extends StatefulWidget {
  final VoidCallback onAuthSuccess;
  const _EmailAuthSheet({required this.onAuthSuccess});

  @override
  _EmailAuthSheetState createState() => _EmailAuthSheetState();
}

class _EmailAuthSheetState extends State<_EmailAuthSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() => _errorMsg = null));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Naya Khata',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Login or create a new account',
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
          const SizedBox(height: 20),
          // Tabs
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[600],
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              indicator: BoxDecoration(
                color: const Color(0xFF6366F1),
                borderRadius: BorderRadius.circular(12),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              padding: const EdgeInsets.all(4),
              tabs: const [
                Tab(text: 'Login'),
                Tab(text: 'Sign Up'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Error message
          if (_errorMsg != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMsg!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          // Email field
          _buildField(
            controller: _emailCtrl,
            label: 'Email Address',
            icon: Icons.email_outlined,
            keyboard: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          // Password field
          _buildField(
            controller: _passCtrl,
            label: 'Password',
            icon: Icons.lock_outline,
            obscure: _obscurePass,
            onToggleObscure: () => setState(() => _obscurePass = !_obscurePass),
          ),
          // Confirm password (Sign Up only)
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            child: _tabController.index == 1
                ? Column(
                    children: [
                      const SizedBox(height: 12),
                      _buildField(
                        controller: _confirmPassCtrl,
                        label: 'Confirm Password',
                        icon: Icons.lock_outline,
                        obscure: _obscureConfirm,
                        onToggleObscure: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
          // Forgot password (Login tab only)
          if (_tabController.index == 0)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _handleForgotPassword,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(
                    color: Color(0xFF6366F1),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          else
            const SizedBox(height: 8),
          const SizedBox(height: 8),
          // Submit button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: const Color(0xFF6366F1).withOpacity(0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      _tabController.index == 0 ? 'LOGIN' : 'CREATE ACCOUNT',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
    bool obscure = false,
    VoidCallback? onToggleObscure,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey[500], size: 20),
        suffixIcon: onToggleObscure != null
            ? IconButton(
                icon: Icon(
                  obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                  color: Colors.grey[500],
                ),
                onPressed: onToggleObscure,
              )
            : null,
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    setState(() {
      _errorMsg = null;
      _isLoading = true;
    });

    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();

    // Basic validation
    if (email.isEmpty || pass.isEmpty) {
      setState(() {
        _errorMsg = 'Please enter your email and password.';
        _isLoading = false;
      });
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      setState(() {
        _errorMsg = 'Please enter a valid email address.';
        _isLoading = false;
      });
      return;
    }
    if (pass.length < 6) {
      setState(() {
        _errorMsg = 'Password must be at least 6 characters.';
        _isLoading = false;
      });
      return;
    }

    try {
      if (_tabController.index == 0) {
        // ── LOGIN ──
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: pass,
        );
      } else {
        // ── SIGN UP ──
        final confirm = _confirmPassCtrl.text.trim();
        if (pass != confirm) {
          setState(() {
            _errorMsg = 'Passwords do not match.';
            _isLoading = false;
          });
          return;
        }
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: pass,
        );
      }
      if (mounted) widget.onAuthSuccess();
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMsg = _friendlyError(e.code);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMsg = 'Something went wrong. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMsg = 'Enter your email above to reset password.');
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Password reset email sent! Check your inbox.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMsg = _friendlyError(e.code));
    }
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email. Please sign up first.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'This email is already registered. Please login instead.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'invalid-credential':
        return 'Incorrect email or password. Please try again.';
      default:
        return 'Authentication failed ($code). Please try again.';
    }
  }
}

// ────────────────────────────────────────────────
//  Pixel-Perfect Google 'G' Logo Custom Painter
// ────────────────────────────────────────────────
class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double r = size.width / 2;
    // Premium Google logo stroke width ratio
    final double strokeWidth = size.width * 0.23;
    final double innerR = r - strokeWidth / 2;

    final Rect rect = Rect.fromCircle(center: Offset(r, r), radius: innerR);

    void drawSegment(Color color, double startAngle, double sweepAngle) {
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
    }

    const double pi = 3.141592653589793;

    // Standard angles in radians
    // Red (top curve): from -135° to -30°
    drawSegment(const Color(0xFFEA4335), -135 * pi / 180, 105 * pi / 180);

    // Yellow (left curve): from 135° to 225° (-135°)
    drawSegment(const Color(0xFFFBBC05), 135 * pi / 180, 90 * pi / 180);

    // Green (bottom curve): from 40° to 135°
    drawSegment(const Color(0xFF34A853), 40 * pi / 180, 95 * pi / 180);

    // Blue (right lower arc): from 0° to 40°
    drawSegment(const Color(0xFF4285F4), 0, 40 * pi / 180);

    // Blue horizontal arm
    final paintArm = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;

    final Path armPath = Path()
      ..moveTo(r - 0.5, r - strokeWidth / 2)
      ..lineTo(size.width, r - strokeWidth / 2)
      ..lineTo(size.width, r + strokeWidth / 2)
      ..lineTo(r - 0.5, r + strokeWidth / 2)
      ..close();

    canvas.drawPath(armPath, paintArm);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

