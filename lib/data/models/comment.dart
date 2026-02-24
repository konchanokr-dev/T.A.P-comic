class Comment {
  final int? id;
  final int comicId;
  final int episodeId;
  final String message;
  final int likeCount;
    final int userId;           
  final int dislikeCount;
  final String createdAt;
  final String? username;

  const Comment({
     this.id,
     required this.userId,
    required this.comicId,
    required this.episodeId,
    required this.message,
    required this.likeCount,
    required this.dislikeCount,
    required this.createdAt,
        this.username,            

  });

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      id: map['id'] as int,
      userId: map['user_id'] as int,
      comicId: map['comic_id'] as int,
      episodeId: map['episode_id'] as int,
      message: map['message'] as String,
      likeCount: map['like_count'] as int,
      dislikeCount: map['dislike_count'] as int,
      createdAt: map['created_at'] as String,
      username: map['username'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'comic_id': comicId,
      'episode_id': episodeId,
      'user_id': userId,  
      'message': message,
      'like_count': likeCount,
      'dislike_count': dislikeCount,
      'created_at': createdAt,
    };
  }
}
