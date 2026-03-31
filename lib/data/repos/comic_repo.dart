import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tapcomic/data/models/genre.dart';
import '../models/comic.dart';
import '../api/api_service.dart';

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
  Future<List<Comic>> fetchNew({int limit = 20}) async {
  final response = await ApiService.get('/comics/recent');

  if (response.statusCode != 200) {
    throw Exception("Failed to load comics");
  }

  final json = jsonDecode(response.body);

  final List data = json["content"]; 

  return data
      .map((e) => Comic.fromMap(e))
      .toList();
}
 Future<List<Comic>> fetchPopular({int limit = 20}) async {
  final response = await ApiService.get('/comics/popular');

  if (response.statusCode != 200) {
    throw Exception("Failed to load comics");
  }

  final json = jsonDecode(response.body);

  final List data = json["content"]; 

  return data
      .map((e) => Comic.fromMap(e))
      .toList();
}
Future<Map<String, dynamic>?> fetchComicDetailByUuId(String comicId) async {
  final response = await ApiService.get('/comics/$comicId');
  if (response.statusCode != 200) {
    throw Exception("Failed to load comic detail");
  }
  print(response.body);
  return jsonDecode(response.body);
}

Future<Comic?> fetchComicDetailByUuIdC(String comicId) async {
  final response = await ApiService.get('/comics/$comicId');

  if (response.statusCode != 200) {
    throw Exception("Failed to load comic detail");
  }

  return Comic.fromMap(jsonDecode(response.body));
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
  debugPrint(response.body);

  if (response.statusCode != 200) {
    throw Exception("Failed to load chapters");
  }

  final List data = jsonDecode(response.body);
  return data;
}
Future<List<Comic>> searchComic(String keyword) async {
  final response = await ApiService.get(
    "/comics/search?keyword=$keyword&page=0",
  );
debugPrint('🔍 search status: ${response.statusCode}');
  debugPrint('🔍 search body: ${response.body}');
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    List list = data["content"];
    return list.map((e) => Comic.fromMap(e)).toList();
  } else {
    throw Exception("Search failed");
  }
}
Future<List<Genre>> getGenres() async {
  final res = await ApiService.get('/genres');
  if (res.statusCode != 200) throw Exception('Failed to load genres');
  final List data = jsonDecode(res.body);
  return data.map((e) => Genre.fromJson(e)).toList();
}

Future<List<Comic>> filterByGenre(Set<int> genreIds) async {
  final ids = genreIds.join(',');
  final res = await ApiService.get('/comics/filter?genreIds=$ids&page=0');
  if (res.statusCode != 200) throw Exception('Filter failed');
  final data = jsonDecode(res.body);
  return (data['content'] as List).map((e) => Comic.fromMap(e)).toList();
}
Future<List<Comic>> fetchFollowing() async {
  final prefs = await SharedPreferences.getInstance();
  final uuid = prefs.getString('userUuid') ?? '';
  final res = await ApiService.get("/users/$uuid/library");
  if (res.statusCode == 200) {
    final data = jsonDecode(res.body);
    final list = data['comicDTO'] as List;
    print(data);
    return list.map((e) => Comic.fromMap(e)).toList();
  }
  throw Exception("Failed to load library");
}
}


