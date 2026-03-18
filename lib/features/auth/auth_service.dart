import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static String? _token;

  /// โหลดครั้งเดียวตอนเปิดแอป
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString("accessToken");
  }

  /// ใช้เรียก token จากทุกที่
  static String? get token => _token;

  /// ตอน login
  static Future<void> setToken(String newToken) async {
    _token = newToken;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("accessToken", newToken);
  }

  /// logout
  static Future<void> clear() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("accessToken");
  }
}