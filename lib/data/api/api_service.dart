import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/comic.dart';

class ApiService {
  static const  baseUrl = "https://bj7oa2qw9ly4.share.zrok.io/api";

  Future<List<Comic>> fetchComics() async {
    final response = await http.get(
      Uri.parse("$baseUrl/comics"),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Comic.fromMap(e)).toList();
    } else {
      throw Exception("Failed to load comics");
    }
  }
}
