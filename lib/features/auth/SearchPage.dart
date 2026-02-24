import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tapcomic/data/models/comic.dart';
import 'package:tapcomic/data/repos/comic_repo.dart';
import 'package:tapcomic/features/auth/comic_detail_page.dart';

class Searchpage extends StatefulWidget {
  const Searchpage({super.key});

  @override
  State<Searchpage> createState() => _SearchpageState();
}

class _SearchpageState extends State<Searchpage> {
  final repo = ComicRepo();
  String keyword = "";
  Timer? _debounce;
List<Comic> allComics = [];
List<Comic> filteredComics = [];
  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  "Search Comic",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
             onChanged: (value) {
  setState(() {
    filteredComics = allComics.where((c) =>
      c.title.toLowerCase().contains(value.toLowerCase())
    ).toList();
  });
},
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Search title",
                  prefixIcon:
                      const Icon(Icons.search, color: Color(0xFFA6A6A6)),
                  hintStyle: const TextStyle(color: Color(0xFFA6A6A6)),
                  filled: true,
                  fillColor: const Color(0xFF484848),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
           child: filteredComics.isEmpty
      ? const Center(
          child: Text(
            'No comics found',
            style: TextStyle(color: Colors.white70),
          ),
        )
      : ListView.builder(
          itemCount: filteredComics.length,
          itemBuilder: (context, index) {
            return _buildComicCard(filteredComics[index]);
          },
        ),
                      ),
            ]
          )
        )
      )
          );
                  }
               
  
Future<void> loadComics() async {
  final result = await repo.fetchAllComics(); 
  setState(() {
    allComics = result;
    filteredComics = result;
  });
}
  Widget _buildComicCard(Comic c) {
    final screenWidth = MediaQuery.of(context).size.width;
        final cardWidth = screenWidth * 0.4; 
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
        
        width: cardWidth*0.5,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                c.url,
                height: cardWidth * 1.2,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: cardWidth *1.2,
                    color: Colors.grey[800],
                    child: const Icon(
                      Icons.broken_image,
                      color: Colors.white,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chapter ${c.chapterCount}',
                    style: const TextStyle(
                      color: Color(0xFF959595),
                      fontSize: 12,
                    ),
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