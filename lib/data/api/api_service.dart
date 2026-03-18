import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/comic.dart';

class ApiService {
  static const baseUrl = "https://xacetx123.share.zrok.io/api";

  static final http.Client client = http.Client();

  static Future<Map<String,String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("accessToken");

    return {
      "Content-Type": "application/json",
      if(token != null) "Authorization": "Bearer $token"
    };
  }

  static Future<http.Response> get(String path) async {
    final headers = await _headers();

    return http.get(
      Uri.parse("$baseUrl$path"),
      headers: headers,
    );
  }

  static Future<http.Response> post(String path, dynamic body) async {
    final headers = await _headers();

    return http.post(
      Uri.parse("$baseUrl$path"),
      headers: headers,
      body: jsonEncode(body),
    );
  }

  Future<List<Comic>> fetchComics() async {

    final response = await ApiService.get("/comics");

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Comic.fromMap(e)).toList();
    } else {
      throw Exception("Failed to load comics");
    }
  }
}