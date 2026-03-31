import 'package:flutter/material.dart';
import 'package:tapcomic/data/models/comment.dart';
import 'package:tapcomic/data/repos/comment_repo.dart';
import 'package:tapcomic/features/auth/report_sheet.dart';
import 'package:tapcomic/widget/NameAvatar.dart';

class ReplyThreadWidget extends StatefulWidget {
  final CommentModel comment;
  final String userUuid;
  const ReplyThreadWidget({super.key, required this.comment, required this.userUuid});

  @override
  State<ReplyThreadWidget> createState() => _ReplyThreadWidgetState();
}

 class _ReplyThreadWidgetState extends State<ReplyThreadWidget> {
  final TextEditingController controller = TextEditingController();
  final _repo = CommentRepo();
  late List<ReplyModel> _replies; // ← เพิ่ม

  @override
  void initState() {
    super.initState();
    _replies = List.from(widget.comment.replies ?? []); // ← copy มาเก็บใน state
  }
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
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
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
                  NameAvatar(name: comment.user?.name ?? 'user', radius: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          comment.user?.name ?? "user",
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          comment.text,
                          style: TextStyle(color: theme.colorScheme.onSurface),
                        ),
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
                itemCount: _replies.length, 
                itemBuilder: (_, i) {
final r = _replies[i];                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            NameAvatar(name: r.user?.name ?? 'user', radius: 14),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    r.user?.name ?? "user",
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(   
                                    r.text,
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => showReportSheet(
                                context,
                                userUuid: widget.userUuid,
                                commentId: r.id,
                              ),
                              icon: const Icon(Icons.flag_outlined),
                              color: theme.colorScheme.onSurface.withOpacity(0.4),
                              iconSize: 18,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),

                        // like/dislike row
                        Padding(
                          padding: const EdgeInsets.only(left: 36),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () => _voteReply(i, true),
                                child: Icon(
                                  r.currentUserVote == true
                                      ? Icons.thumb_up_alt
                                      : Icons.thumb_up_alt_outlined,
                                  color: r.currentUserVote == true
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurface.withOpacity(0.5),
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "${r.likeCount}",
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 12),
                              GestureDetector(
                              onTap: () => _voteReply(i, false),

                                child: Icon(
                                  r.currentUserVote == false
                                      ? Icons.thumb_down_alt
                                      : Icons.thumb_down_alt_outlined,
                                  color: r.currentUserVote == false
                                      ? Colors.red
                                      : theme.colorScheme.onSurface.withOpacity(0.5),
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "${r.dislikeCount}",
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                                  fontSize: 12,
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
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
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
Future<void> _voteReply(int index, bool vote) async {
  final r = _replies[index];
  try {
    await _repo.voteReply(replyId: r.id, vote: vote);

    // คำนวณ like/dislike ใหม่
    final wasLiked = r.currentUserVote == true;
    final wasDisliked = r.currentUserVote == false;
    final cancel = (vote == true && wasLiked) || (vote == false && wasDisliked);

    setState(() {
      _replies[index] = ReplyModel(
        id: r.id,
        text: r.text,
        user: r.user,
        createAt: r.createAt,
        mainCommentId: r.mainCommentId,
        likeCount: vote == true
            ? (cancel ? r.likeCount - 1 : r.likeCount + (wasDisliked ? 0 : 1))
            : r.likeCount - (wasLiked ? 1 : 0),
        dislikeCount: vote == false
            ? (cancel ? r.dislikeCount - 1 : r.dislikeCount + (wasLiked ? 0 : 1))
            : r.dislikeCount - (wasDisliked ? 1 : 0),
        currentUserVote: cancel ? null : vote,
      );
    });
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please login first")),
    );
  }
}
  Future<void> _sendReply() async {
    final text = controller.text.trim();
    if (text.isEmpty) return;
    try {
      await _repo.addReply(
        userUuid: widget.userUuid,
        commentId: widget.comment.id,
        text: text,
      );
      setState(() {
       _replies.add(ReplyModel(
          id: 0,
          text: text,
          user: widget.comment.user,
          createAt: DateTime.now().toString(),
          mainCommentId: widget.comment.id,
          likeCount: 0,     
          dislikeCount: 0,    
          currentUserVote: null, 
        ));
      });
      controller.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to send reply")),
      );
    }
  }
}