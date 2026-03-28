import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tapcomic/data/repos/comic_repo.dart';
import 'package:tapcomic/data/repos/history_repo.dart';
import 'comic_reader_page.dart';
import 'package:tapcomic/data/repos/favorite_repo.dart';
import 'package:tapcomic/data/repos/comment_repo.dart';
import 'package:tapcomic/data/models/comment.dart';
import 'package:tapcomic/features/auth/reply.dart';
import 'package:tapcomic/data/api/api_service.dart'; // ✅ เพิ่มบรรทัดนี้

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
List comments = [];
bool loadingComments = true;
Future<Map<String, dynamic>?>? _future;
late Future<List<dynamic>> _chapterFuture;
  bool _isFavorite = false;
  bool _loadingFavorite = false;
  bool _favoriteLoaded = false;
  bool _expanded = false;
  final _commentRepo = CommentRepo();
  
final TextEditingController _commentController = TextEditingController();
List<CommentModel> _comments = [];
bool _loadingComments = true;
int? _comicIntId; // เ
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

  _future = repo.fetchComicDetailByUuId(widget.comicId);
  _chapterFuture = repo.fetchChapters(widget.comicId);

  try {
    final favs = await favoriteRepo.getAll();

    _isFavorite = favs.any(
      (f) => f.uuid == widget.comicId,
    );
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
Future<void> _loadComments(int comicIntId) async {
  try {
    final data = await _commentRepo.getComicComments(comicIntId);
    if (!mounted) return;
    setState(() {
      _comments = data;
      _loadingComments = false;
    });
  } catch (e) {
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Failed to send comment")),
    );
  }
}

Future<void> _reportComment(CommentModel c) async {
  try {
    final res = await ApiService.post("/report", {
         "uuid": userUuid,
      "commentId": c.id,
      "reason": "spam",
    });

    if (!mounted) return;

    if (res.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Reported successfully")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Report failed")),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Report failed")),
    );
  }
}
void _openReplyThread(CommentModel comment) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.black,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => ReplyThreadWidget(
      comment: comment,
      userUuid: userUuid,
    ),
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
          style: TextStyle(color: theme.colorScheme.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // ช่องพิมพ์
        Row(
          children: [
            const CircleAvatar(radius: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: _commentController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: "Write Your Comment Here!",
                    hintStyle: TextStyle(color: Colors.white54),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send, color: Colors.greenAccent),
              onPressed: () => _sendComment(comicIntId),
            ),
          ],
        ),

        const SizedBox(height: 20),

        if (_loadingComments)
          const Center(child: CircularProgressIndicator(color: Colors.white))
        else
          ..._comments.map((c) => _commentItem(c)).toList(),

        const SizedBox(height: 16),
      ],
    ),
  );
}

Widget _commentItem(CommentModel c) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: const Color(0xFF333333),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(radius: 18, backgroundColor: Colors.white24),
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
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _reportComment(c),
                        child: const Text(
                          "report",
                          style: TextStyle(color: Colors.redAccent, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    c.text,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.thumb_up_alt_outlined, color: Colors.white70, size: 18),
                SizedBox(width: 4),
                Text("0", style: TextStyle(color: Colors.white70)),
                SizedBox(width: 16),
                Icon(Icons.thumb_down_alt_outlined, color: Colors.white70, size: 18),
              ],
            ),
            TextButton.icon(
              onPressed: () => _openReplyThread(c),
              icon: const Icon(Icons.mode_comment_outlined, color: Colors.white70, size: 12),
              label: const Text("reply", style: TextStyle(color: Colors.white70)),
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
    _isFavorite = favs.any(
      (f) => f.uuid == comicUuid,
    );

  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please login first")),
    );
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("User not loaded yet")),
    );
    return;
  }

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ComicReaderPage(
        uuid: uuid,
        comicIntId: comicIntId,
        episodeTitle: "Chapter $chapterNo",
        episodeNo: chapterNo,   // ใช้ count
        comicId: widget.comicId,
        episodeId: chapterId,   // ใช้ id
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
  return const Scaffold(
    body: Center(child: CircularProgressIndicator()),
  );
}
    return Scaffold(
      
      backgroundColor: theme.scaffoldBackgroundColor,

      appBar: AppBar( ),
      
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

// โหลด comment ครั้งแรก
if (_comicIntId == null) {
  _comicIntId = comicIntId;
  Future.microtask(() => _loadComments(comicIntId));
}
          final genresList = (m['genres'] as List?) ?? [];
          final genresText = genresList.join(", ");

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
               Stack(
                 children: [ CachedNetworkImage(
  imageUrl: "${m['coverUrl']}?w=500",
  httpHeaders: {
    "Authorization": "Bearer $token",
  },
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
          color: _isFavorite ? const Color.fromARGB(255, 224, 211, 26) : Colors.white,
        ),
        label: Text(_isFavorite ? "Following" : "Follow"),
        onPressed:() => _toggleFavorite(uuid),
      ),
    ),
  ],
              ),
              const SizedBox(height: 16),
              Text(
                m['title'] ?? '',
                style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 24, fontWeight: FontWeight.bold),

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
                'Author: ${m['author'] ?? '-' }',
                
style: TextStyle(color: theme.colorScheme.onSurface),              ),
               const SizedBox(height: 8),
              Text(
                'Artist: ${m['artist']?? '-' }',
style: TextStyle(color: theme.colorScheme.onSurface),              ),
              const SizedBox(height: 8),
              Text(
                'Genres: ${genresText.isEmpty ? '-' : genresText}',
style: TextStyle(color: theme.colorScheme.onSurface),              ),
    ],
  ),
  ),    const SizedBox(height: 16),
  Text(
                'Synopsis:',
                style:TextStyle(color: theme.colorScheme.onSurface,fontWeight: FontWeight.bold),
              ),
          
              Text(
                m['description'] ?? '',
                style:  TextStyle(color: theme.colorScheme.onSurface),
              ),
              const SizedBox(height: 24),

              Text(
                'Chapters: $chapterCount',
                style:  TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
Container(
  decoration: BoxDecoration(
    color: theme.colorScheme.surface, // สีพื้นหลัง
    borderRadius: BorderRadius.circular(16), // มุมโค้ง
  ),
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  child: FutureBuilder<List<dynamic>>(
  future: _chapterFuture,
  builder: (context, snapshot) {

    if (!snapshot.hasData) {
      return const Center(child: CircularProgressIndicator());
    }

    final chapters = snapshot.data!;
final displayCount = _expanded ? chapters.length : chapters.length.clamp(0, 5);
    return Column(
  children: [
    ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayCount,
      itemBuilder: (context, index) {
        final ch = chapters[index];
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
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration:  BoxDecoration(
              border: Border(
                bottom: BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.1)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 Text('Chapter', style: TextStyle(color: theme.colorScheme.onSurface),),
                Text('$chapterNo',
                    style:  TextStyle(color: theme.colorScheme.onSurface),),
              ],
            ),
          ),
        );
      },
    ),

    // 👇 วางตรงนี้!
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
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              size: 30,
            ),
          ),
        ),
      ),
  ],
);
    
  },
)
),
_commentSection(comicIntId),
const SizedBox(height: 24),
            ]
          );
          
        },
      ),
    );
  }
  
}
