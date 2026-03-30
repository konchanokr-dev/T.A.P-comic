class ReadingHistory {
  final int? id;
  final String? userUuid;
  final String comicUuid;   
  final int chapterId;
  final int pageNumber;
  final String lastReadAt;

  String? comicTitle;
  String? coverPath;
  final int? episodeNo;
  final String? episodeTitle;
  final int? totalPages;

  ReadingHistory({
    this.id,
    this.userUuid,
    required this.comicUuid,
    required this.chapterId,
    required this.pageNumber,
    required this.lastReadAt,
    this.comicTitle,
    this.coverPath,
    this.episodeNo,
    this.episodeTitle,
    this.totalPages,
  });

  factory ReadingHistory.fromApi(Map<String, dynamic> map) {
    return ReadingHistory(
      id: (map['id'] as num?)?.toInt(),
      userUuid: map['userUuid'] as String?,

      comicUuid: map['comicUuid'] ?? '',

      chapterId: (map['chapterId'] as num?)?.toInt() ?? 0,
      pageNumber: (map['pageNumber'] as num?)?.toInt() ?? 0,

      lastReadAt: map['lastReadAt'] as String? ?? '',

      comicTitle: map['comicTitle'] as String?,
      coverPath: map['coverPath'] as String?,
    );
  }

  double get progress {
    if (totalPages == null || totalPages == 0) return 0;
    return (pageNumber + 1) / totalPages!;
  }
}