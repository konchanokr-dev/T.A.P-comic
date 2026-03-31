import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tapcomic/data/repos/comic_repo.dart';
import 'package:tapcomic/data/repos/history_repo.dart';
import 'package:tapcomic/widget/NameAvatar.dart';
import 'comic_reader_page.dart';
import 'package:tapcomic/data/repos/favorite_repo.dart';
import 'package:tapcomic/data/repos/comment_repo.dart';
import 'package:tapcomic/data/models/comment.dart';
import 'package:tapcomic/features/auth/reply.dart';
import 'package:tapcomic/features/auth/report_sheet.dart';
import 'package:tapcomic/data/api/api_service.dart';

class ComicDetailPage extends StatefulWidget {
  final String comicId;
  const ComicDetailPage({super.key, required this.comicId});

  @override
  State<ComicDetailPage> createState() => _ComicDetailPageState();
}

class _ComicDetailPageState extends State<ComicDetailPage> {
  final repo = ComicRepo();
  final historyRepo = HistoryRepo();
  final favoriteRepo = FavoriteRepo();
  String? token;
  String userUuid = "";
  String _currentUserName = "";

  List comments = [];
  bool loadingComments = true;
  Future<Map<String, dynamic>?>? _future;
  late Future<List<dynamic>> _chapterFuture;
  bool _isFavorite = false;
  bool _loadingFavorite = false;
  bool _favoriteLoaded = false;
  bool _expanded = false;
  final _commentRepo = CommentRepo();
bool _sortDescending = true;
  final TextEditingController _commentController = TextEditingController();
  List<CommentModel> _comments = [];
  bool _loadingComments = true;
  int? _comicIntId;
  
  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _loadUser();
final prefs = await SharedPreferences.getInstance();
_currentUserName = prefs.getString('userName') ?? "";
    _future = repo.fetchComicDetailByUuId(widget.comicId);
    _chapterFuture = repo.fetchChapters(widget.comicId);
    try {
      final favs = await favoriteRepo.getAll();

      _isFavorite = favs.any((f) => f.uuid == widget.comicId);
    } catch (e) {
      _isFavorite = false;
    }

    _favoriteLoaded = true;

    setState(() {});
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    userUuid = prefs.getString('userUuid') ?? "";
    token = prefs.getString("accessToken");
    setState(() {});

    print("USER UUID = $userUuid");
  }
