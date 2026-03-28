import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:tapcomic/data/models/comic.dart';
import 'package:tapcomic/data/models/user.dart';
import 'package:tapcomic/data/repos/comic_repo.dart';
import 'package:tapcomic/features/auth/auth_service.dart';
import 'package:tapcomic/features/auth/comic_detail_page.dart';
import '../../data/repos/user_repo.dart';

enum SearchType { comic, user }

class Searchpage extends StatefulWidget {
  const Searchpage({super.key});

  @override
  State<Searchpage> createState() => _SearchpageState();
}

class _SearchpageState extends State<Searchpage> {
  final repo = ComicRepo();
  final userRepo = UserRepo();
  Timer? _debounce;
  final token = AuthService.token;
  SearchType searchType = SearchType.comic;
  List<Comic> filteredComics = [];
  List<User> filteredUsers = [];
  bool isLoading = false;
  final TextEditingController searchController = TextEditingController();

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (query.isEmpty) {
        setState(() { filteredComics = []; filteredUsers = []; });
        return;
      }
      setState(() => isLoading = true);
      try {
        if (searchType == SearchType.comic) {
          final result = await repo.searchComic(query);
          setState(() => filteredComics = result);
        } else {
          final result = await userRepo.searchUser(query);
          setState(() => filteredUsers = result);
        }
      } catch (e) {
        debugPrint("Search error: $e");
      }
      if (mounted) setState(() => isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                "Search",
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => searchType = SearchType.comic),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                          decoration: BoxDecoration(
                            color: searchType == SearchType.comic
                                ? theme.colorScheme.onSurface.withOpacity(0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text("Comic",
                              style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 10)),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => searchType = SearchType.user),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                          decoration: BoxDecoration(
                            color: searchType == SearchType.user
                                ? theme.colorScheme.onSurface.withOpacity(0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text("User",
                              style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 10)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              TextFormField(
                onChanged: _onSearchChanged,
                style: TextStyle(color: theme.colorScheme.onSurface),
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                  hintText: "Search...",
                  hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _empty() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.manage_search_rounded, size: 100,
              color: theme.colorScheme.onSurface.withOpacity(0.2)),
          const SizedBox(height: 12),
          Text("Find something...",
              style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5), fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (searchType == SearchType.comic) {
      if (filteredComics.isEmpty) return _empty();
      return ListView.separated(
        padding: const EdgeInsets.only(bottom: 20),
        itemCount: filteredComics.length,
        separatorBuilder: (_, __) => Divider(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1), height: 32),
        itemBuilder: (context, index) => _buildComicItem(filteredComics[index]),
      );
    } else {
      if (filteredUsers.isEmpty) return _empty();
      return ListView.builder(
        itemCount: filteredUsers.length,
        itemBuilder: (context, index) {
          final user = filteredUsers[index];
          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(user.name,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
          );
        },
      );
    }
  }

  Widget _buildComicItem(Comic c) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => ComicDetailPage(comicId: c.uuid))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: c.url,
              httpHeaders: AuthService.token == null
                  ? null : {"Authorization": "Bearer ${AuthService.token}"},
              width: 90, height: 120, fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(
                width: 90, height: 120,
                color: theme.colorScheme.surface,
                child: Icon(Icons.broken_image,
                    color: theme.colorScheme.onSurface.withOpacity(0.2)),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.title,
                    style: TextStyle(color: theme.colorScheme.onSurface,
                        fontSize: 18, fontWeight: FontWeight.bold),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Text("Chapter ${c.chapterCount}",
                    style: const TextStyle(color: Colors.greenAccent, fontSize: 14)),
                const SizedBox(height: 4),
                Text(c.description,
                    style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.5), fontSize: 12),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}