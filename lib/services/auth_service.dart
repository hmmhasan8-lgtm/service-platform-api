import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const String baseUrl = 'http://localhost:8000';
  static const String _tokenKey = 'service_auth_token';
  static const String _userKey = 'service_user_data';

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null && _currentUser!.token != null;
  bool get isVerified => _currentUser != null && _currentUser!.isVerified;

  /// Initialize and load saved session.
  /// If no user exists, returns null so app opens directly to AuthScreen!
  Future<UserModel?> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      final userJson = prefs.getString(_userKey);

      if (token != null && userJson != null) {
        _currentUser = UserModel.fromJson(jsonDecode(userJson));
        return _currentUser;
      }
    } catch (_) {}

    _currentUser = null;
    return null;
  }

  /// Request OTP for phone number
  Future<String> sendPhoneOtp(String phone) async {
    // Simulates SMS gateway
    await Future.delayed(const Duration(milliseconds: 500));
    return '1234'; // Default simulation OTP code
  }

  /// Complete registration with Phone + OTP + Name + Referral Code
  Future<UserModel> registerWithOtp({
    required String phone,
    required String otp,
    required String fullName,
    String? referralCode,
  }) async {
    if (otp != '1234' && otp.length != 4 && otp.length != 6) {
      throw Exception('সঠিক ওটিপি কোড লিখুন (টেস্ট কোড: 1234)');
    }

    final cleanPhone = phone.trim().replaceAll(' ', '');

    final newUser = UserModel(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      fullName: fullName.isNotEmpty ? fullName : 'মোবাইল ব্যবহারকারী',
      phone: cleanPhone.startsWith('+') ? cleanPhone : '+880$cleanPhone',
      email: '$cleanPhone@service.com',
      role: 'user',
      isVerified: false, // Default is NOT verified until NID is provided!
      level: 'New',
      avgRating: 5.0,
      referralCode: 'REF${cleanPhone.length >= 4 ? cleanPhone.substring(cleanPhone.length - 4) : '99'}',
      walletBalance: (referralCode != null && referralCode.isNotEmpty) ? 200.0 : 100.0,
      token: 'jwt_token_${DateTime.now().millisecondsSinceEpoch}',
    );

    await _saveSession(newUser);
    return newUser;
  }

  /// Register with Email/Phone and Password
  Future<UserModel> register({
    required String fullName,
    required String phone,
    required String password,
    String? referralCode,
  }) async {
    final cleanPhone = phone.trim().replaceAll(' ', '');
    final newUser = UserModel(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      fullName: fullName.isNotEmpty ? fullName : 'নতুন ব্যবহারকারী',
      phone: cleanPhone.startsWith('+') ? cleanPhone : '+880$cleanPhone',
      email: '$cleanPhone@service.com',
      role: 'user',
      isVerified: false,
      level: 'New',
      avgRating: 5.0,
      referralCode: 'REF${cleanPhone.length >= 4 ? cleanPhone.substring(cleanPhone.length - 4) : '99'}',
      walletBalance: (referralCode != null && referralCode.isNotEmpty) ? 200.0 : 100.0,
      token: 'jwt_token_${DateTime.now().millisecondsSinceEpoch}',
    );

    await _saveSession(newUser);
    return newUser;
  }

  /// Verify OTP and Login
  Future<UserModel> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    if (otp != '1234' && otp.length != 4 && otp.length != 6) {
      throw Exception('সঠিক ওটিপি কোড দিন (টেস্ট ওটিপি: 1234)');
    }
    final cleanPhone = phone.trim().replaceAll(' ', '');
    final user = UserModel(
      id: 'usr_${cleanPhone.hashCode.abs()}',
      fullName: 'মোবাইল ব্যবহারকারী',
      phone: cleanPhone.startsWith('+') ? cleanPhone : '+880$cleanPhone',
      email: '$cleanPhone@service.com',
      role: 'user',
      isVerified: false,
      level: 'New',
      avgRating: 5.0,
      referralCode: 'OTP${cleanPhone.length >= 4 ? cleanPhone.substring(cleanPhone.length - 4) : '77'}',
      walletBalance: 100.0,
      token: 'jwt_token_${DateTime.now().millisecondsSinceEpoch}',
    );
    await _saveSession(user);
    return user;
  }

  /// Login with Phone/Email and Password
  Future<UserModel> login({
    required String identifier,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email_or_phone': identifier,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = UserModel.fromJson(data['user'] ?? data);
        await _saveSession(user);
        return user;
      }
    } catch (_) {}

    // Deterministic simulation
    final clean = identifier.trim();
    final simulatedUser = UserModel(
      id: 'usr_${clean.hashCode.abs()}',
      fullName: clean.contains('@') ? clean.split('@')[0] : 'তানভীর আহমেদ',
      phone: clean.startsWith('+') ? clean : '+880$clean',
      email: clean.contains('@') ? clean : '$clean@service.com',
      role: 'user',
      isVerified: false, // New session requires NID verify or keeps saved state
      level: 'Gold',
      avgRating: 4.8,
      referralCode: 'ARIF123',
      walletBalance: 100.0,
      token: 'jwt_${DateTime.now().millisecondsSinceEpoch}',
    );

    await _saveSession(simulatedUser);
    return simulatedUser;
  }

  /// Update verified status directly (for simulation / quick toggle)
  void setVerified(bool verified) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(isVerified: verified);
      _saveSession(_currentUser!);
    }
  }

  /// Submit NID & Face Verification (Module 1)
  Future<void> submitNidVerification({
    required String nidNumber,
    required String nidFrontImage,
    required String nidBackImage,
    required String selfieImage,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(isVerified: true);
      await _saveSession(_currentUser!);
    }
  }

  Future<void> _saveSession(UserModel user) async {
    _currentUser = user;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (user.token != null) {
        await prefs.setString(_tokenKey, user.token!);
      }
      await prefs.setString(_userKey, jsonEncode(user.toJson()));
    } catch (_) {}
  }

  Future<void> logout() async {
    _currentUser = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userKey);
    } catch (_) {}
  }
}
