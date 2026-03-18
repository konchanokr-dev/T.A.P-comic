import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tapcomic/data/api/api_service.dart';
import '../models/user.dart';

import '../../core/utils/password_helper.dart';

class UserRepo {

  Future<void> register(String name, String password) async {
    final allUsers = await _fetchAllUsers();
    final exists = allUsers.any((u) => u.name == name);
    if (exists) throw Exception('Username already exists');

    final res = await http.post(
      Uri.parse('${ApiService.baseUrl}/users'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'password': password, 
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('Register failed: ${res.body}');
    }

    final updatedUsers = await _fetchAllUsers();
    final newUser = updatedUsers.firstWhere(
      (u) => u.name == name,
      orElse: () => throw Exception('User not found after register'),
    );

    await _saveLocalCredential(
      uuid: newUser.uuid,
      name: name,
      passwordHash: PasswordHelper.hashPassword(password),
    );
  }

Future<User?> login(String name, String password) async {

  final res = await http.post(
    Uri.parse('${ApiService.baseUrl}/auth/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'name': name,
      'password': password,
    }),
  );

  print("STATUS: ${res.statusCode}");
  print("BODY: ${res.body}");

  if (res.statusCode != 200) return null;

  final data = jsonDecode(res.body);

  final prefs = await SharedPreferences.getInstance();

  // เก็บ token
  await prefs.setString("accessToken", data["accessToken"]);
  await prefs.setString("refreshToken", data["refreshToken"]);

  // โค้ดเก่ายังใช้เหมือนเดิม
  final users = await _fetchAllUsers();
  final user = users.firstWhere((u) => u.name == name);

  await _saveSession(user);

  return user;
}

Future<void> logout() async {
  final prefs = await SharedPreferences.getInstance();

  await prefs.remove('userUuid');
  await prefs.remove('userName');
  await prefs.remove('userId');

  await prefs.remove('accessToken');
  await prefs.remove('refreshToken');
}
  Future<List<User>> _fetchAllUsers() async {
    final res = await http.get(
      Uri.parse('${ApiService.baseUrl}/users'),
    );
    if (res.statusCode != 200) throw Exception('Failed to fetch users');
    final List data = jsonDecode(res.body);
    return data.map((e) => User.fromApi(e)).toList();
  }

  Future<void> _saveSession(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userUuid', user.uuid);
    await prefs.setString('userName', user.name);
    if (user.id != null) await prefs.setInt('userId', user.id!);
  }

  Future<void> _saveLocalCredential({
    required String uuid,
    required String name,
    required String passwordHash,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pw_$uuid', passwordHash); 
  }
Future<List<User>> searchUser(String keyword) async {
  final res = await http.post(
    Uri.parse('${ApiService.baseUrl}/users/search?page=0'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'keyword': keyword,
    }),
  );

  print("STATUS: ${res.statusCode}");
  print("BODY: ${res.body}");

  if (res.statusCode != 200) {
    throw Exception("User search failed");
  }

  final data = jsonDecode(res.body);

  List list = data["content"];

  return list.map((e) => User.fromApi(e)).toList();
}
}
  