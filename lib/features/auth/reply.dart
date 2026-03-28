import 'package:flutter/material.dart';
import 'package:tapcomic/data/models/comment.dart';
import 'package:tapcomic/data/repos/comment_repo.dart';
import 'package:tapcomic/data/repos/report_repo.dart';

class ReplyThreadWidget extends StatefulWidget {
  final CommentModel comment;
  final String userUuid;
  const ReplyThreadWidget({super.key, required this.comment, required this.userUuid});

  @override
  State<ReplyThreadWidget> createState() => _ReplyThreadWidgetState();
}

class _ReplyThreadWidgetState extends State<ReplyThreadWidget> {
  final TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final comment = widget.comment;

    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // drag handle
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 12),

            // main comment
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
                        Text(comment.user?.name ?? "user",
                            style: TextStyle(
                                color: theme.colorScheme.onSurface.withOpacity(0.7),
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(comment.text,
                            style: TextStyle(color: theme.colorScheme.onSurface)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Divider(color: theme.colorScheme.onSurface.withOpacity(0.15)),

            // replies
            Expanded(
              child: ListView.builder(
                itemCount: comment.replies?.length ?? 0,
                itemBuilder: (_, i) {
                  final r = comment.replies![i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        const CircleAvatar(radius: 14),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.user?.name ?? "user",
                                  style: TextStyle(
                                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                                      fontSize: 13, fontWeight: FontWeight.bold)),
                              Text(r.text,
                                  style: TextStyle(
                                      color: theme.colorScheme.onSurface, fontSize: 13)),
                              TextButton(
                                onPressed: () => _reportComment(r.id),
                                child: const Text("Report",
                                    style: TextStyle(color: Colors.redAccent)),
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

            // reply input
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: theme.colorScheme.surface,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      style: TextStyle(color: theme.colorScheme.onSurface),
                      decoration: InputDecoration(
                        hintText: "Write reply...",
                        hintStyle: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.5)),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send, color: theme.colorScheme.onSurface),
                    onPressed: _sendReply,
                  ),
                ],
              ),
            ),
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
      setState(() {
        widget.comment.replies.add(ReplyModel(
          id: 0, text: text,
          user: widget.comment.user,
          createAt: DateTime.now().toString(),
          mainCommentId: widget.comment.id,
        ));
      });
      controller.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to send reply")));
    }
  }

  Future<void> _reportComment(int commentId) async {
    try {
      await ReportRepo().reportComment(
          uuid: widget.userUuid, commentId: commentId, reason: "spam");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Reported")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Report failed")));
    }
  }
}