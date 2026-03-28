import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:tapcomic/data/models/favorite_comic.dart';
import 'package:tapcomic/data/repos/favorite_repo.dart';
import 'package:tapcomic/features/auth/auth_service.dart';
import 'comic_detail_page.dart';

class Library extends StatefulWidget {
  const Library({super.key});

  @override
  State<Library> createState() => _LibraryState();
}

class _LibraryState extends State<Library> {
  final favoriteRepo = FavoriteRepo();
  late Future<List<FavoriteComic>> _future;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

 void _loadFavorites() {
  _future = favoriteRepo.getAll(); // assign ก่อน
  setState(() {}); // แค่ trigger rebuild
}
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        title: Text('My Library',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 30,
                color: theme.colorScheme.onSurface)),
      ),
      body: FutureBuilder<List<FavoriteComic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.redAccent)));
          }

          final favorites = snapshot.data ?? [];

          if (favorites.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star_border, size: 80,
                      color: theme.colorScheme.onSurface.withOpacity(0.2)),
                  const SizedBox(height: 16),
                  Text('you dont have bookmark comic',
                      style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                          fontSize: 18)),
                  const SizedBox(height: 8),
                  Text('click star icon on comic to add to Library',
                      style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.4),
                          fontSize: 14),
                      textAlign: TextAlign.center),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.6,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final fav = favorites[index];
              return InkWell(
                onTap: () async {
                  await Navigator.push(context,
                      MaterialPageRoute(builder: (_) => ComicDetailPage(comicId: fav.uuid)));
                  _loadFavorites();
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          ClipRRect(
                            child: CachedNetworkImage(
                              imageUrl: fav.url,
                              httpHeaders: AuthService.token == null
                                  ? null : {"Authorization": "Bearer ${AuthService.token}"},
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) =>
                                  Image.asset('assets/icon/fakelogo.png', fit: BoxFit.cover),
                            ),
                          ),
                          Positioned(
                            top: 4, right: 4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.star, color: Colors.amber, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(fav.title,
                        style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontSize: 14, fontWeight: FontWeight.w600),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}