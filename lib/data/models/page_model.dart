class PageModel {
  final String pageUrl;
  final int pageNumber;
  final int pageId;

  PageModel({
    required this.pageUrl,
    required this.pageNumber,
    required this.pageId,
  });

factory PageModel.fromJson(Map<String, dynamic> json) {
  return PageModel(
    pageUrl: json["pageUrl"] ?? "",
    pageNumber: json["pageNumber"] ?? 0,
    pageId: json["pageId"] ?? 0,
  );
}
}