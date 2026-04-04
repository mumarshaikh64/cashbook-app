import 'package:connectivity_plus/connectivity_plus.dart';
import 'google_drive_service.dart';

class SyncService {
  final GoogleDriveService _googleDriveService = GoogleDriveService();

  Future<void> autoBackupIfConnected() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult != ConnectivityResult.none) {
      if (await _googleDriveService.isSignedIn()) {
        await _googleDriveService.backupDatabase();
      }
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
