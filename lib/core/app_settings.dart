import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
enum ReaderMode {
  vertical,
  horizontal,
  tap,
}

class AppSettings extends ChangeNotifier {
  ReaderMode _readerMode = ReaderMode.vertical;
    ReaderMode get readerMode => _readerMode;
ThemeMode _themeMode = ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;
Future<void> loadUserSettings() async {
  final prefs = await SharedPreferences.getInstance();
  
  // ✅ เพิ่มตรงนี้ — โหลด theme
  final isDark = prefs.getBool('isDarkMode') ?? true;
  _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;

  final userId = prefs.getInt('userId');
  if (userId != null) {
    final key = 'reader_mode_user_$userId';
    final modeIndex = prefs.getInt(key) ?? 0;
    _readerMode = ReaderMode.values[modeIndex];
  }

  notifyListeners(); // ย้ายมาตรงนี้ที่เดียวพอ
}
  Future<void> setReaderMode(ReaderMode? mode) async {
    if (mode == null) return;
    
    _readerMode = mode;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    
    if (userId != null) {
      final key = 'reader_mode_user_$userId';
      await prefs.setInt(key, mode.index);
    }
  }

Future<void> toggleTheme() async {
  final isDark = _themeMode == ThemeMode.dark;
  _themeMode = isDark ? ThemeMode.light : ThemeMode.dark;
  notifyListeners(); // 👈 เรียกทันทีก่อน await — UI เปลี่ยนเลย

  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('isDarkMode', !isDark); // save ทีหลังได้
}
}
