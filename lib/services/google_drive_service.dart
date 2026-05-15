import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';

class GoogleDriveService {
  static final GoogleDriveService _instance = GoogleDriveService._internal();
  factory GoogleDriveService() => _instance;
  GoogleDriveService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>[drive.DriveApi.driveFileScope],
    serverClientId: '781643880585-6jfj59pk0cridl7655vqe8hfvlra39hs.apps.googleusercontent.com',
  );

  GoogleSignInAccount? get currentGoogleUser => _googleSignIn.currentUser;
  User? get currentFirebaseUser => _auth.currentUser;

  Future<User?> signIn() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      // Ensure Google Drive permission is granted for backups gracefully
      try {
        final bool canAccess = await _googleSignIn.canAccessScopes(<String>[drive.DriveApi.driveFileScope]);
        if (!canAccess) {
          final bool authorized = await _googleSignIn.requestScopes(<String>[drive.DriveApi.driveFileScope]);
          if (!authorized) {
            throw Exception('Google Drive permission is required to enable backup.');
          }
        }
      } catch (e) {
        print('Scope check warning (safe to ignore if granted during login): $e');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('googleEmail', user.email ?? '');
        await prefs.setString('googleDisplayName', user.displayName ?? '');
        await prefs.setString('googlePhotoUrl', user.photoURL ?? '');
      }
      return user;
    } catch (e) {
      print('Google Sign-In Error: $e');
      // Rethrow to allow UI to display the exact permission or network error
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('googleEmail');
    await prefs.remove('googleDisplayName');
    await prefs.remove('googlePhotoUrl');
    await prefs.remove('lastBackupTime');
  }

  Future<bool> isSignedIn() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return false;

    // Try to silently sign in to Google if session is lost
    if (_googleSignIn.currentUser == null) {
      try {
        await _googleSignIn.signInSilently();
      } catch (e) {
        print('SignIn Silently Error: $e');
        return false;
      }
    }
    
    return _googleSignIn.currentUser != null;
  }

  Future<Map<String, String?>> getAccountInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final user = _auth.currentUser;
    return {
      'email': user?.email ?? prefs.getString('googleEmail'),
      'name': user?.displayName ?? prefs.getString('googleDisplayName'),
      'photo': user?.photoURL ?? prefs.getString('googlePhotoUrl'),
      'lastBackup': prefs.getString('lastBackupTime'),
    };
  }

  Future<drive.DriveApi?> _getDriveApi() async {
    try {
      if (_googleSignIn.currentUser == null) {
        try {
          await _googleSignIn.signInSilently();
        } catch (_) {}
      }

      if (_googleSignIn.currentUser == null) {
        return null;
      }

      try {
        final bool canAccess = await _googleSignIn.canAccessScopes(<String>[drive.DriveApi.driveFileScope]);
        if (!canAccess) {
          final bool authorized = await _googleSignIn.requestScopes(<String>[drive.DriveApi.driveFileScope]);
          if (!authorized) {
            print('User denied Google Drive scope access.');
            return null;
          }
        }
      } catch (e) {
        print('Scope check warning in getDriveApi: $e');
      }

      final client = await _googleSignIn.authenticatedClient();
      if (client == null) return null;
      return drive.DriveApi(client);
    } catch (e) {
      print('Drive API Error: $e');
      return null;
    }
  }

  Future<bool> backupDatabase() async {
    final driveApi = await _getDriveApi();
    if (driveApi == null) {
      // Re-signing in since the client session might be lost
      await _googleSignIn.signInSilently();
      final freshApi = await _getDriveApi();
      if (freshApi == null) {
        throw Exception('Google Drive access not granted. Please sign out and sign in again, making sure to check the box for Google Drive access.');
      }
      return _runBackup(freshApi);
    }
    return _runBackup(driveApi);
  }

  Future<bool> _runBackup(drive.DriveApi driveApi) async {
    try {
      // Ensure local SQLite database is fully created and initialized before backing up
      await DatabaseHelper.instance.database;

      final dbPath = await getDatabasesPath();
      final path = p.join(dbPath, 'cashbook.db');
      final file = File(path);

      if (!await file.exists()) {
        throw Exception('Database file could not be found or created. Please add a transaction first.');
      }

      final driveFile = drive.File();
      driveFile.name = 'cashbook_backup.db';
      driveFile.mimeType = 'application/x-sqlite3';
      driveFile.description = 'Cashbook App Backup - ${DateTime.now().toIso8601String()}';

      final media = drive.Media(file.openRead(), await file.length());

      final list = await driveApi.files.list(q: "name = 'cashbook_backup.db' and trashed = false");
      if (list.files != null && list.files!.isNotEmpty) {
        await driveApi.files.update(driveFile, list.files!.first.id!, uploadMedia: media);
      } else {
        await driveApi.files.create(driveFile, uploadMedia: media);
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('lastBackupTime', DateTime.now().toIso8601String());
      return true;
    } catch (e) {
      print('Backup Exec Error: $e');
      throw Exception('Network or API Error: $e');
    }
  }

  Future<bool> restoreDatabase() async {
    final driveApi = await _getDriveApi();
    if (driveApi == null) {
      await _googleSignIn.signInSilently();
      final freshApi = await _getDriveApi();
      if (freshApi == null) {
        throw Exception('Google Drive access not granted. Please sign in with Google Drive permissions enabled.');
      }
      return _runRestore(freshApi);
    }
    return _runRestore(driveApi);
  }

  Future<bool> _runRestore(drive.DriveApi driveApi) async {
    try {
      final list = await driveApi.files.list(q: "name = 'cashbook_backup.db' and trashed = false");
      if (list.files == null || list.files!.isEmpty) {
        throw Exception('No backup file found on your Google Drive account.');
      }

      final fileId = list.files!.first.id!;
      final media = await driveApi.files.get(fileId, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;

      final dbPath = await getDatabasesPath();
      final path = p.join(dbPath, 'cashbook.db');
      final file = File(path);

      final List<int> dataStore = <int>[];
      await for (final data in media.stream) {
        dataStore.addAll(data);
      }
      await file.writeAsBytes(dataStore);
      return true;
    } catch (e) {
      print('Restore Exec Error: $e');
      throw Exception('Restore failed: $e');
    }
  }
}
