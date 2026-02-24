import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';  
import '../models/comment.dart';
import '../db/app_db2.dart';

class CommentRepo {
  Future<int?> _getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userId');
  }
  
  Future<List<Comment>> getComments(int episodeId) async {
    final db = await AppDb.database;

    final result = await db.rawQuery('''
      SELECT 
        c.*,
        u.username
      FROM comments c
      LEFT JOIN users u ON u.id = c.user_id
      WHERE c.episode_id = ?
      ORDER BY c.created_at DESC
    ''', [episodeId]);

    return result.map((e) => Comment.fromMap(e)).toList();
  }

 
  Future<void> insertComment(Comment comment) async {
    final userId = await _getCurrentUserId();
    if (userId == null) throw Exception('User not logged in');
    
    final db = await AppDb.database;

    await db.insert(
      "comments",
      {
        "comic_id": comment.comicId,
        "episode_id": comment.episodeId,
        "user_id": userId,              
        "message": comment.message,
        "like_count": comment.likeCount,
        "dislike_count": comment.dislikeCount,
        "created_at": comment.createdAt,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

 
  Future<void> deleteComment(int commentId) async {
    final userId = await _getCurrentUserId();
    if (userId == null) throw Exception('User not logged in');
    
    final db = await AppDb.database;
    
    await db.delete(
      "comments",
      where: "id = ? AND user_id = ?", 
      whereArgs: [commentId, userId],
    );
  }
  
  Future<void> updateComment(int commentId, String newMessage) async {
    final userId = await _getCurrentUserId();
    if (userId == null) throw Exception('User not logged in');
    
    final db = await AppDb.database;
    
    await db.update(
      "comments",
      {"message": newMessage},
      where: "id = ? AND user_id = ?",  
      whereArgs: [commentId, userId],
    );
  }

  Future<void> increaseLike(int id) async {
    final db = await AppDb.database;
    await db.rawUpdate(
      "UPDATE comments SET like_count = like_count + 1 WHERE id = ?",
      [id],
    );
  }

  Future<void> decreaseLike(int id) async {
    final db = await AppDb.database;
    await db.rawUpdate(
      """
      UPDATE comments
      SET like_count = CASE
        WHEN like_count > 0 THEN like_count - 1
        ELSE 0
      END
      WHERE id = ?
      """,
      [id],
    );
  }

  Future<void> increaseDislike(int id) async {
    final db = await AppDb.database;
    await db.rawUpdate(
      "UPDATE comments SET dislike_count = dislike_count + 1 WHERE id = ?",
      [id],
    );
  }

  Future<void> decreaseDislike(int id) async {
    final db = await AppDb.database;
    await db.rawUpdate(
      """
      UPDATE comments
      SET dislike_count = CASE
        WHEN dislike_count > 0 THEN dislike_count - 1
        ELSE 0
      END
      WHERE id = ?
      """,
      [id],
    );
  }
}