class Episode {
  final int id;
  final int comicId;
  final int epNo;
  final String title;

  const Episode({
    required this.id,
    required this.comicId,
    required this.epNo,
    required this.title,
  });

  factory Episode.fromMap(Map<String, dynamic> map) {
    return Episode(
      id: map['id'],
      comicId: map['comicId'] ?? map['comic_id'],
      epNo: map['epNo'] ?? map['ep_no'],
      title: map['title'],
    );
  }
}
