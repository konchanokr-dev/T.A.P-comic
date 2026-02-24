import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tapcomic/data/api/api_service.dart';
import '../models/page_model.dart';
class PageRepo {
  final String baseUrl = ApiService.baseUrl;
Future<List<PageModel>> fetchPages({
  required String uuid,
  required int chapter,
}) async {
  // 1. โหลดข้อมูล Chapter ครั้งเดียวเพื่อเอา pageCount
  final chapterRes = await http.get(Uri.parse('$baseUrl/comics/$uuid/chapter'));
  if (chapterRes.statusCode != 200) throw Exception("Failed");

  final List chapterData = jsonDecode(chapterRes.body);
  final chapterInfo = chapterData.firstWhere((c) => c['count'] == chapter);
  final int pageCount = chapterInfo['pageCount'];

  // 2. สร้างรายการของ Future (ยังไม่เริ่มโหลดทันที)
  List<Future<http.Response>> requests = [];
  for (int i = 1; i <= pageCount; i++) {
    requests.add(http.get(Uri.parse('$baseUrl/comics/$uuid/$chapter/$i')));
  }

  // 3. ยิงกระสุนออกไปพร้อมกัน! (Concurrent)
  // วิธีนี้จะเร็วกว่าเดิมหลายเท่าตัว
  final responses = await Future.wait(requests);

  // 4. แปลงข้อมูลกลับเป็น Model
  List<PageModel> pages = [];
  for (var res in responses) {
    if (res.statusCode == 200) {
      pages.add(PageModel.fromMap(jsonDecode(res.body)));
    }
  }

  return pages;
}

  /// โหลดแค่หน้าแรก
  Future<List<PageModel>> fetchFirstPage({
    required String uuid,
    required int chapter,
  }) async {
    final res = await http.get(
      Uri.parse('$baseUrl/comics/$uuid/$chapter/1'),
    );

    if (res.statusCode != 200) return [];

    final data = jsonDecode(res.body);

    return [PageModel.fromMap(data)];
  }

  Future<int> getPageCount({
  required String uuid,
  required int chapter,
}) async {
  final res = await http.get(
    Uri.parse('$baseUrl/comics/$uuid/chapter'),
  );

  final chapterData = jsonDecode(res.body);

  return chapterData
      .firstWhere((c) => c['count'] == chapter)['pageCount'];
} 
}