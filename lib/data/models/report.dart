class ReportRequest {
  final String uuid;
  final int commentId;
  final String reason;

  ReportRequest({
    required this.uuid,
    required this.commentId,
    required this.reason,
  });

  Map<String, dynamic> toJson() {
    return {
      "uuid": uuid,
      "commentId": commentId,
      "reason": reason,
    };
  }
}