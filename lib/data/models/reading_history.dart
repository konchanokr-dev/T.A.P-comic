// lib/data/models/reading_history.dart
class ReadingHistory {
  final int? id;
  final String? userUuid;     // ← เพิ่ม (server ใช้ uuid)
  final String comicId;
  final int episodeId;
  final int pageNo;
  final String lastReadAt;

  // join data (แสดงใน UI)
  String? comicTitle;
   String? coverPath;
  final int? episodeNo;
  final String? episodeTitle;
  final int? totalPages;

  ReadingHistory({
    this.id,
    this.userUuid,
    required this.comicId,
    required this.episodeId,
    required this.pageNo,
    required this.lastReadAt,
    this.comicTitle,
    this.coverPath,
    this.episodeNo,
    this.episodeTitle,
    this.totalPages,
  });

  // รับจาก server API
factory ReadingHistory.fromApi(Map<String, dynamic> map) {
  return ReadingHistory(
    id: (map['id'] as num?)?.toInt(),
    userUuid: map['userUuid'] as String?,

    comicId: map['comicId']! as String? ?? '',

    // 🔥 backend ใช้ chapterId ไม่ใช่ episodeId
    episodeId: (map['chapterId'] as num?)?.toInt() ?? 0,

    // 🔥 backend ใช้ pageNumber ไม่ใช่ pageNo
    pageNo: (map['pageNumber'] as num?)?.toInt() ?? 0,

    lastReadAt: map['lastReadAt'] as String? ?? '',

    comicTitle: map['comicTitle'] as String?,
    coverPath: map['coverPath'] as String?,
    episodeNo: (map['chapterId'] as num?)?.toInt(),
    episodeTitle: map['episodeTitle'] as String?,
    totalPages: (map['totalPages'] as num?)?.toInt(),
  );
}
  // ยังคงไว้สำหรับ local SQLite (ถ้ายังใช้อยู่)
  factory ReadingHistory.fromMap(Map<String, dynamic> map) {
    return ReadingHistory(
      id: map['id'] as int?,
      comicId: map['comic_id'] as String,
      episodeId: map['episode_id'] as int,
      pageNo: map['page_no'] as int,
      lastReadAt: map['last_read_at'] as String? ?? '',
      comicTitle: map['comic_title'] as String?,
      coverPath: map['cover_path'] as String?,
      episodeNo: map['episode_no'] as int?,
      episodeTitle: map['episode_title'] as String?,
      totalPages: map['total_pages'] as int?,
    );
  }

  double get progress {
    if (totalPages == null || totalPages == 0) return 0;
    return (pageNo + 1) / totalPages!;
  }
}
