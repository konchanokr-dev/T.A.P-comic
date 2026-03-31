import 'package:tapcomic/data/models/userm.dart';

class CommentModel {
  final int id;
  final String text;
  final UserModel user;
  int likeCount;
 int dislikeCount;
 bool? currentUserVote;
final List<ReplyModel> replies; 
final String createAt;
  CommentModel({
    required this.id,
    required this.text,
    required this.user,
    required this.replies,
    required this.likeCount,
    required this.dislikeCount,
    required this.createAt,
    this.currentUserVote,

  });

factory CommentModel.fromJson(Map<String, dynamic> json) {
  return CommentModel(
    id: json["id"] ?? 0,
    text: json["text"] ?? "",
    user: UserModel.fromJson(json["user"]),
    likeCount: json["likeCount"] ?? 0,
    dislikeCount: json["dislikeCount"] ?? 0,
    currentUserVote: json["currentUserVote"],
    createAt: json["createAt"] ?? "",
    replies: json["replies"] == null
        ? []
        : List<ReplyModel>.from(
            (json["replies"] as List).map((e) => ReplyModel.fromJson(e)),
          ),
  );
}
}
  

class ReplyModel {
  final int id;
  final String text;
  final UserModel user;
  final String createAt;
  final int mainCommentId;
  final int likeCount;        // เพิ่ม
  final int dislikeCount;     // เพิ่ม
  final bool? currentUserVote; // เพิ่ม

  ReplyModel({
    required this.id,
    required this.text,
    required this.user,
    required this.createAt,
    required this.mainCommentId,
    required this.likeCount,
    required this.dislikeCount,
    this.currentUserVote,
  });

  factory ReplyModel.fromJson(Map<String, dynamic> json) {
    return ReplyModel(
      id: json["id"] ?? 0,
      text: json["text"] ?? "",
      user: UserModel.fromJson(json["user"]),
      createAt: json["createAt"] ?? "",
      mainCommentId: json["mainCommentId"] ?? 0,
      likeCount: json["likeCount"] ?? 0,
      dislikeCount: json["dislikeCount"] ?? 0,
      currentUserVote: json["currentUserVote"],
    );
  }
}


