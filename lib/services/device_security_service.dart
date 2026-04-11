import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

class DeviceSecurityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// Core logic to check or bind the device
  /// Returns 'success', 'locked', or 'error message'
  Future<String> verifyDevice(String email) async {
    try {
      String? currentDeviceId = await _getUniqueId();
      if (currentDeviceId == null) return "Could not fetch Device ID";

      final docRef = _firestore.collection('device_locks').doc(email);
      final doc = await docRef.get();

      if (!doc.exists) {
        // Case A: New User / First time on this system
        String activationCode = _generateActivationCode();
        await docRef.set({
          'email': email,
          'device_id': currentDeviceId,
          'activation_code': activationCode,
          'locked_at': FieldValue.serverTimestamp(),
          'is_active': true,
        });
        return "success";
      } else {
        // Case B: Returning User
        String storedDeviceId = doc.data()?['device_id'] ?? "";

        if (storedDeviceId == currentDeviceId) {
          return "success";
        } else {
          return "This account is locked to another device.";
        }
      }
    } catch (e) {
      debugPrint("DeviceSecurity Error: $e");
      return "Security check failed: $e";
    }
  }

  /// Helper to get unique hardware ID
  Future<String?> _getUniqueId() async {
    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await _deviceInfo.androidInfo;
        return androidInfo.id; // Unique ID on Android
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.identifierForVendor; // Unique ID on iOS
      }
    } catch (e) {
      debugPrint("Error getting device ID: $e");
    }
    return null;
  }

  /// Generate a random 6-digit code for new bindings
  String _generateActivationCode() {
    return (Random().nextInt(900000) + 100000).toString();
  }

  /// Utility to manually reset a lock (Admin logic)
  Future<void> clearDeviceLock(String email) async {
    await _firestore.collection('device_locks').doc(email).delete();
  }
}
