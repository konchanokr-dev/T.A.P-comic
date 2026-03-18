class PageModel {
  final String pageUrl;
  final int pageNumber;

  PageModel({
    required this.pageUrl,
    required this.pageNumber,
  });

  factory PageModel.fromJson(Map<String, dynamic> json) {
    return PageModel(
      pageUrl: json['pageUrl'],
      pageNumber: json['pageNumber'],
    );
  }
}