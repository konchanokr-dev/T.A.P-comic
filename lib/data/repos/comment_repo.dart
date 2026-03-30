import 'dart:convert';
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
  int? pageId,
}) async {

  final body = {
    "userUuid": userUuid,
    "comicId": comicId,
    "chapterId": chapterId,
    "pageId": pageId,
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
Future<List<CommentModel>> getComicComments(int comicId) async {
  final res = await ApiService.get("/comments/comic/$comicId");
  final List data = jsonDecode(res.body);
  return data.map((e) => CommentModel.fromJson(e)).toList();
}

Future<List<CommentModel>> getPageComments(int pageId) async {
  final res = await ApiService.get("/comments/page/$pageId");
  final List data = jsonDecode(res.body);
  return data.map((e) => CommentModel.fromJson(e)).toList();
}
// Comic level
Future<void> addComicComment({
  required String userUuid,
  required int comicId,
  required String text,
}) async {
  final res = await ApiService.post("/comments/add/comment", {
    "userUuid": userUuid,
    "comicId": comicId,
    "text": text,
  });
  if (res.statusCode != 200) throw Exception("Failed to send comment");
}

// Chapter level
Future<void> addChapterComment({
  required String userUuid,
  required int comicId,
  required int chapterId,
  required String text,
}) async {
  final res = await ApiService.post("/comments/add/comment", {
    "userUuid": userUuid,
    "comicId": comicId,
    "chapterId": chapterId,
    "text": text,
  });
  if (res.statusCode != 200) throw Exception("Failed to send comment");
}

// Page level
Future<void> addPageComment({
  required String userUuid,
  required int comicId,
  required int pageId,
  required String text,
}) async {
  final res = await ApiService.post("/comments/add/comment", {
    "userUuid": userUuid,
    "comicId": comicId,
    "pageId": pageId,
    "text": text,
  });
  if (res.statusCode != 200) throw Exception("Failed to send comment");
}
}