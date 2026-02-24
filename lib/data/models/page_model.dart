class PageModel {
  final int id;
  final int pageNumber;
  final String imageUrl;

  PageModel({
    required this.id,
    required this.pageNumber,
    required this.imageUrl,
  });

  factory PageModel.fromMap(Map<String, dynamic> map) {
    return PageModel(
      id: (map['id'] as num).toInt(),
      pageNumber: (map['count'] as num).toInt(),
      imageUrl: map['pageUrl'] ?? '',
    );
  }
}