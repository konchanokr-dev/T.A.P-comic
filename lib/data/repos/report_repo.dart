import 'package:flutter/material.dart';
import 'package:tapcomic/data/api/api_service.dart';

class ReportRepo {
  Future<void> reportComment({
    required String uuid,
    required int commentId,
    required String reason,
  }) async {
    debugPrint("📢 REPORT → uuid: $uuid | commentId: $commentId | reason: $reason");

    final response = await ApiService.post("/report", {
      "uuid": uuid,
      "commentId": commentId,
      "reason": reason,
    });

    debugPrint("📢 REPORT STATUS: ${response.statusCode}");
    debugPrint("📢 REPORT BODY: ${response.body}");

    if (response.statusCode != 200) {
      throw Exception("report fail");
    }
  }
}