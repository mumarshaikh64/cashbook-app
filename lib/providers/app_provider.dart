import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppProvider with ChangeNotifier {
  bool _isOnboarded = false;
  String? _userName;
  String? _businessName;
  String? _businessType;
  String? _address;
  String? _phone;
  String? _email;
  String? _logoPath; // local file path for custom logo

  bool get isOnboarded => _isOnboarded;
  String? get userName => _userName;
  String? get businessName => _businessName;
  String? get businessType => _businessType;
  String? get address => _address;
  String? get phone => _phone;
  String? get email => _email;
  String? get logoPath => _logoPath;

  AppProvider() {
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    _isOnboarded = prefs.getBool('isOnboarded') ?? false;
    _userName = prefs.getString('userName');
    _businessName = prefs.getString('businessName');
    _businessType = prefs.getString('businessType');
    _address = prefs.getString('address');
    _phone = prefs.getString('phone');
    _email = prefs.getString('email');
    _logoPath = prefs.getString('logoPath');
    notifyListeners();
  }

  Future<void> completeOnboarding({
    String? name,
    String? business,
    String? type,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    _isOnboarded = true;
    _userName = name;
    _businessName = business;
    _businessType = type;

    await prefs.setBool('isOnboarded', true);
    if (name != null) await prefs.setString('userName', name);
    if (business != null) await prefs.setString('businessName', business);
    if (type != null) await prefs.setString('businessType', type);

    notifyListeners();
  }

  Future<void> updateProfile({
    String? name,
    String? businessName,
    String? businessType,
    String? address,
    String? phone,
    String? email,
    String? logoPath,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (name != null) { _userName = name; await prefs.setString('userName', name); }
    if (businessName != null) { _businessName = businessName; await prefs.setString('businessName', businessName); }
    if (businessType != null) { _businessType = businessType; await prefs.setString('businessType', businessType); }
    if (address != null) { _address = address; await prefs.setString('address', address); }
    if (phone != null) { _phone = phone; await prefs.setString('phone', phone); }
    if (email != null) { _email = email; await prefs.setString('email', email); }
    if (logoPath != null) { _logoPath = logoPath; await prefs.setString('logoPath', logoPath); }
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _isOnboarded = false;
    _userName = null;
    _businessName = null;
    _businessType = null;
    _address = null;
    _phone = null;
    _email = null;
    _logoPath = null;
    notifyListeners();
  }
}
