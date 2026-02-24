import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tapcomic/data/repos/comment_repo.dart';
import 'package:tapcomic/features/auth/readersetting/readerstyle_setting.dart';
import '../../core/app_settings.dart';
import '../../core/app_setting_scope.dart';
import 'package:tapcomic/data/models/page_model.dart';
import 'package:tapcomic/data/repos/history_repo.dart';
import 'package:tapcomic/data/repos/episode_repo.dart';
import 'package:tapcomic/data/repos/page_repo.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ComicReaderPage extends StatefulWidget {
  final String uuid;
  final String episodeTitle;
  final int episodeNo;
  final String comicId;
  final int episodeId;
 final int totalChapters;
  const ComicReaderPage({
    super.key,
    required this.uuid,
    required this.episodeTitle,
    required this.episodeNo,
    required this.comicId,
    required this.episodeId,
        required this.totalChapters,

  });

  @override
  State<ComicReaderPage> createState() => _ComicReaderPageState();
}

class _ComicReaderPageState extends State<ComicReaderPage> {
  bool _showMenu = false;
  late final PageController _pageController;
  int _pageIndex = 0;

  final _historyRepo = HistoryRepo();
  final _episodeRepo = EpisodeRepo();
  final _pageRepo = PageRepo();
  final _commentRepo = CommentRepo();
   bool _isLoading = false;

  String? _comicId;
  int? _episodeId;
 
  List<PageModel> _pages = [];
  bool _loadingPages = true;
  late final ScrollController _scrollController;
  Timer? _saveTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _comicId = widget.comicId;
    _episodeId = widget.episodeId;
  _scrollController = ScrollController();
  _scrollController.addListener(_onVerticalScroll);
    _loadPages();
  }

void _onVerticalScroll() {
  if (_pages.isEmpty) return;
  
  final screenH = MediaQuery.of(context).size.height;
  final estimatedPage = (_scrollController.offset / screenH).floor();
  
  if (estimatedPage != _pageIndex) {
    _pageIndex = estimatedPage;

    int nextToPreload = _pageIndex + 3; 
    if (nextToPreload < _pages.length) {
       precacheImage(
         CachedNetworkImageProvider(_pages[nextToPreload].imageUrl),
         context,
       );
    }

    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), _saveProgress);
  }
}

Future<void> _loadPages() async {
  final pages = await _pageRepo.fetchPages(
    uuid: widget.uuid,
    chapter: widget.episodeNo,
  );

  if (!mounted) return;

  setState(() {
    _pages = pages;
    _loadingPages = false;
  });


  _startSmartPreload(); 
}

void _startSmartPreload() {
  for (int i = 0; i < _pages.length && i < 10; i++) {
    precacheImage(
      CachedNetworkImageProvider(_pages[i].imageUrl),
      context,
    );
  }
}

  @override
  void dispose() {
   _saveTimer?.cancel();
  _saveProgress();
  _scrollController.dispose();
  _pageController.dispose();
  super.dispose();
  }

  void _toggleMenu() {
    setState(() => _showMenu = !_showMenu);
  }



  Future<void> _saveProgress() async {
    if (_comicId != null && _episodeId != null) {
     await _historyRepo.saveProgress(
  comicUuid: widget.uuid,   
  episodeId: _episodeId!,
  pageNo: _pageIndex,
);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingPages) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    final settings = AppSettingsScope.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _toggleMenu,
            child: _buildReader(settings),
          ),

          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            top: _showMenu ? 0 : -100,
            left: 0,
            right: 0,
            child: AppBar(
              backgroundColor: Colors.black.withOpacity(0.85),
              foregroundColor: Colors.white,
              centerTitle: true,
              title: Column(
                children: [
                  Text(widget.episodeTitle,
                      style: const TextStyle(fontSize: 16)),
                  Text('chapter ${widget.episodeNo}',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.white70)),
                ],
              ),
            ),
          ),

          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            bottom: _showMenu ? 0 : -220,
            left: 0,
            right: 0,
           child: _bottomMenu(context),
          ),
        ],
      ),
    );
  }

  Widget _bottomMenu(BuildContext context) {
  return Container(
    height: 56,
    color: Colors.black.withOpacity(0.9),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: _isLoading 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.skip_previous, color: Colors.white),
          onPressed: _isLoading ? null : _goToPreviousEpisode,
          
          
        ),
        IconButton(
          icon: const Icon(Icons.settings, color: Colors.white),
          onPressed: () => _openReaderSetting(context),
        ),
        IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {
          },
        ),
        IconButton(
           icon: _isLoading 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.skip_next, color: Colors.white),
               onPressed: _isLoading ? null : _goToNextEpisode,
        ),
      ],
    ),
  );
}

  void _openReaderSetting(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color.fromARGB(255, 0, 0, 0),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => const Padding(
      padding: EdgeInsets.all(16),
      child: ReaderstyleSetting(),
    ),
  );
}
Future<void> _goToNextEpisode() async {
  if (widget.episodeNo >= widget.totalChapters) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ไม่มีตอนถัดไป')),
    );
    return;
  }

  await _saveProgress();

  final nextChapter = widget.episodeNo + 1;

  if (!mounted) return;
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => ComicReaderPage(
        uuid: widget.uuid,
        episodeTitle: 'Chapter $nextChapter',
        episodeNo: nextChapter,
        comicId: widget.comicId,
        episodeId: nextChapter,
        totalChapters: widget.totalChapters, 
      ),
    ),
  );
}