DateTime parseDate(String s) {
  return DateTime.parse(s.replaceFirst(' ', 'T'));
}
Future<void> _loadComments(int comicIntId) async {
  try {
    final data = await _commentRepo.getComicComments(comicIntId);
    debugPrint(">>> comments count = ${data.length}"); // เพิ่ม
    if (!mounted) return;
 data.sort((a, b) {
  final dateA = DateTime.parse(a.createAt);
  final dateB = DateTime.parse(b.createAt);
  return dateB.compareTo(dateA); // ใหม่ก่อน
});

setState(() {
  _comments = data;
  _loadingComments = false;
});
  } catch (e) {
    debugPrint(">>> _loadComments ERROR = $e"); // เพิ่ม
    if (!mounted) return;
    setState(() => _loadingComments = false);
  }
}
  Future<void> _sendComment(int comicIntId) async {
    if (_commentController.text.trim().isEmpty) return;
    try {
      await _commentRepo.addComicComment(
        userUuid: userUuid,
        comicId: comicIntId,
        text: _commentController.text,
      );
      _commentController.clear();
      await _loadComments(comicIntId);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to send comment")));
    }
  }

  Future<void> _reportComment(CommentModel c) =>
      showReportSheet(context, userUuid: userUuid, commentId: c.id);
  void _openReplyThread(CommentModel comment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ReplyThreadWidget(comment: comment, userUuid: userUuid),
    ).then((_) {
      if (_comicIntId != null) _loadComments(_comicIntId!);
    });
  }

  Widget _commentSection(int comicIntId) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Comments",
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
             NameAvatar(name: _currentUserName, radius: 18),

              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextField(
                    controller: _commentController,
                    style: TextStyle(color: theme.colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: "Write Your Comment Here!",
                      hintStyle: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.send, color: theme.colorScheme.primary),
                onPressed: () => _sendComment(comicIntId),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_loadingComments)
            Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.onSurface,
              ),
            )
          else
            ..._comments.map((c) => _commentItem(c)).toList(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _commentItem(CommentModel c) {
    debugPrint("comment id = ${c.id}");
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
NameAvatar(name: c.user?.name ?? 'user', radius: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          c.user?.name ?? "user",
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      IconButton(
  onPressed: () => showReportSheet(
    context,
    userUuid: userUuid,
    commentId: c.id,
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
                    const SizedBox(height: 2),
                    Text(
                      c.text,
                    
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
         Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Row(
      children: [
        GestureDetector(
          onTap: () async {
            try {
              await _commentRepo.voteComment(
                commentId: c.id,
                vote: true,
              );
              await _loadComments(_comicIntId!);
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Please login first")),
              );
            }
          },
          child: Icon(
            c.currentUserVote == true
                ? Icons.thumb_up_alt
                : Icons.thumb_up_alt_outlined,
            color: c.currentUserVote == true
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withOpacity(0.5),
            size: 18,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          "${c.likeCount}",
          style: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
        const SizedBox(width: 16),
        GestureDetector(
          onTap: () async {
            try {
              await _commentRepo.voteComment(
                commentId: c.id,
                vote: false,
              );
              await _loadComments(_comicIntId!);
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Please login first")),
              );
            }
          },
          child: Icon(
            c.currentUserVote == false
                ? Icons.thumb_down_alt
                : Icons.thumb_down_alt_outlined,
            color: c.currentUserVote == false
                ? Colors.red
                : theme.colorScheme.onSurface.withOpacity(0.5),
            size: 18,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          "${c.dislikeCount}",
          style: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      ],
    ),
    TextButton.icon(
      onPressed: () => _openReplyThread(c),
      icon: Icon(
        Icons.mode_comment_outlined,
        color: theme.colorScheme.onSurface.withOpacity(0.5),
        size: 12,
      ),
      label: Text(
        "reply",
        style: TextStyle(
          color: theme.colorScheme.onSurface.withOpacity(0.5),
        ),
      ),
    ),
  ],
),
        ],
      ),
    );
  }

  Future<void> _toggleFavorite(String comicUuid) async {
    if (_loadingFavorite) return;

    setState(() => _loadingFavorite = true);

    try {
      await favoriteRepo.toggle(comicUuid);

      final favs = await favoriteRepo.getAll();
      _isFavorite = favs.any((f) => f.uuid == comicUuid);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please login first")));
    } finally {
      if (mounted) {
        setState(() => _loadingFavorite = false);
      }
    }
  }

  void _openChapter({
    required String uuid,
    required int chapterId,
    required int chapterNo,
    required int totalChapters,
    required int comicIntId,
    required String userUuid,
  }) {
    if (userUuid.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("User not loaded yet")));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ComicReaderPage(
          uuid: uuid,
          comicIntId: comicIntId,
          episodeTitle: "Chapter $chapterNo",
          episodeNo: chapterNo,
          comicId: widget.comicId,
          episodeId: chapterId,
          totalChapters: totalChapters,
          userUuid: userUuid,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_future == null || _chapterFuture == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      appBar: AppBar(),

      body: FutureBuilder<Map<String, dynamic>?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Text('Not found', style: TextStyle(color: Colors.white)),
            );
          }

          final m = snapshot.data!;

          final chapterCount = m['chapterCount'] ?? 0;
          final uuid = m['uuid'];
          final comicIntId = m['id'] as int;
          if (_comicIntId == null) {
            _comicIntId = comicIntId;
            Future.microtask(() => _loadComments(comicIntId));
          }
          final genresList = ((m['genres'] as List?) ?? [])
              .map((g) => g['name'].toString())
              .toList();

          final genresText = genresList.join(", ");
          debugPrint(genresText);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: "${m['coverUrl']}?w=500",
                    httpHeaders: {"Authorization": "Bearer $token"},
                    height: 240,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      height: 240,
                      color: theme.colorScheme.surface,
                    ),
                    errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
                  ),
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black54,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      icon: Icon(
                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: _isFavorite
                            ? const Color.fromARGB(255, 224, 211, 26)
                            : Colors.white,
                      ),
                      label: Text(_isFavorite ? "Following" : "Follow"),
                      onPressed: () => _toggleFavorite(uuid),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                m['title'] ?? '',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Author: ${m['author'] ?? '-'}',

                      style: TextStyle(color: theme.colorScheme.onSurface),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Artist: ${m['artist'] ?? '-'}',
                      style: TextStyle(color: theme.colorScheme.onSurface),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Genres: ${genresText.isEmpty ? '-' : genresText}',
                      style: TextStyle(color: theme.colorScheme.onSurface),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Synopsis:',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),

              Text(
                m['description'] ?? '',
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
              const SizedBox(height: 24),

              Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Text(
      'Chapters: $chapterCount',
      style: TextStyle(
        color: theme.colorScheme.onSurface,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
    TextButton.icon(
      onPressed: () => setState(() => _sortDescending = !_sortDescending),
      icon: Icon(
        _sortDescending ? Icons.arrow_downward : Icons.arrow_upward,
        size: 16,
        color: theme.colorScheme.primary,
      ),
      label: Text(
        _sortDescending ? "DSC" : "ASC",
        style: TextStyle(color: theme.colorScheme.primary, fontSize: 13),
      ),
    ),
  ],
),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: FutureBuilder<List<dynamic>>(
                  future: _chapterFuture,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final chapters = snapshot.data!;
                    final displayCount = _expanded
                        ? chapters.length
                        : chapters.length.clamp(0, 5);
                        final sortedChapters = _sortDescending
         ? chapters.reversed.toList()
         : List.from(chapters);
                  
                    return Column(

                      children: [
                         
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: displayCount,
                          itemBuilder: (context, index) {
                            final ch = sortedChapters[index];
                            final chapterNo = ch['count'];

                            return InkWell(
                              onTap: () => _openChapter(
                                uuid: uuid,
                                chapterId: ch['id'],
                                chapterNo: chapterNo,
                                totalChapters: chapters.length,
                                comicIntId: m['id'],
                                userUuid: userUuid,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.1),
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Chapter',
                                      style: TextStyle(
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    Text(
                                      '$chapterNo',
                                      style: TextStyle(
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                        if (chapters.length > 5)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _expanded = !_expanded;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Center(
                                child: Icon(
                                  _expanded
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.7),
                                  size: 30,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              _commentSection(comicIntId),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}
