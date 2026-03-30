import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:tapcomic/data/models/comic.dart';
import 'package:tapcomic/data/models/genre.dart';
import 'package:tapcomic/data/models/user.dart';
import 'package:tapcomic/data/repos/comic_repo.dart';
import 'package:tapcomic/features/auth/auth_service.dart';
import 'package:tapcomic/features/auth/comic_detail_page.dart';
import 'package:tapcomic/features/auth/user_profile_page.dart';
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
List<Genre> _genres = [];
Set<int> _selectedGenreIds = {};
  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
@override
void initState() {
  super.initState();
  _loadGenres();
}

Future<void> _loadGenres() async {
  final genres = await repo.getGenres();
  setState(() => _genres = genres);
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
              if (searchType == SearchType.comic)
  Align(
    alignment: Alignment.centerLeft,
    child: GestureDetector(
      onTap: _showFilterSheet,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: _selectedGenreIds.isNotEmpty
              ? theme.colorScheme.onSurface.withOpacity(0.2)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.tune_rounded,
                size: 16, color: theme.colorScheme.onSurface),
            const SizedBox(width: 6),
            Text(
              _selectedGenreIds.isEmpty
                  ? 'Filter'
                  : 'Filter (${_selectedGenreIds.length})',
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ),
  ),              const SizedBox(height: 20),

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
      return ListView.separated(
        padding: const EdgeInsets.only(bottom: 20),
        itemCount: filteredUsers.length,
        separatorBuilder: (_, __) => Divider(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1), height: 1),
        itemBuilder: (context, index) => _buildUserItem(filteredUsers[index]),
      );
    }
  }

  Widget _buildUserItem(User user) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => UserProfilePage(user: user)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: theme.colorScheme.surface,
              child: Icon(Icons.person,
                  color: theme.colorScheme.onSurface.withOpacity(0.5)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                user.name,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.chevron_right,
                color: theme.colorScheme.onSurface.withOpacity(0.3)),
          ],
        ),
      ),
    );
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

void _showFilterSheet() {
  final theme = Theme.of(context);
  showModalBottomSheet(
    context: context,
    backgroundColor: theme.scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => StatefulBuilder(
      builder: (context, setSheetState) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter by Genre',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_selectedGenreIds.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      setSheetState(() => _selectedGenreIds.clear());
                      setState(() {});
                      _onSearchChanged(searchController.text);
                    },
                    child: Text(
                      'Clear',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Genre Grid
            Flexible(
              child: GridView.builder(
                shrinkWrap: true,
                itemCount: _genres.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 2.5,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemBuilder: (_, i) {
                  final genre = _genres[i];
                  final selected = _selectedGenreIds.contains(genre.id);
                  return GestureDetector(
                    onTap: () {
                      setSheetState(() {
                        if (selected) {
                          _selectedGenreIds.remove(genre.id);
                        } else {
                          _selectedGenreIds.add(genre.id);
                        }
                      });
                      setState(() {});
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: selected
                            ? theme.colorScheme.onSurface.withOpacity(0.15)
                            : theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected
                              ? theme.colorScheme.onSurface.withOpacity(0.5)
                              : Colors.transparent,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          genre.name,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontSize: 12,
                            fontWeight: selected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // ── Apply button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.onSurface.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  if (_selectedGenreIds.isNotEmpty) {
                    _filterByGenre();
                  } else {
                    _onSearchChanged(searchController.text);
                  }
                },
                child: Text(
                  'Apply',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
Future<void> _filterByGenre() async {
  setState(() => isLoading = true);
  try {
    final result = await repo.filterByGenre(_selectedGenreIds);
    setState(() => filteredComics = result);
  } catch (e) {
    debugPrint('Filter error: $e');
  }
  setState(() => isLoading = false);
}
}