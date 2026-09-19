import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';

class StorageService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static SharedPreferences get prefs {
    if (_prefs == null) throw Exception('StorageService not initialized');
    return _prefs!;
  }

  // Tokens
  static String? getToken() => prefs.getString(AppConstants.tokenKey);
  static Future<bool> setToken(String token) =>
      prefs.setString(AppConstants.tokenKey, token);
  static Future<bool> removeToken() => prefs.remove(AppConstants.tokenKey);

  static String? getRefreshToken() => prefs.getString('refresh_token');
  static Future<bool> setRefreshToken(String token) =>
      prefs.setString('refresh_token', token);
  static Future<bool> removeRefreshToken() => prefs.remove('refresh_token');

  // User data (stored as JSON)
  static Map<String, dynamic>? getUser() {
    final data = prefs.getString(AppConstants.userKey);
    if (data == null) return null;
    return jsonDecode(data) as Map<String, dynamic>;
  }

  static Future<bool> setUser(Map<String, dynamic> user) =>
      prefs.setString(AppConstants.userKey, jsonEncode(user));
  static Future<bool> removeUser() => prefs.remove(AppConstants.userKey);

  // Theme
  static String getThemeMode() =>
      prefs.getString(AppConstants.themeKey) ?? 'light';
  static Future<bool> setThemeMode(String mode) =>
      prefs.setString(AppConstants.themeKey, mode);

  // Locale
  static String getLocale() => prefs.getString(AppConstants.localeKey) ?? 'en';
  static Future<bool> setLocale(String locale) =>
      prefs.setString(AppConstants.localeKey, locale);

  // Clear all
  static Future<bool> clearAll() => prefs.clear();

  // Is logged in
  static bool isLoggedIn() {
    final token = getToken();
    return token != null && token.isNotEmpty;
  }

  // Offline Mode
  static bool isOfflineMode() => prefs.getBool('is_offline_mode') ?? false;
  static Future<bool> setOfflineMode(bool value) =>
      prefs.setBool('is_offline_mode', value);
}
