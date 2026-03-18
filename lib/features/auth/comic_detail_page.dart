import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tapcomic/data/repos/comic_repo.dart';
import 'package:tapcomic/data/repos/history_repo.dart';
import 'comic_reader_page.dart';
import 'package:tapcomic/data/repos/favorite_repo.dart';

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
@override
  void initState() {

   super.initState();
  _init();
  }
  Future<void> _init() async {
  await _loadUser(); // รอ token ก่อน
  _future = repo.fetchComicDetailByUuId(widget.comicId);
  _chapterFuture = repo.fetchChapters(widget.comicId);
  setState(() {});
}
Future<void> _loadUser() async {
   
  final prefs = await SharedPreferences.getInstance();
  userUuid = prefs.getString('userUuid') ?? "";
   token = prefs.getString("accessToken");
  setState(() {});

  print("USER UUID = $userUuid");
}
Future<void> _toggleFavorite(String comicUuid) async {
  if (_loadingFavorite) return;

  setState(() => _loadingFavorite = true);

  try {
    await favoriteRepo.toggle(comicUuid);
    setState(() {
      _isFavorite = !_isFavorite;
    });
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
    if (_future == null || _chapterFuture == null) {
  return const Scaffold(
    body: Center(child: CircularProgressIndicator()),
  );
}
    return Scaffold(
      
      backgroundColor: Color(0xFF171717),
      appBar: AppBar(
        backgroundColor: Color(0xFF171717),
        foregroundColor: Colors.white,
      ),
      
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
    color: Colors.grey[900],
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
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
               const SizedBox(height: 8),
               Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: const Color(0xFF282828), 
    borderRadius: BorderRadius.circular(12),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
              Text(
                'Author: ${m['author'] ?? '-' }',
                
                style: const TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
              ),
               const SizedBox(height: 8),
              Text(
                'Artist: ${m['artist']?? '-' }',
                style: const TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
              ),
              const SizedBox(height: 8),
              Text(
                'Genres: ${genresText.isEmpty ? '-' : genresText}',
                style: const TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
              ),
    ],
  ),
  ),    const SizedBox(height: 16),
  Text(
                'Synopsis:',
                style: const TextStyle(color: Color.fromARGB(255, 255, 255, 255),fontWeight: FontWeight.bold),
              ),
          
              Text(
                m['description'] ?? '',
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 24),

              Text(
                'Chapters: $chapterCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
Container(
  decoration: BoxDecoration(
    color: const Color(0xFF1E1E1E), // สีพื้นหลัง
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

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: chapters.length,
      itemBuilder: (context, index) {

        final ch = chapters[index];

        final chapterId = ch['id'];      // 10
        final chapterNo = ch['count'];   // 1

        return InkWell(
          onTap: () => _openChapter(
  uuid: uuid,
  chapterId: chapterId,
  chapterNo: chapterNo,
  totalChapters: chapters.length,
  comicIntId: m['id'],
  userUuid: userUuid,
),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Chapter',
                  style: TextStyle(color: Colors.white),
                ),
                Text(
                  '$chapterNo',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        );
      },
    );
  },
)
)
            ]
          );
        },
      ),
    );
  }
  
}
