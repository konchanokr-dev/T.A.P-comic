import 'dart:convert';

import 'package:flutter/rendering.dart';
import 'package:tapcomic/data/api/api_service.dart';
class VoteRepo {
  Future<void> voteChapter(int chapterId, bool vote) async {
    final response = await ApiService.post(
      "/vote/chapter/$chapterId?vote=$vote",
      {},
    );
    debugPrint("Vote Response: ${response.statusCode} - ${response.body}");
    if (response.statusCode != 200) {
      throw Exception("vote fail");
    }
    
  }
  Future<Map<String, dynamic>> getChapterVotes(int chapterId, {Map<String, String>? headers}) async {
    final response = await ApiService.get("/vote/chapter/$chapterId/status",);
    
    debugPrint("GET /vote/chapter/$chapterId/status -> status: ${response.statusCode}");
    debugPrint("Response headers: ${response.headers}");
    debugPrint("Response body: ${response.body}");

    if (response.statusCode == 200) {
      try {
        final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
        return data;
      } catch (e) {
        // ถ้า body เป็น empty string หรือไม่ได้เป็น JSON
        debugPrint("Failed to decode vote response body: $e");
        throw Exception("Invalid response format from server");
      }
    } else {
      // ส่ง response.body กลับในข้อความ error เพื่อช่วยดีบัก
      throw Exception("Failed to load chapter votes: ${response.statusCode} - ${response.body}");
    }
  }

}