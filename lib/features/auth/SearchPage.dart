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
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

 
Future<void> search() async {
  final result = await ComicRepo().searchComic(searchController.text);

  setState(() {
   filteredComics = result;
  });
}
  // Trigger search logic only when typing
void _onSearchChanged(String query) {
  if (_debounce?.isActive ?? false) _debounce?.cancel();

  _debounce = Timer(const Duration(milliseconds: 300), () async {

    if (query.isEmpty) {
      setState(() {
        filteredComics = [];
        filteredUsers = [];
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {

      if (searchType == SearchType.comic) {

        final result = await repo.searchComic(query);

        setState(() {
          filteredComics = result;
        });

      } else {

        final result = await userRepo.searchUser(query);

        setState(() {
          filteredUsers = result;
        });

      }

    } catch (e) {
      debugPrint("Search error: $e");
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }

  });
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF171717),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                "Search",
                style: TextStyle(
                  color: Colors.white, 
                  fontSize: 32, 
                  fontWeight: FontWeight.bold
                ),
              ),
              const SizedBox(height: 8),
  
                        Align(
  alignment: Alignment.centerLeft,
  child: Container(
  padding: const EdgeInsets.all(4),
  decoration: BoxDecoration(
    color: const Color(0xFF1E1E1E),
    borderRadius: BorderRadius.circular(20),
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [

      // Comic button
      GestureDetector(
        onTap: () {
          setState(() {
            searchType = SearchType.comic;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          decoration: BoxDecoration(
            color: searchType == SearchType.comic
                ? Colors.grey[700]
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Text(
            "Comic",
            style: TextStyle(color: Colors.white, fontSize: 10),
          ),
        ),
      ),


      // User button
      GestureDetector(
        onTap: () {
          setState(() {
            searchType = SearchType.user;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          decoration: BoxDecoration(
            color: searchType == SearchType.user
                ? Colors.grey[700]
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Text(
            "User",
            style: TextStyle(color: Colors.white, fontSize: 10),
          ),
        ),
      ),
    ],
  ),
  ),
),

      const SizedBox(height: 20),

              // Search Input Field
              TextFormField(
                onChanged: _onSearchChanged,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF1E1E1E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Dynamic Result View
              Expanded(
                child: _buildBody(),
              ),
            ],
          ),
        ),
      ),
    );
  }
Widget _empty() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.manage_search_rounded,
            size: 100,
            color: Colors.grey[800]),
        const SizedBox(height: 12),
        const Text(
          "Find something...",
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      ],
    ),
  );
}
  Widget _buildBody() {

  if (isLoading) {
    return const Center(
      child: CircularProgressIndicator(color: Colors.green),
    );
  }

  if (searchType == SearchType.comic) {

    if (filteredComics.isEmpty) {
      return _empty();
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: filteredComics.length,
      separatorBuilder: (_, __) =>
          const Divider(color: Colors.white10, height: 32),
      itemBuilder: (context, index) =>
          _buildComicItem(filteredComics[index]),
    );

  } else {

    if (filteredUsers.isEmpty) {
      return _empty();
    }

    return ListView.builder(
      itemCount: filteredUsers.length,
      itemBuilder: (context, index) {
        final user = filteredUsers[index];

        return ListTile(
          leading: const CircleAvatar(
            child: Icon(Icons.person),
          ),
          title: Text(
            user.name,
            style: const TextStyle(color: Colors.white),
          ),
        );
      },
    );

  }
}



  Widget _buildComicItem(Comic c) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ComicDetailPage(comicId: c.uuid)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child:   CachedNetworkImage(
                 imageUrl: c.url,
  httpHeaders: AuthService.token == null
      ? null
      : {
          "Authorization": "Bearer ${AuthService.token}",
        },
              width: 90, height: 120, fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(
                width: 90, height: 120, 
                color: Colors.grey[900], 
                child: const Icon(Icons.broken_image, color: Colors.white24)
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.title, 
                  style: const TextStyle(
                    color: Colors.white, 
                    fontSize: 18, 
                    fontWeight: FontWeight.bold
                  ), 
                  maxLines: 2, 
                  overflow: TextOverflow.ellipsis
                ),
                const SizedBox(height: 6),
                Text(
                  "Chapter ${c.chapterCount}", 
                  style: const TextStyle(color: Colors.greenAccent, fontSize: 14)
                ),
                const SizedBox(height: 4),
                Text(
                  c.description, 
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}