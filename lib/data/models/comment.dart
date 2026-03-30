import 'package:tapcomic/data/models/userm.dart';

class CommentModel {
  final int id;
  final String text;
  final UserModel user;
final List<ReplyModel> replies; 
  CommentModel({
    required this.id,
    required this.text,
    required this.user,
    required this.replies,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json["id"],
      text: json["text"],
      user: UserModel.fromJson(json["user"]),
      replies: List<ReplyModel>.from(
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

  ReplyModel({
    required this.id,
    required this.text,
    required this.user,
    required this.createAt,
    required this.mainCommentId,
  });

  factory ReplyModel.fromJson(Map<String,dynamic> json){
    return ReplyModel(
      id: json["id"],
      text: json["text"],
      user: UserModel.fromJson(json["user"]),
      createAt: json["createAt"],
      mainCommentId: json["mainCommentId"],
    );
  }
}

