import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tapcomic/data/api/api_service.dart';
import '../models/reading_history.dart';
class HistoryRepo {

  Future<String?> _getCurrentUserUuid() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userUuid');
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

  final res = await http.post(
    Uri.parse('${ApiService.baseUrl}/history/record'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      "userUuid": userUuid,      
      "comicUuid": comicUuid,
      "chapterId": episodeId,    
      "pageNumber": pageNo,
    }),
  );

  if (res.statusCode != 200) {
    throw Exception('Failed to save history: ${res.body}');
  }
}
  Future<List<ReadingHistory>> getRecentHistory({int limit = 20}) async {
    final userUuid = await _getCurrentUserUuid();
    if (userUuid == null) return [];

    final res = await http.get(
      Uri.parse('${ApiService.baseUrl}/history/$userUuid'),
    );

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

    final res = await http.get(
      Uri.parse('${ApiService.baseUrl}/history/$userUuid'),
    );

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

  Future<ReadingHistory?> getComicProgress(String uuid) async {
    final userUuid = await _getCurrentUserUuid();
    if (userUuid == null) return null;

    final res = await http.get(
      Uri.parse('${ApiService.baseUrl}/history/$userUuid'),
    );

    if (res.statusCode != 200) return null;

    final List data = jsonDecode(res.body);

    try {
      final matches = data.where((e) => e['comicUuid'] == uuid).toList();
      if (matches.isEmpty) return null;
      return ReadingHistory.fromApi(matches.first);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearAllHistory() async {

    throw UnimplementedError('Server ยังไม่มี DELETE /api/history endpoint');
  }Future<List<ReadingHistory>> getRecentHistoryFull({int limit = 20}) async {
  final userUuid = await _getCurrentUserUuid();
  if (userUuid == null) return [];

  final historyRes = await http.get(
    Uri.parse('${ApiService.baseUrl}/history/$userUuid'),
  );

  if (historyRes.statusCode != 200) {
    throw Exception('Failed to load history');
  }

  final List historyData = jsonDecode(historyRes.body);
  final histories =
      historyData.map((e) => ReadingHistory.fromApi(e)).take(limit).toList();

  for (var h in histories) {
    final comicRes = await http.get(
      Uri.parse('${ApiService.baseUrl}/comics/${h.comicId}'),
    );

    if (comicRes.statusCode == 200) {
      final comic = jsonDecode(comicRes.body);
      h.comicTitle = comic['title'];
      h.coverPath = comic['coverUrl'];
    }
  }

  return histories;
}
}
