
import 'package:flutter/material.dart';
import 'package:tapcomic/data/models/comment.dart';
import 'package:tapcomic/data/repos/comment_repo.dart';
import 'package:tapcomic/data/repos/report_repo.dart';

class ReplyThreadWidget extends StatefulWidget {
  final CommentModel comment;
  final String userUuid;
  const ReplyThreadWidget({
    super.key,
    required this.comment,
    required this.userUuid,
  });

  @override
  State<ReplyThreadWidget> createState() => _ReplyThreadWidgetState();
}

class _ReplyThreadWidgetState extends State<ReplyThreadWidget> {
  final TextEditingController controller = TextEditingController();
  List<CommentModel> comments = [];

  @override
  Widget build(BuildContext context) {
    final comment = widget.comment;

    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Color(0xFF111111),
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [

            /// drag handle
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            const SizedBox(height: 12),

            /// main comment
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const CircleAvatar(radius: 18),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Text(
                          comment.user?.name ?? "user",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          comment.text,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(color: Colors.white24),

            /// replies
            Expanded(
              child: ListView.builder(
                itemCount: comment.replies?.length ?? 0,
                itemBuilder: (_, i) {

                  final r = comment.replies![i];

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: Row(
                      children: [

                        const CircleAvatar(radius: 14),

                        const SizedBox(width: 8),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              Text(
                                r.user?.name ?? "user",
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              Text(
                                r.text,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),

                  TextButton(
  onPressed: () {
    _reportComment(r.id);
  },
  child: const Text(
    "Report",
    style: TextStyle(color: Colors.redAccent),
  ),
),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            /// reply input
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[900],
              ),
              child: Row(
                children: [

                  Expanded(
                    child: TextField(
                      controller: controller,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: "Write reply...",
                        hintStyle: TextStyle(color: Colors.white54),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
IconButton(
  icon: const Icon(Icons.send),
   onPressed: _sendReply
)
                  
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

Future<void> _sendReply() async {
  final text = controller.text.trim();
  if (text.isEmpty) return;

  try {
    await CommentRepo().addReply(
      userUuid: widget.userUuid,
      commentId: widget.comment.id,
      text: text,
    );

    // ✅ แก้ตรงนี้
    setState(() {
      widget.comment.replies.add(
        ReplyModel(
          id: 0,
          text: text,
          user: widget.comment.user, // ⚠️ ชั่วคราว ถ้ามี currentUser ให้ใส่แทน
          createAt: DateTime.now().toString(),
          mainCommentId: widget.comment.id,
        ),
      );
    });

    controller.clear();

  } catch (e) {
    print("❌ ERROR: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Failed to send reply")),
    );
  }
}
Future<void> _reportComment(int commentId) async {

  try {

    await ReportRepo().reportComment(
      uuid: widget.userUuid,
      commentId: commentId,
      reason: "spam",
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Reported")),
    );

  } catch (e) {

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Report failed")),
    );

  }

}
}
