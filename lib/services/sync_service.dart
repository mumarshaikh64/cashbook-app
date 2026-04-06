import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'google_drive_service.dart';

class SyncService {
  final GoogleDriveService _googleDriveService = GoogleDriveService();

  Future<void> autoBackupIfConnected() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.isNotEmpty && connectivityResult.first != ConnectivityResult.none) {
        if (await _googleDriveService.isSignedIn()) {
          await _googleDriveService.backupDatabase();
        }
      }
    } catch (e) {
      debugPrint('AutoBackup Error: $e');
    }
  }

  void monitorConnectivity() {
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.isNotEmpty && results.first != ConnectivityResult.none) {
        autoBackupIfConnected();
      }
    });
  }
}
