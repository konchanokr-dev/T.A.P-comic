import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:tapcomic/data/models/comic.dart';
import 'package:tapcomic/features/auth/auth_service.dart';
import 'comic_detail_page.dart';

class SeeAllPage extends StatelessWidget {
  final String title;
  final Future<List<Comic>> future;

  const SeeAllPage({super.key, required this.title, required this.future});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(title, style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold)),
      ),
      body: FutureBuilder<List<Comic>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
          }
          final comics = snapshot.data ?? [];
          if (comics.isEmpty) {
            return Center(child: Text('No comics found', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7))));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: comics.length,
            itemBuilder: (context, index) => _buildComicRow(context, comics[index]),
          );
        },
      ),
    );
  }

  Widget _buildComicRow(BuildContext context, Comic c) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ComicDetailPage(comicId: c.uuid))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: c.url,
                httpHeaders: AuthService.token == null ? null : {"Authorization": "Bearer ${AuthService.token}"},
                width: 80,
                height: 110,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  width: 80, height: 110,
                  color: theme.colorScheme.surface,
                  child: Icon(Icons.broken_image, color: theme.colorScheme.onSurface),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text('Chapter ${c.chapterCount}',
                    style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5), fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: theme.colorScheme.onSurface.withOpacity(0.4)),
          ],
        ),
      ),
    );
  }
}