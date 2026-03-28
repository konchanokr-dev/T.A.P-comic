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
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Reading history'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: theme.colorScheme.surface,
                  title: Text('Delete all?', style: TextStyle(color: theme.colorScheme.onSurface)),
                  content: Text('cannot recovery', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7))),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('cancel')),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('delete')),
                  ],
                ),
              );
              if (confirm == true) {
                await historyRepo.clearAllHistory();
                setState(() => _future = historyRepo.getRecentHistoryFull());
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
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
          }
          final histories = snapshot.data ?? [];
          if (histories.isEmpty) {
            return Center(
              child: Text('NO reading history',
                  style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7))),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: histories.length,
            itemBuilder: (context, index) {
              final h = histories[index];
              return InkWell(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => ComicDetailPage(comicId: h.comicUuid))),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        child: h.coverPath != null && h.coverPath!.startsWith('http')
                            ? CachedNetworkImage(
                                imageUrl: h.coverPath!,
                                httpHeaders: AuthService.token == null ? null : {"Authorization": "Bearer ${AuthService.token}"},
                                width: 80, height: 120, fit: BoxFit.cover,
                                placeholder: (_, __) => const SizedBox(width: 60, height: 80, child: Center(child: CircularProgressIndicator())),
                                errorWidget: (_, __, ___) => const Icon(Icons.error),
                              )
                            : Image.asset('assets/icon/fakelogo.png', width: 60, height: 80, fit: BoxFit.cover),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(h.comicTitle ?? 'Unknown',
                                style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.bold),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text('EP.${h.chapterId}',
                                style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7), fontSize: 14),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
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