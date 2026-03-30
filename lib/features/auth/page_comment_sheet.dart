import 'package:flutter/material.dart';
import 'package:tapcomic/data/models/comment.dart';
import 'package:tapcomic/data/repos/comment_repo.dart';

class PageCommentSheet extends StatefulWidget {
  final int pageId;
  final int pageNo;
  final String userUuid;
  final int comicIntId;
  final CommentRepo commentRepo;

  const PageCommentSheet({
    super.key,
    required this.pageId,
    required this.pageNo,
    required this.userUuid,
    required this.comicIntId,
    required this.commentRepo,
  });

  @override
  State<PageCommentSheet> createState() => _PageCommentSheetState();
}

class _PageCommentSheetState extends State<PageCommentSheet> {
  List<CommentModel> _comments = [];
  bool _loading = true;
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final data = await widget.commentRepo.getPageComments(widget.pageId);
      if (!mounted) return;
      setState(() {
        _comments = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    if (_controller.text.trim().isEmpty) return;
    try {
      await widget.commentRepo.addPageComment(
        userUuid: widget.userUuid,
        comicId: widget.comicIntId,
        pageId: widget.pageId,
        text: _controller.text,
      );
      _controller.clear();
      await _load();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to send comment")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // ✅ ดึง theme

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface, // ✅
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.3), // ✅
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(
                    Icons.image,
                    color: theme.colorScheme.onSurface.withOpacity(0.5), // ✅
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "Page ${widget.pageNo} Comments",
                    style: TextStyle(
                      color: theme.colorScheme.onSurface, // ✅
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: _loading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: theme.colorScheme.onSurface, // ✅
                      ),
                    )
                  : _comments.isEmpty
                      ? Center(
                          child: Text(
                            "No comments on this page yet",
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withOpacity(0.4), // ✅
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _comments.length,
                          itemBuilder: (_, i) {
                            final c = _comments[i];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.onSurface.withOpacity(0.05), // ✅
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: theme.colorScheme.onSurface.withOpacity(0.15), // ✅
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          c.user?.name ?? "user",
                                          style: TextStyle(
                                            color: theme.colorScheme.onSurface.withOpacity(0.7), // ✅
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          c.text,
                                          style: TextStyle(
                                            color: theme.colorScheme.onSurface, // ✅
                                            fontSize: 14,
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

            // Input bar
            Padding(
              padding: EdgeInsets.only(
                left: 12,
                right: 12,
                bottom: MediaQuery.of(context).viewInsets.bottom + 12,
                top: 8,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: theme.colorScheme.onSurface.withOpacity(0.15), // ✅
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withOpacity(0.08), // ✅
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextField(
                        controller: _controller,
                        style: TextStyle(color: theme.colorScheme.onSurface), // ✅
                        decoration: InputDecoration(
                          hintText: "Comment on this page...",
                          hintStyle: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.4), // ✅
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send, color: theme.colorScheme.primary), // ✅
                    onPressed: _send,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}