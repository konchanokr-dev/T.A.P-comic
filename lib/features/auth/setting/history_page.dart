import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:tapcomic/data/repos/history_repo.dart';
import 'package:tapcomic/data/models/reading_history.dart';
import 'package:tapcomic/features/auth/auth_service.dart';
import 'package:tapcomic/features/auth/comic_detail_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final historyRepo = HistoryRepo();
  late Future<List<ReadingHistory>> _future;

  @override
  void initState() {
    super.initState();
    _future = historyRepo.getRecentHistoryFull();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF171717),
      appBar: AppBar(
        backgroundColor: Color(0xFF171717),
        foregroundColor: Colors.white,
        title: const Text('Reading history'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Delete all?'),
                  content: const Text('cannot recovery'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('cancle'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('delete'),
                    ),
                  ],
                ),
              );
              
              if (confirm == true) {
                await historyRepo.clearAllHistory();
                setState(() {
                  _future = historyRepo.getRecentHistoryFull();
                });
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<List<ReadingHistory>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }

          final histories = snapshot.data ?? [];

          if (histories.isEmpty) {
            return const Center(
              child: Text(
                'NO reading history',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: histories.length,
            
            itemBuilder: (context, index) {
              final h = histories[index];
              
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ComicDetailPage(comicId: h.comicUuid),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                  ),
                  child: Row(
                    children: [
                     ClipRRect(
  child: h.coverPath != null && h.coverPath!.startsWith('http')
      ? CachedNetworkImage(
          imageUrl: h.coverPath!,
           httpHeaders: AuthService.token == null
      ? null
      : {
          "Authorization": "Bearer ${AuthService.token}",
        },
          width: 80,
          height: 120,
          fit: BoxFit.cover,
          placeholder: (context, url) =>
              const SizedBox(
                width: 60,
                height: 80,
                child: Center(child: CircularProgressIndicator()),
              ),
          errorWidget: (context, url, error) =>
              const Icon(Icons.error),
        )
      : Image.asset(
          'assets/icon/fakelogo.png',
          width: 60,
          height: 80,
          fit: BoxFit.cover,
        ),
),
                      const SizedBox(width: 12),
                      
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              h.comicTitle ?? 'Unknown',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            
                            const SizedBox(height: 4),
                            
                            Text(
                              'EP.${h.chapterId} ',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            
                            const SizedBox(height: 8),
                            
                     
                            
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}