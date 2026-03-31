import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:tapcomic/data/models/comic.dart';
import 'package:tapcomic/data/repos/comic_repo.dart';
import 'package:tapcomic/features/auth/auth_service.dart';
import 'package:tapcomic/features/auth/see_all_page.dart';
import 'comic_detail_page.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final repo = ComicRepo();
  late Future<List<Comic>> newChaptersFuture;
  late Future<List<Comic>> popularChaptersFuture;
late Future<List<Comic>> followingFuture;
  @override
  void initState() {
    super.initState();
    newChaptersFuture = repo.fetchNew(limit: 10);
    popularChaptersFuture = repo.fetchPopular(limit: 10);
    followingFuture = repo.fetchFollowing();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Image.asset('assets/icon/fakelogo.png', height: 48)),
                const SizedBox(height: 24),
                _buildSectionTitle(context, 'Following',  followingFuture),
_buildComicList(context, followingFuture),
const SizedBox(height: 24),
_buildSectionTitle(context, 'Popular Comics', popularChaptersFuture),
_buildComicList(context, popularChaptersFuture),
const SizedBox(height: 24),
_buildSectionTitle(context, 'New Chapter', newChaptersFuture),
_buildComicList(context, newChaptersFuture),
              ],
            ),
          ),
        ),
      ),
    );
  }

 Widget _buildSectionTitle(BuildContext context, String title, Future<List<Comic>> future) {
  final theme = Theme.of(context);
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 20, fontWeight: FontWeight.bold)),
        TextButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => SeeAllPage(title: title, future: future)),
          ),
          child: const Text('See All', style: TextStyle(color: Colors.green)),
        ),
      ],
    ),
  );
}

  Widget _buildComicList(BuildContext context, Future<List<Comic>> future) {
    final theme = Theme.of(context);
    return FutureBuilder<List<Comic>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 260, child: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return SizedBox(height: 60,
              child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
        }
        final comics = snapshot.data ?? [];
        if (comics.isEmpty) {
          return SizedBox(height: 60,
              child: Center(child: Text('No comics found',
                  style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)))));
        }
        return SizedBox(
          height: 260,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: comics.length,
            itemBuilder: (context, index) => _buildComicCard(context, comics[index]),
          ),
        );
      },
    );
  }

  Widget _buildComicCard(BuildContext context, Comic c) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () async {
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ComicDetailPage(comicId: c.uuid),
    ),
  );

  setState(() {
    followingFuture = repo.fetchFollowing();
  });
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
                httpHeaders: AuthService.token == null ? null : {"Authorization": "Bearer ${AuthService.token}"},
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  height: 200,
                  color: theme.colorScheme.surface,
                  child: Icon(Icons.broken_image, color: theme.colorScheme.onSurface),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Chapter ${c.chapterCount}',
                      style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 12),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 4),
                  Text(c.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}