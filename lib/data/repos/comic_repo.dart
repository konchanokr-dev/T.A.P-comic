import 'dart:convert';
import 'package:tapcomic/data/models/user.dart';

import '../models/comic.dart';
import '../api/api_service.dart';
import 'package:http/http.dart' as http;

final client = ApiService.client;
class ComicRepo {
final String baseUrl = ApiService.baseUrl;
  Future<List<Comic>> fetchNewChapters({int limit = 20}) async {
    final response = await ApiService.get('/comics'
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to load comics");
    }

    final List data = jsonDecode(response.body);

    return data
        .map((e) => Comic.fromMap(e))
        .toList();
  }

Future<Map<String, dynamic>?> fetchComicDetailByUuId(String comicId) async {
  final response = await ApiService.get('/comics/$comicId');

  if (response.statusCode != 200) {
    throw Exception("Failed to load comic detail");
  }

  return jsonDecode(response.body);
}
  Future<List<Comic>> fetchComicDetailByTitle(String title) async {
    final response = await ApiService.get('/comics?search=$title'  );

    if (response.statusCode != 200) {
      throw Exception("Search failed");
    }

    final List data = jsonDecode(response.body);

    return data
        .map((e) => Comic.fromMap(e))
        .toList();
  }
   Future<List<Comic>> fetchAllComics() async {
    final response = await ApiService.get('/comics');

    if (response.statusCode != 200) {
      throw Exception("Search failed");
    }

    final List data = jsonDecode(response.body);

    return data
        .map((e) => Comic.fromMap(e))
        .toList();
  }
  Future<List<dynamic>> fetchChapters(String comicUuid) async {
  final response = await ApiService.get('/comics/$comicUuid/chapter');

  if (response.statusCode != 200) {
    throw Exception("Failed to load chapters");
  }

  final List data = jsonDecode(response.body);
  return data;
}
Future<List<Comic>> searchComic(String keyword) async {

    final response = await ApiService.post(
      "/comics/search?page=0",
      {"keyword": keyword}
    );

    if (response.statusCode == 200) {

      final data = jsonDecode(response.body);

      List list = data["content"];

      return list.map((e) => Comic.fromMap(e)).toList();

    } else {
      throw Exception("Search failed");
    }
  }
}


