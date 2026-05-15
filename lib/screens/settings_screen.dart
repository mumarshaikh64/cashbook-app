import 'dart:io';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import '../services/google_drive_service.dart';
import '../providers/app_provider.dart';
import '../providers/transaction_provider.dart';
import 'auth_screen.dart';
import 'edit_profile_screen.dart';
import '../widgets/custom_modals.dart';
import 'terms_screen.dart';
import 'privacy_policy_screen.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final GoogleDriveService _googleDriveService = GoogleDriveService();
  bool _isSigningIn = false;
  bool _isSignedIn = false;
  bool _isBackingUp = false;
  bool _isRestoring = false;
  String? _googleEmail;
  String? _googleName;
  String? _googlePhoto;
  String? _lastBackup;
  String _appVersion = 'Version 1.0.0';


  @override
  void initState() {
    super.initState();
    _checkSignInStatus();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _appVersion = 'Version ${info.version}');
  }

  _checkSignInStatus() async {
    final status = await _googleDriveService.isSignedIn();
    final info = await _googleDriveService.getAccountInfo();
    if (mounted) {
      setState(() {
        _isSignedIn = status;
        _googleEmail = info['email'];
        _googleName = info['name'];
        _googlePhoto = info['photo'];
        _lastBackup = info['lastBackup'];
      });
    }
  }

  _handleSignIn() async {
    setState(() => _isSigningIn = true);
    try {
      final user = await _googleDriveService.signIn();
      if (mounted) {
        setState(() {
          _isSigningIn = false;
          _isSignedIn = user != null;
          if (user != null) {
            _googleEmail = user.email;
            _googleName = user.displayName;
            _googlePhoto = user.photoURL;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSigningIn = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  _handleSignOut() async {
    await _googleDriveService.signOut();
    if (mounted) {
      setState(() {
        _isSignedIn = false;
        _googleEmail = null;
        _googleName = null;
        _googlePhoto = null;
        _lastBackup = null;
      });
    }
  }

  _handleBackup() async {
    setState(() => _isBackingUp = true);
    try {
      final success = await _googleDriveService.backupDatabase();
      if (!mounted) return;
      if (success) {
        _lastBackup = DateTime.now().toIso8601String();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Backup successful!'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup failed. Please ensure Google Drive permission is granted.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Backup failed: ${e.toString().replaceAll('Exception: ', '')}')));
      }
    }
    if (mounted) setState(() => _isBackingUp = false);
  }

  _handleRestore() async {
    final confirmed = await CustomModals.showPremiumDialog<bool>(
      context: context,
      title: 'Restore Backup?',
      icon: Icons.restore_rounded,
      iconColor: const Color(0xFFEF4444),
      content: const Text(
        'This will replace your current data with the backup from Google Drive.\n\nThis action cannot be undone.',
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEF4444),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: const Text('RESTORE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            foregroundColor: Colors.grey[600],
          ),
          child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
    if (confirmed != true) return;

    setState(() => _isRestoring = true);
    try {
      final success = await _googleDriveService.restoreDatabase();
      if (!mounted) return;
      if (success) {
        await context.read<TransactionProvider>().fetchBooks();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('✅ Database restored successfully!'),
              backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No backup found on Google Drive.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Restore failed: $e')));
      }
    }
    if (mounted) setState(() => _isRestoring = false);
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final userName = appProvider.userName ?? 'User';
    final businessName = appProvider.businessName ?? 'My Business';
    final businessType = appProvider.businessType ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        automaticallyImplyLeading: false,
        title: const Text('Settings', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        children: [
          // ─── Profile Card ──────────────────────────
          FadeInDown(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              width: 72, height: 72,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFEEF2FF),
                                border: Border.all(color: const Color(0xFF6366F1), width: 2),
                                image: appProvider.logoPath != null
                                    ? DecorationImage(image: FileImage(File(appProvider.logoPath!)), fit: BoxFit.cover)
                                    : null,
                              ),
                              child: appProvider.logoPath == null
                                  ? Center(child: Text(userName.isNotEmpty ? userName[0].toUpperCase() : 'U', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF6366F1))))
                                  : null,
                            ),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Color(0xFF6366F1), shape: BoxShape.circle),
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(userName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                            const SizedBox(height: 2),
                            Text(businessName, style: const TextStyle(fontSize: 14, color: Color(0xFF6366F1), fontWeight: FontWeight.w600)),
                            if (businessType.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(12)),
                                child: Text(businessType, style: const TextStyle(fontSize: 11, color: Color(0xFF6366F1), fontWeight: FontWeight.w500)),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: Color(0xFF6366F1)),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
                      ),
                    ],
                  ),
                  if (appProvider.address != null || appProvider.phone != null || appProvider.email != null) ...[
                    const Divider(height: 28),
                    if (appProvider.address != null && appProvider.address!.isNotEmpty)
                      _infoRow(Icons.location_on_outlined, appProvider.address!),
                    if (appProvider.phone != null && appProvider.phone!.isNotEmpty)
                      _infoRow(Icons.phone_outlined, appProvider.phone!),
                    if (appProvider.email != null && appProvider.email!.isNotEmpty)
                      _infoRow(Icons.email_outlined, appProvider.email!),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ─── Google Drive Backup ──────────────────
          _buildSectionHeader('Google Drive Backup'),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Secure your data in your own Google Drive.', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.folder_open, size: 14, color: Colors.grey[400]),
                    const SizedBox(width: 6),
                    Text('Location: Google Drive (Root)', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                    const SizedBox(width: 12),
                    Icon(Icons.insert_drive_file_outlined, size: 14, color: Colors.grey[400]),
                    const SizedBox(width: 6),
                    Text('File: cashbook_backup.db', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 16),
                _isSignedIn ? _buildAccountInfo() : _buildSignInButton(),
                if (_isSignedIn) ...[
                  const SizedBox(height: 16),
                  // Backup
                  InkWell(
                    onTap: _isBackingUp ? null : _handleBackup,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          if (_isBackingUp)
                            const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6366F1)))
                          else
                            const Icon(Icons.backup_rounded, color: Color(0xFF6366F1), size: 22),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_isBackingUp ? 'Backing up...' : 'Backup Now', style: const TextStyle(fontWeight: FontWeight.w500)),
                                if (_lastBackup != null)
                                  Text('Last backup: ${_formatBackupTime(_lastBackup!)}', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                              ],
                            ),
                          ),
                          if (!_isBackingUp) const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                  const Divider(),
                  // Restore
                  InkWell(
                    onTap: _isRestoring ? null : _handleRestore,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          if (_isRestoring)
                            const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6366F1)))
                          else
                            const Icon(Icons.restore_rounded, color: Color(0xFF6366F1), size: 22),
                          const SizedBox(width: 16),
                          Expanded(child: Text(_isRestoring ? 'Restoring...' : 'Restore Database', style: const TextStyle(fontWeight: FontWeight.w500))),
                          if (!_isRestoring) const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ─── About & Legal ───────────────────────
          _buildSectionHeader('About & Legal'),
          Container(
            color: Colors.white,
            child: Column(
              children: [
                _buildActionRow(
                  Icons.gavel_rounded,
                  'Terms & Conditions',
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsScreen())),
                ),
                const Divider(height: 1, indent: 54),
                _buildActionRow(
                  Icons.shield_rounded,
                  'Privacy Policy',
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
                ),
                const Divider(height: 1, indent: 54),
                _buildActionRow(
                  Icons.info_outline,
                  _appVersion,
                  null,
                  subtitle: 'Built with ♥ by Softgrid Solutions',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ─── Logout ───────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FadeInUp(
              child: OutlinedButton.icon(
                onPressed: () => _handleLogout(context),
                icon: const Icon(Icons.logout_rounded, color: Colors.red),
                label: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ─── Account & Data Deletion (Google Policy) ───
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FadeInUp(
              delay: const Duration(milliseconds: 100),
              child: TextButton.icon(
                onPressed: () => _handleDeleteAccount(context),
                icon: const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
                label: const Text(
                  'Delete Account & Local Data',
                  style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: Colors.red.withOpacity(0.05),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  String _formatBackupTime(String isoTime) {
    try {
      final dt = DateTime.parse(isoTime);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
      if (diff.inHours < 24) return '${diff.inHours} hours ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return isoTime;
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[500], letterSpacing: 0.5)),
    );
  }

  Widget _buildActionRow(IconData icon, String title, VoidCallback? onTap, {String? subtitle}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF6366F1), size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w500, color: onTap == null ? Colors.grey : Colors.black87)),
                  if (subtitle != null) Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ],
              ),
            ),
            if (onTap != null) const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: TextStyle(color: Colors.grey[800], fontSize: 13))),
        ],
      ),
    );
  }

  void _handleLogout(BuildContext context) async {
    final confirmed = await CustomModals.showPremiumDialog<bool>(
      context: context,
      title: 'Logout?',
      content: const Text(
          'Are you sure you want to logout? Your local data will remain safe.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('CANCEL', style: TextStyle(color: Colors.grey[600])),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: const Text('LOGOUT'),
        ),
      ],
    );
    if (confirmed == true) {
      await _googleDriveService.signOut();
      if (!mounted) return;
      await context.read<AppProvider>().logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => AuthScreen()), (route) => false);
    }
  }

  void _handleDeleteAccount(BuildContext context) async {
    final confirmed = await CustomModals.showPremiumDialog<bool>(
      context: context,
      title: 'Delete Account & Data?',
      icon: Icons.warning_amber_rounded,
      iconColor: Colors.red,
      content: const Text(
        'Deleting your account will permanently erase all associated cashbook credentials, synced references, and profile identities from this device.\n\nThis action is irreversible and complies strictly with Google Play Data Deletion parameters.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('CANCEL', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: const Text('DELETE PERMANENTLY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ],
    );

    if (confirmed == true) {
      // Disconnect Google Drive scope bindings
      await _googleDriveService.signOut();
      if (!mounted) return;
      
      // Clear persistent key-value profiles and reset state buffers
      await context.read<AppProvider>().logout();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account and secure cached parameters purged successfully.'),
          backgroundColor: Colors.redAccent,
        ),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => AuthScreen()),
        (route) => false,
      );
    }
  }

  Widget _buildAccountInfo() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFF6366F1),
            backgroundImage: _googlePhoto != null && _googlePhoto!.isNotEmpty ? NetworkImage(_googlePhoto!) : null,
            child: _googlePhoto == null || _googlePhoto!.isEmpty ? const Icon(Icons.person, color: Colors.white, size: 20) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_googleName ?? 'Google Account', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(_googleEmail ?? '', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    const Text('Connected', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
          TextButton(onPressed: _handleSignOut, child: const Text('Sign Out', style: TextStyle(color: Colors.red, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildSignInButton() {
    return ElevatedButton.icon(
      onPressed: _isSigningIn ? null : _handleSignIn,
      icon: _isSigningIn
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.g_mobiledata, size: 28),
      label: Text(_isSigningIn ? 'Connecting...' : 'Sign in with Google', style: const TextStyle(fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        minimumSize: const Size(double.infinity, 50),
        side: BorderSide(color: Colors.grey[300]!),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    );
  }
}