Future<void> _goToPreviousEpisode() async {
  if (widget.episodeNo <= 1) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ไม่มีตอนก่อนหน้า')),
    );
    return;
  }

  await _saveProgress();

  final prevChapter = widget.episodeNo - 1;

  if (!mounted) return;
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => ComicReaderPage(
        uuid: widget.uuid,
        episodeTitle: 'Chapter $prevChapter',
        episodeNo: prevChapter,
        comicId: widget.comicId,
        episodeId: prevChapter,
        totalChapters: widget.totalChapters, 
      ),
    ),
  );
}
  Widget _buildReader(AppSettings settings) {
    switch (settings.readerMode) {
      case ReaderMode.vertical:
        return _vertical(_pages);
      case ReaderMode.horizontal:
        return _horizontal(_pages);
      case ReaderMode.tap:
        return _tap(_pages);
    }
  }
Widget _buildImage(String url, {bool isVertical = false}) {
  final double screenWidth = MediaQuery.of(context).size.width;
  final double devicePixelRatio = MediaQuery.of(context).devicePixelRatio;

  return CachedNetworkImage(
    imageUrl: url,
    memCacheWidth: (screenWidth * devicePixelRatio).round(), 
    width: screenWidth,
    fit: BoxFit.fitWidth,
    filterQuality: FilterQuality.low, 
    placeholder: (_, __) => Container(
      height: 400, 
      color: const Color(0xFF1A1A1A),
    ),
    errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
  );
}

Widget _vertical(List<PageModel> pages) {
  return ListView.builder(
    controller: _scrollController,  
    cacheExtent: 1500,             
    itemCount: pages.length,
    itemBuilder: (_, i) => RepaintBoundary(
      key: ValueKey(pages[i].imageUrl),  
      child: _buildImage(pages[i].imageUrl, isVertical: true),
    ),
  );
}


Widget _horizontal(List<PageModel> pages) {
  return PageView.builder(
    controller: _pageController,
    allowImplicitScrolling: true,
    itemCount: pages.length,
   onPageChanged: (i) {
  _pageIndex = i;
  _saveTimer?.cancel();
  _saveTimer = Timer(const Duration(seconds: 2), _saveProgress);
  _preloadAround(i);
},
    itemBuilder: (_, i) => SizedBox.expand( 
      child: _buildImage(pages[i].imageUrl),
    ),
  );
}

  Widget _tap(List<PageModel> pages) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (details) {
        final width = MediaQuery.of(context).size.width;
        final dx = details.globalPosition.dx;

        if (dx < width * 0.33) {
          _prevPage();
        } else if (dx > width * 0.66) {
          _nextPage();
        } else {
          _toggleMenu();
        }
      },
      child: PageView.builder(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: pages.length,
       onPageChanged: (i) {
  _pageIndex = i;
  _saveTimer?.cancel();
  _saveTimer = Timer(const Duration(seconds: 2), _saveProgress);
  _preloadAround(i);
},
       itemBuilder: (_, i) => SizedBox.expand(
  child: _buildImage(pages[i].imageUrl),
),
      ),
    );
  }
void _preloadAround(int index) {
  for (int i = index + 1; i <= index + 2; i++) {
    if (i < _pages.length) {
      precacheImage(
        CachedNetworkImageProvider(_pages[i].imageUrl),
        context,
      );
    }
  }
}
  void _nextPage() {
    if (_pageIndex < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  void _prevPage() {
    if (_pageIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }
}
