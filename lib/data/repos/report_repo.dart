import 'dart:convert';
import 'package:http/http.dart' as http;
import '../api/api_service.dart';

class ReportRepo {

  Future<void> reportComment({
    required String uuid,
    required int commentId,
    required String reason,
  }) async {

    final url = Uri.parse("${ApiService.baseUrl}/report");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "uuid": uuid,
        "commentId": commentId,
        "reason": reason,
      }),
    );
print("STATUS: ${response.statusCode}");
print("BODY: ${response.body}");

    if (response.statusCode != 200) {
      throw Exception("report failed");
    }
  }
  
}