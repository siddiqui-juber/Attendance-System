import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  bool _isLoading = false;
  String _errorMessage = '';
  UserProfile? _userProfile;

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  UserProfile? get userProfile => _userProfile;
  bool get isAuthenticated => _userProfile != null;
  bool get isAdmin => _userProfile?.role == 'ADMIN';

  AuthProvider() {
    tryLoginFromStorage();
  }

  Future<void> tryLoginFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';
    final profileStr = prefs.getString('user_profile') ?? '';

    if (token.isNotEmpty && profileStr.isNotEmpty) {
      try {
        _userProfile = UserProfile.fromJson(jsonDecode(profileStr));
        notifyListeners();
      } catch (e) {
        logout();
      }
    }
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final response = await _api.post('/api/auth/login', {
        'username': username,
        'password': password,
      });

      _isLoading = false;
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final token = data['token'];

        _userProfile = UserProfile.fromJson(data);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);
        await prefs.setString('user_profile', jsonEncode(data));

        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Invalid username or password';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Connection failed. Check your network or server.';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _userProfile = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_profile');
    notifyListeners();
  }
}
