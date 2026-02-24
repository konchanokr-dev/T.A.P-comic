import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/comic.dart';
import '../api/api_service.dart';

class ComicRepo {
final String baseUrl = ApiService.baseUrl;
  Future<List<Comic>> fetchNewChapters({int limit = 20}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/comics'),
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
  final response = await http.get(
    Uri.parse('$baseUrl/comics/$comicId'),
  );

  if (response.statusCode != 200) {
    throw Exception("Failed to load comic detail");
  }

  return jsonDecode(response.body);
}
  Future<List<Comic>> fetchComicDetailByTitle(String title) async {
    final response = await http.get(
      Uri.parse('$baseUrl/comics?search=$title'),
    );

    if (response.statusCode != 200) {
      throw Exception("Search failed");
    }

    final List data = jsonDecode(response.body);

    return data
        .map((e) => Comic.fromMap(e))
        .toList();
  }
   Future<List<Comic>> fetchAllComics() async {
    final response = await http.get(
      Uri.parse('$baseUrl/comics'),
    );

    if (response.statusCode != 200) {
      throw Exception("Search failed");
    }

    final List data = jsonDecode(response.body);

    return data
        .map((e) => Comic.fromMap(e))
        .toList();
  }
}
