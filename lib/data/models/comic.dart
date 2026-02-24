class Comic {
  final int id;
  final String uuid;
  final String title;
  final String description;
  final String? author;
  final String? artist;
  final List<dynamic> genres;
  final int followerCount;
  final int chapterCount;
  final String url;

  const Comic({
    required this.id,
    required this.uuid,
    required this.title,
    required this.description,
    required this.author,
    required this.artist,
    required this.genres,
    required this.followerCount,
    required this.chapterCount,
    required this.url,
  });

  factory Comic.fromMap(Map<String, dynamic> map) {
    return Comic(
      id: (map['id'] as num).toInt(),
      uuid: map['uuid'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      author: map['author'],
      artist: map['artist'],
      genres: map['genres'] ?? [],
      followerCount: (map['followerCount'] as num?)?.toInt() ?? 0,
      chapterCount: (map['chapterCount'] as num?)?.toInt() ?? 0,
      url: map['coverUrl'] ?? '',
    );
  }
}
