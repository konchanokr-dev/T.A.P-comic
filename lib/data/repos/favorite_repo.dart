import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tapcomic/data/api/api_service.dart';
import 'package:tapcomic/data/models/favorite_comic.dart';

class FavoriteRepo {
  Future<String> _getCurrentUserUuid() async {
    final prefs = await SharedPreferences.getInstance();
    final uuid = prefs.getString('userUuid');

    if (uuid == null) {
      throw Exception("User not logged in");
    }

    return uuid;
  }

  Future<void> toggle(String comicUuid) async {
    final userUuid = await _getCurrentUserUuid();

    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/users/follow'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'userUuid': userUuid,
        'comicUuid': comicUuid,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Favorite failed");
    }
  }
  Future<List<FavoriteComic>> getAll() async {
  final userUuid = await _getCurrentUserUuid();

  final response = await http.get(
    Uri.parse('${ApiService.baseUrl}/users/$userUuid/library'),
  );

  if (response.statusCode != 200) {
    throw Exception("Failed to load user");
  }

  final Map<String, dynamic> user =
      jsonDecode(response.body);

  final List followed = user['comicDTO'] ?? [];

  return followed
      .map((e) => FavoriteComic.fromMap(e))
      .toList();
}
}

