import 'package:tapcomic/data/models/episode.dart';
import '../db/app_db2.dart';
class EpisodeRepo {
  Future<List<Episode>> fetchByComicId(int comicId) async{
    final db = await AppDb.database;
    final rows = await db.query(
      'episode',
      where: 'comic_id = ?',
      whereArgs: [comicId],
      orderBy: 'ep_no DESC',
    );
    return rows.map((m) => Episode.fromMap(m)).toList();

  }
   Future<Episode?> getNextEpisode(int comicId, int currentEpNo) async {
    final db = await AppDb.database;
    
    final rows = await db.query(
      'episode',
      where: 'comic_id = ? AND ep_no > ?',
      whereArgs: [comicId, currentEpNo],
      orderBy: 'ep_no ASC', 
      limit: 1,
    );
    
    if (rows.isEmpty) return null;
    return Episode.fromMap(rows.first);
  }
  
  Future<Episode?> getPreviousEpisode(int comicId, int currentEpNo) async {
    final db = await AppDb.database;
    
    final rows = await db.query(
      'episode',
      where: 'comic_id = ? AND ep_no < ?',
      whereArgs: [comicId, currentEpNo],
      orderBy: 'ep_no DESC', 
      limit: 1,
    );
    
    if (rows.isEmpty) return null;
    return Episode.fromMap(rows.first);
  }
  
  Future<Episode?> getById(int episodeId) async {
    final db = await AppDb.database;
    
    final rows = await db.query(
      'episode',
      where: 'id = ?',
      whereArgs: [episodeId],
      limit: 1,
    );
    
    if (rows.isEmpty) return null;
    return Episode.fromMap(rows.first);
  }
}
