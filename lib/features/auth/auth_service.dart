import 'package:shared_preferences/shared_preferences.dart';
class AuthService {
  static String? _token;
  static String? _userUuid; 

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString("accessToken");
    _userUuid = prefs.getString("userUuid"); 
  }

  static String? get token => _token;
  static String? get userUuid => _userUuid; 

  static Future<void> setToken(String newToken, String uuid) async {
    _token = newToken;
    _userUuid = uuid;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("accessToken", newToken);
    await prefs.setString("userUuid", uuid);
  }

  static Future<void> clear() async {
    _token = null;
    _userUuid = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("accessToken");
    await prefs.remove("userUuid");
  }}