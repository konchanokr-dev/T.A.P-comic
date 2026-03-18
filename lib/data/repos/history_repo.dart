import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tapcomic/data/api/api_service.dart';
import 'package:tapcomic/data/repos/comic_repo.dart';
import '../models/reading_history.dart';
class HistoryRepo {

Future<String?> _getCurrentUserUuid() async {
  final prefs = await SharedPreferences.getInstance();
  
  // ✅ return userUuid ไม่ใช่ token
  final userUuid = prefs.getString("userUuid");
  
  print("📋 userUuid = $userUuid"); // เช็คค่า
  return userUuid;
}
 Future<void> saveProgress({
  required String comicUuid,
  required int episodeId,
  required int pageNo,
}) async {
  final userUuid = await _getCurrentUserUuid();
  if (userUuid == null) {
    throw Exception("User not logged in");
  }

  final res = await ApiService.post(
    '/history/record',
    {
      "userUuid": userUuid,      
      "chapterId": episodeId,    
      "pageNumber": pageNo,
    },
  );
  

  if (res.statusCode != 200) {
    throw Exception('Failed to save history: ${res.body}');
  }
}
  Future<List<ReadingHistory>> getRecentHistory({int limit = 20}) async {
    final userUuid = await _getCurrentUserUuid();
    if (userUuid == null) return [];

   final res = await ApiService.get('/history/$userUuid');


    if (res.statusCode != 200) {
      throw Exception('Failed to load history: ${res.body}');
    }

    final List data = jsonDecode(res.body);
    return data
        .map((e) => ReadingHistory.fromApi(e))
        .take(limit)
        .toList();
  }

  Future<ReadingHistory?> getProgress(int episodeId) async {
    final userUuid = await _getCurrentUserUuid();
    if (userUuid == null) return null;

      final res = await ApiService.get('/history/$userUuid');


    if (res.statusCode != 200) return null;

    final List data = jsonDecode(res.body);

    try {
      final match = data.firstWhere(
        (e) => e['chapterId'] == episodeId,
      );
      return ReadingHistory.fromApi(match);
    } catch (_) {
      return null;
    }
  }
Future<ReadingHistory?> getComicProgress(String comicUuid) async {
  final userUuid = await _getCurrentUserUuid();
  if (userUuid == null) return null;

  try {
    final res = await ApiService.get('/history/$userUuid');

    if (res.statusCode != 200) return null;

    final List data = jsonDecode(res.body);
    
    // DEBUG: พิมพ์ดูว่า Server ส่งอะไรมากันแน่
    print("📡 ข้อมูลจาก Server: $data");

    // แก้ไขการเปรียบเทียบ โดยใช้ .toString() ป้องกันเรื่อง Type Mismatch
    final match = data.firstWhere(
      (e) => e['comicUuid'].toString() == comicUuid.toString(),
      orElse: () => null,
    );
    
    if (match != null) {
      print("🎯 เจอข้อมูลแล้ว! หน้าที่บันทึกไว้คือ: ${match['pageNumber']}");
      return ReadingHistory.fromApi(match);
    } else {
      print("🔎 ไม่พบประวัติของ Comic ID: $comicUuid");
      return null;
    }
  } catch (e) {
    print("❌ Error ใน getComicProgress: $e");
    return null;
  }
}
  Future<void> clearAllHistory() async {

    throw UnimplementedError('Server ยังไม่มี DELETE /api/history endpoint');
  }Future<List<ReadingHistory>> getRecentHistoryFull({int limit = 20}) async {
  final userUuid = await _getCurrentUserUuid();
  if (userUuid == null) return [];

    final historyRes = await ApiService.get('/history/$userUuid');



  if (historyRes.statusCode != 200) {
    throw Exception('Failed to load history');
  }

  final List historyData = jsonDecode(historyRes.body);
  final histories =
      historyData.map((e) => ReadingHistory.fromApi(e)).take(limit).toList();

 await Future.wait(histories.map((h) async {
  final comicRes = await ApiService.get('/comics/${h.comicUuid}');

  if (comicRes.statusCode == 200) {
    final comic = jsonDecode(comicRes.body);
    h.comicTitle = comic['title'];
    h.coverPath = comic['coverUrl'];
  }
}));

  return histories;
}
}
