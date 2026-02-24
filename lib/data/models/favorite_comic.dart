class   FavoriteComic {
  final String uuid;
  final String title;
  final String url;
  const FavoriteComic({
     required this.uuid,
    required this.title,
    required this.url,
  });
factory FavoriteComic.fromMap(Map<String, dynamic> map) {
    return FavoriteComic(
      uuid: map['uuid'] ?? '',
      title: map['title'] ?? '',
      url: map['coverUrl'] ?? '',
    );
  }
}