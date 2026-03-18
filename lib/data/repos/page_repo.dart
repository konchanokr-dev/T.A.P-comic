import 'dart:convert';
import 'package:tapcomic/data/api/api_service.dart';
import '../models/page_model.dart';

class PageRepo {

  Future<List<PageModel>> fetchPages({
    required String uuid,
    required int chapterNo,
  }) async {

    final response = await ApiService.get('/comics/$uuid/$chapterNo');

    if (response.statusCode == 200) {

      List data = json.decode(response.body);

      return data
          .map((e) => PageModel.fromJson(e))
          .toList();

    } else {
      throw Exception("Failed to load pages");
    }
  }

  Future<int> getPageCount({
    required String uuid,
    required int chapter,
  }) async {

    final res = await ApiService.get('/comics/$uuid/chapter');

    final chapterData = jsonDecode(res.body);

    return chapterData
        .firstWhere((c) => c['count'] == chapter)['pageCount'];
  }
}