import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tapcomic/data/api/api_service.dart';
import 'package:tapcomic/data/models/comment.dart';
class CommentRepo {
  final String baseUrl = ApiService.baseUrl;

  Future<List<CommentModel>> getChapterComments(int chapterId) async {

   final res = await ApiService.get("/comments/chapter/$chapterId");


    final List data = jsonDecode(res.body);

    return data.map((e) => CommentModel.fromJson(e)).toList();
  }Future<void> addComment({
  required String userUuid,
  required int comicId,
  required int chapterId,
  required String text,
}) async {

  final body = {
    "userUuid": userUuid,
    "comicId": comicId,
    "chapterId": chapterId,
    "text": text,
  };

  final res = await ApiService.post(
    "/comments/add/comment",
    body,
  );

  print("STATUS: ${res.statusCode}");
  print("RESPONSE: ${res.body}");

  if (res.statusCode != 200) {
    throw Exception("Failed to send comment");
  }
}Future<void> addReply({
  required String userUuid,
  required int commentId,
  required String text,
}) async {

  final res = await ApiService.post(
    "/comments/add/reply",
    {
      "uuid": userUuid,
      "commentId": commentId,
      "text": text,
    },
  );

  if (res.statusCode != 200) {
    throw Exception("Failed to send reply");
  }
}

}