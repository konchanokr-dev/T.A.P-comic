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

Future<void> loadUserSettings() async{
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getInt('userId');
  if (userId != null) {
      final key = 'reader_mode_user_$userId';  
      final modeIndex = prefs.getInt(key) ?? 0;
      _readerMode = ReaderMode.values[modeIndex];
      notifyListeners();
    }
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
}
