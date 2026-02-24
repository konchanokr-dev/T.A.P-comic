import 'package:flutter/material.dart';
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

  late Future<Map<String, dynamic>?> _future;

  bool _isFavorite = false;
  bool _loadingFavorite = false;

  @override
  void initState() {
    super.initState();
    _future = repo.fetchComicDetailByUuId(widget.comicId);
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
    required int chapter,
      required int totalChapters, 

  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ComicReaderPage(
          uuid: uuid,             
          episodeTitle: "Chapter $chapter",
          episodeNo: chapter,
          comicId: widget.comicId,
          episodeId: chapter,
          totalChapters: totalChapters, 
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
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
                 children: [ Image.network(
                m['coverUrl'] ?? '',
                height: 240,
                width: double.infinity,
                fit: BoxFit.cover,
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
    color: const Color.fromARGB(137, 128, 128, 128), 
    borderRadius: BorderRadius.circular(12),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
              Text(
                'Author: ${m['author'] ?? '-' }',
                style: const TextStyle(color: Colors.white70),
              ),
               const SizedBox(height: 8),
              Text(
                'Artist: ${m['artist']?? '-' }',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Text(
                'Genres: ${genresText.isEmpty ? '-' : genresText}',
                style: const TextStyle(color: Colors.white70),
              ),
    ],
  ),
  ),
              const SizedBox(height: 16),
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

              ...List.generate(chapterCount, (index) {
                final chapter = index + 1;

                return InkWell(
                  onTap: () => _openChapter(
                    uuid: uuid,
                    chapter: chapter,
                      totalChapters: chapterCount, 

                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.white12),
                      ),
                    ),
                    child: Text(
                      'Chapter $chapter',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
