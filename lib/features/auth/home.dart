import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:tapcomic/data/models/comic.dart';
import 'package:tapcomic/data/repos/comic_repo.dart';
import 'package:tapcomic/features/auth/auth_service.dart';
import 'comic_detail_page.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final repo = ComicRepo();

  late Future<List<Comic>> newChaptersFuture;

  @override
  void initState() {
    super.initState();
    final token = AuthService.token;
    newChaptersFuture = repo.fetchNewChapters(limit: 10);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF171717),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Image.asset(
                    'assets/icon/fakelogo.png',
                    height: 48,
                  ),
                ),
                const SizedBox(height: 24),

                _buildSectionTitle('New Chapter '),
                _buildComicList(newChaptersFuture),

                const SizedBox(height: 24),

                _buildSectionTitle('Popular Comics'),
                _buildComicList(newChaptersFuture), // รอแยก future

                const SizedBox(height: 24),

                _buildSectionTitle('Recently Updated'),
                _buildComicList(newChaptersFuture), // รอแยก future
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextButton(
            onPressed: () {},
            child: const Text('See All'),
          ),
        ],
      ),
    );
  }

  Widget _buildComicList(Future<List<Comic>> future) {
    return FutureBuilder<List<Comic>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 260,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return SizedBox(
            height: 60,
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.redAccent),
            ),
          );
        }

        final comics = snapshot.data ?? [];

        if (comics.isEmpty) {
          return const SizedBox(
            height: 60,
            child: Center(
              child: Text(
                'No comics found',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          );
        }

        return SizedBox(
          height: 260,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: comics.length,
            itemBuilder: (context, index) {
              final c = comics[index];
              return _buildComicCard(c);
            },
          ),
        );
      },
    );
  }

  Widget _buildComicCard(Comic c) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ComicDetailPage(comicId: c.uuid),
          ),
        );
      },
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              child: CachedNetworkImage(
                 imageUrl: c.url,
  httpHeaders: AuthService.token == null
      ? null
      : {
          "Authorization": "Bearer ${AuthService.token}",
        },
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
               errorWidget: (_, __, ___) => Container(
  height: 200,
  color: Colors.grey[800],
  child: const Icon(
    Icons.broken_image,
    color: Colors.white,
  ),
),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chapter ${c.chapterCount}',
                    style: const TextStyle(
                      color: Color(0xFF959595),
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    c.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle( 
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
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
