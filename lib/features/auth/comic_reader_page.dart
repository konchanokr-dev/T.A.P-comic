import 'dart:async';
import 'dart:convert';
import 'package:tapcomic/data/api/api_service.dart';
import 'package:tapcomic/data/models/comment.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http show get;
import 'package:tapcomic/data/repos/comment_repo.dart';
import 'package:tapcomic/data/repos/vote_repo.dart';
import 'package:tapcomic/features/auth/readersetting/readerstyle_setting.dart';
import 'package:tapcomic/features/auth/reply.dart';
import 'package:tapcomic/features/auth/report_sheet.dart';
import 'package:tapcomic/widget/NameAvatar.dart';
import '../../core/app_settings.dart';
import '../../core/app_setting_scope.dart';
import 'package:tapcomic/data/models/page_model.dart';
import 'package:tapcomic/data/repos/history_repo.dart';
import 'package:tapcomic/data/repos/page_repo.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tapcomic/features/auth/page_comment_sheet.dart';

class ComicReaderPage extends StatefulWidget {
  final String uuid;
  final String episodeTitle;
  final int episodeNo;
   final int comicIntId; 
  final String comicId;
  final int episodeId;
 final int totalChapters;
 final String userUuid;
  const ComicReaderPage({
    super.key,
    required this.uuid,
      required this.comicIntId,   
    required this.userUuid,  

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
List comments = [];
bool _loadingComments = true;
  final _historyRepo = HistoryRepo();
  final _pageRepo = PageRepo();
  final _commentRepo = CommentRepo();
   bool _isLoading = false;
   String? _token;
   int _initialPage = 0; 
   bool? _userVote; // null = ยังไม่โหวต, true = like, false = dislike
final _voteRepo = VoteRepo();
   double _screenHeight = 0;
final TextEditingController _commentController = TextEditingController();
  String? _comicId;
  int? _episodeId;
 int _likeCount = 0;
  int _dislikeCount = 0;
  bool? _currentUserVote;
  List<PageModel> _pages = [];
  bool _loadingPages = true;
  late final ScrollController _scrollController;
 int _currentLikeCount = 0;
  int _currentDislikeCount = 0;
  bool? _currentVoteStatus;
  Timer? _saveTimer;
  String _currentUserName = "";
Map<String, String> userMap = {};
@override
void initState() {
  super.initState();
    
  _pageController = PageController();
  _comicId = widget.comicId;
  _episodeId = widget.episodeId;
  _scrollController = ScrollController();
  _scrollController.addListener(_onVerticalScroll);
  _init(); 
}Future<void> _init() async {
  final prefs = await SharedPreferences.getInstance();
  _token = prefs.getString("accessToken");
  _currentUserName = prefs.getString('userName') ?? "";

_refreshVoteStatus();
 final progress = await _historyRepo.getComicProgress(widget.comicId);
if (progress != null) {
  print("🎬 ประวัติจากเซิร์ฟเวอร์: Chapter ${progress.chapterId}, Page ${progress.pageNumber}");
      debugPrint("currentuser name is" + _currentUserName);

  if (progress.chapterId == widget.episodeId) {
    setState(() {
      _initialPage = progress.pageNumber; 
      _pageIndex = _initialPage;
    });
  }
}
  await _loadPages();   
  await _loadUsers();
  await _loadComments();

if (_initialPage > 0) {
    _jumpToInitialPage(); 
  }
  if (mounted) setState(() {});
  print("Debug: _initialPage value is $_initialPage");

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
        CachedNetworkImageProvider(
  _pages[nextToPreload].pageUrl,
  headers: _token == null
      ? null
      : {
          "Authorization": "Bearer $_token",
        },
),
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
    chapterNo: widget.episodeNo,
  );

  if (!mounted) return;

  setState(() {
    _pages = pages;
    _loadingPages = false;
  });


  _startSmartPreload(); 
}
void _startSmartPreload() {
  for (int i = 0; i < _pages.length && i < 4; i++) {
    precacheImage(
      CachedNetworkImageProvider(
        "${_pages[i].pageUrl}?w=1080",
        headers: {
          "Authorization": "Bearer $_token",
        },
      ),
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
  _commentController.dispose();
  super.dispose();
  }

  void _toggleMenu() {
    setState(() => _showMenu = !_showMenu);
  }



Future<void> _saveProgress() async {
  if (_comicId != null && _episodeId != null) {
    try {
      print("💾 Saving Progress: Comic ${widget.comicId}, Chapter $_episodeId, Page $_pageIndex");
      
      await _historyRepo.saveProgress(
        comicUuid: widget.comicId,   
        episodeId: _episodeId!,      
        pageNo: _pageIndex,          
      );
    } catch (e) {
      print("⚠️ Save Progress Error: $e");
    }
  }
}

  @override
Widget build(BuildContext context) {
  _screenHeight = MediaQuery.of(context).size.height;

  if (_loadingPages) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }

  final settings = AppSettingsScope.of(context);

  return Scaffold(
    backgroundColor: Colors.black,
    resizeToAvoidBottomInset: false, 
    body: Stack(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggleMenu,
          child: _buildReader(settings),
        ),

        AnimatedPositioned(
          duration: const Duration(milliseconds: 200),
          top: _showMenu ? 0 : -120, 
          left: 0,
          right: 0,
          child: Material(
            color: Colors.black.withOpacity(0.9),
            elevation: 5,
            child: SafeArea( 
              bottom: false,
              child: Container(
                height: 60,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.episodeTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            "Chapter ${widget.episodeNo}",
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 48), 
                  ],
                ),
              ),
            ),
          ),
        ),

        AnimatedPositioned(
          duration: const Duration(milliseconds: 200),
          bottom: _showMenu ? 0 : -100,
          left: 0,
          right: 0,
          child: _bottomMenu(context),
        ),
Positioned(
  right: 16,
  bottom: _showMenu ? 72 : 16, 
  child: FloatingActionButton(
    mini: true,
    backgroundColor: Colors.black87,
    onPressed: _openPageComments,
    child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
  ),
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
          onPressed: () {  _openChapterSelect(context);
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
void _openChapterSelect(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF1A1A1A),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollController) => Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "เลือกตอน",
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: widget.totalChapters,
              itemBuilder: (_, index) {
                final chapterNo = index + 1;
                final isCurrent = chapterNo == widget.episodeNo;
                return ListTile(
                  title: Text(
                    "Chapter $chapterNo",
                    style: TextStyle(
                      color: isCurrent ? Theme.of(context).colorScheme.primary : Colors.white,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: isCurrent
                      ? Icon(Icons.play_arrow, color: Theme.of(context).colorScheme.primary)
                      : null,
                  onTap: () async {
                    Navigator.pop(context);
                    if (isCurrent) return;
                    await _saveProgress();
                    if (!mounted) return;
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ComicReaderPage(
                          uuid: widget.uuid,
                          comicIntId: widget.comicIntId,
                          episodeTitle: 'Chapter $chapterNo',
                          episodeNo: chapterNo,
                          userUuid: widget.userUuid,
                          comicId: widget.comicId,
                          episodeId: chapterNo,
                          totalChapters: widget.totalChapters,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}
Future<void> _goToNextEpisode() async {
  if (widget.episodeNo >= widget.totalChapters) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Dont have next chapter')),
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
        comicIntId: widget.comicIntId,
        episodeTitle: 'Chapter $nextChapter',
        episodeNo: nextChapter,
        userUuid: widget.userUuid,
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
        userUuid: widget.userUuid,

        comicIntId: widget.comicIntId,
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
      case ReaderMode.tapUD:
        return _tapUD(_pages);
    }
  }Widget _buildImage(String url, {bool fitContain = false}) {
  final screenWidth = MediaQuery.of(context).size.width;
  final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;

  double maxWidth = screenWidth;

  if (screenWidth > 900) {
    maxWidth = 700;
  }

  return CachedNetworkImage(
    imageUrl: "$url?w=1080",
    cacheKey: url,

    httpHeaders: _token == null
        ? null
        : {
            "Authorization": "Bearer $_token",
          },

    memCacheWidth: (screenWidth * devicePixelRatio * 0.7).round(),
    width: fitContain ? null : maxWidth,
fit: fitContain ? BoxFit.contain : BoxFit.fitWidth,
    fadeInDuration: Duration.zero,
    fadeOutDuration: Duration.zero,
    filterQuality: FilterQuality.low,

    placeholder: (_, __) => Container(
      height: 400,
      color: const Color(0xFF1A1A1A),
    ),

    errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
  );
}
void _jumpToInitialPage() {
  Future.delayed(const Duration(milliseconds: 400), () { 
    if (!mounted) return;

    final settings = AppSettingsScope.of(context);

    if (settings.readerMode == ReaderMode.vertical) {
      if (_scrollController.hasClients) {
        double targetOffset = _initialPage * MediaQuery.of(context).size.height;
        _scrollController.jumpTo(targetOffset);
        print("🚀 [Vertical] Jumped to offset: $targetOffset");
      }
    } 
    
    else {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(_initialPage);
        print("🚀 [Horizontal/Tap] Jumped to page: $_initialPage");
      }
    }
  });
}
Widget _vertical(List<PageModel> pages) {
  return ListView.builder(
    controller: _scrollController,
    cacheExtent: 500,
    itemCount: pages.length + 1, 
    itemBuilder: (_, i) {

      if (i < pages.length) {
        return RepaintBoundary(
          key: ValueKey(pages[i].pageUrl),
          child: _buildImage(pages[i].pageUrl,),
        );
      }

      return SizedBox(
  width: double.infinity,
   child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _voteSection(widget.episodeId), // แสดง vote section ก่อน
          SizedBox(height: 16),    // เว้นระยะห่าง
          _commentSection(),       // ตามด้วย comment section
        ],
      ),
);
    },
  );
}

Widget _horizontal(List<PageModel> pages) {
  return PageView.builder(
    controller: _pageController,
    allowImplicitScrolling: true,
    itemCount: pages.length + 1,
  onPageChanged: (i) {
  _pageIndex = i; 
  
  _saveTimer?.cancel();
  _saveTimer = Timer(const Duration(seconds: 2), _saveProgress);

  if (i < _pages.length) {
    _preloadAround(i);
  }
},
    itemBuilder: (_, i) {

      if (i < pages.length) {
        return SizedBox.expand(
          child: _buildImage(pages[i].pageUrl,fitContain: true),
        );
      }
return SingleChildScrollView(
  child: ConstrainedBox(
    constraints: BoxConstraints(
      minHeight: MediaQuery.of(context).size.height, 
    ),
    child: Padding(
      padding: const EdgeInsets.only(top: 60), 
     child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _voteSection(widget.episodeId), // แสดง vote section ก่อน
          SizedBox(height: 16),    // เว้นระยะห่าง
          _commentSection(),       // ตามด้วย comment section
        ],
      ),
    ),
  ),
);
    },
  );
}Widget _tap(List<PageModel> pages) {
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
      itemCount: pages.length + 1,
    onPageChanged: (i) {
  _pageIndex = i; 
  
  _saveTimer?.cancel();
  _saveTimer = Timer(const Duration(seconds: 2), _saveProgress);

  if (i < _pages.length) {
    _preloadAround(i);
  }
},
      itemBuilder: (_, i) {

        if (i < pages.length) {
          return Center(
  child: _buildImage(pages[i].pageUrl,fitContain: true),
);
        }

    
return SingleChildScrollView(
  child: ConstrainedBox(
    constraints: BoxConstraints(
      minHeight: MediaQuery.of(context).size.height, 
    ),
    child: Padding(
      padding: const EdgeInsets.only(top: 60), 
       child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _voteSection(widget.episodeId), // แสดง vote section ก่อน
          SizedBox(height: 8),    // เว้นระยะห่าง
          _commentSection(),       // ตามด้วย comment section
        ],
      ),
    ),
  ),
);
      },
    ),
  );
}
Widget _tapUD(List<PageModel> pages) {
  return GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTapUp: (details) {
      final height = MediaQuery.of(context).size.height;
      final dx = details.globalPosition.dy;

      if (dx < height * 0.33) {
        _prevPage();
      } else if (dx > height * 0.66) {
        _nextPage();
      } else {
        _toggleMenu();
      }
    },
    child: PageView.builder(
      scrollDirection: Axis.vertical,
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: pages.length + 1,
    onPageChanged: (i) {
  _pageIndex = i; 
  
  _saveTimer?.cancel();
  _saveTimer = Timer(const Duration(seconds: 2), _saveProgress);

  if (i < _pages.length) {
    _preloadAround(i);
  }
},
      itemBuilder: (_, i) {

        if (i < pages.length) {
          return Center(
  child: _buildImage(pages[i].pageUrl,fitContain: true),
);
        }

    
return SingleChildScrollView(
  child: ConstrainedBox(
    constraints: BoxConstraints(
      minHeight: MediaQuery.of(context).size.height, 
    ),
    child: Padding(
      padding: const EdgeInsets.only(top: 60), 
       child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _voteSection(widget.episodeId), // แสดง vote section ก่อน
          SizedBox(height: 16),    // เว้นระยะห่าง
          _commentSection(),       // ตามด้วย comment section
        ],
      ),
    ),
  ),
);
      },
    ),
  );
}
void _preloadAround(int index) {
  for (int i = index + 1; i <= index + 5; i++) {
    if (i < _pages.length) {
      precacheImage(
        CachedNetworkImageProvider(
          "${_pages[i].pageUrl}?w=1080",
          headers: {
            "Authorization": "Bearer $_token",
          },
        ),
        context,
      );
    }
  }
}
  void _nextPage() {
    if (_pageIndex < _pages.length ) {
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
Widget _commentSection() {
  final theme = Theme.of(context);

  return Container(
    width: double.infinity,
    margin: const EdgeInsets.only(top: 40),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: theme.colorScheme.surface,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(30),
      ),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Text(
          "Comments",
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 16),

        Row(
          children: [
         NameAvatar(name: _currentUserName, radius: 18),

            const SizedBox(width: 10),

            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: _commentController,
                  style: TextStyle(color: theme.colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText: "Write Your Comment Here!",
                    hintStyle: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),

            IconButton(
              icon: Icon(Icons.send, color: theme.colorScheme.primary),
              onPressed: _sendComment,
            ),
          ],
        ),

        const SizedBox(height: 20),

        if (_loadingComments)
          Center(
            child: CircularProgressIndicator(
              color: theme.colorScheme.onSurface,
            ),
          )
        else
          ...comments.map((c) => _commentItem(c)).toList(),

        const SizedBox(height: 30),
      ],
    ),
  );
}
Widget _commentItem(CommentModel c) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            NameAvatar(name: c.user?.name ?? 'user', radius: 18),

              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          c.user?.name ?? "user",
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
  onPressed: () => showReportSheet(
    context,
    userUuid: c.user.uuid,
    commentId: c.id,
  ),
  icon: const Icon(Icons.flag_outlined),
  color: theme.colorScheme.onSurface.withOpacity(0.4),
  iconSize: 18,
  padding: EdgeInsets.zero,
  constraints: const BoxConstraints(),
  visualDensity: VisualDensity.compact,
),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      c.text,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Row(
      children: [
        GestureDetector(
          onTap: () async {
            try {
              await _commentRepo.voteComment(
                commentId: c.id,
                vote: true,
              );
              await _loadComments();
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Please login first")),
              );
            }
          },
          child: Icon(
            c.currentUserVote == true
                ? Icons.thumb_up_alt
                : Icons.thumb_up_alt_outlined,
            color: c.currentUserVote == true
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withOpacity(0.5),
            size: 18,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          "${c.likeCount}",
          style: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
        const SizedBox(width: 16),
        GestureDetector(
          onTap: () async {
            try {
              await _commentRepo.voteComment(
                commentId: c.id,
                vote: false,
              );
              await _loadComments();
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Please login first")),
              );
            }
          },
          child: Icon(
            c.currentUserVote == false
                ? Icons.thumb_down_alt
                : Icons.thumb_down_alt_outlined,
            color: c.currentUserVote == false
                ? Colors.red
                : theme.colorScheme.onSurface.withOpacity(0.5),
            size: 18,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          "${c.dislikeCount}",
          style: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      ],
    ),
              TextButton.icon(
                onPressed: () => _openReplyThread(c),
                icon: Icon(
                  Icons.mode_comment_outlined,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                  size: 12,
                ),
                label: Text(
                  "reply",
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
void _openReplyThread(CommentModel comment) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.black,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) {
      return ReplyThreadWidget(
        comment: comment,
        userUuid: widget.userUuid,
      );
    },
  ).then((_) {
    _loadComments(); 
  });
}
Future<void> _loadUsers() async {
  final res = await http.get(
    Uri.parse("https://xacetx123.share.zrok.io/api/users"),
  );

  final data = jsonDecode(res.body);

  if (!mounted) return;

  setState(() {
    for (var u in data) {
      userMap[u["uuid"]] = u["name"];
    }
  });
}

Future<void> _loadComments() async {
  try {
    final data = await _commentRepo.getChapterComments(widget.episodeId);
    
    print("✅ จำนวน comments: ${data.length}");
    print("✅ ข้อมูล: $data");
    
    if (!mounted) return;
    setState(() {
      comments = data;
      _loadingComments = false;
    });
  } catch (e) {
    print("❌ ERROR: $e"); 
    if (!mounted) return;
    setState(() {
      _loadingComments = false;
    });
  }
}
Future<void> _sendComment() async {
  if (_commentController.text.trim().isEmpty) return;

  try {
    await _commentRepo.addChapterComment(
      userUuid: widget.userUuid,
      comicId: widget.comicIntId,
      chapterId: widget.episodeId,
      text: _commentController.text,
    );

    _commentController.clear();

    await _loadComments(); 
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Failed to send comment")),
    );
  }
}
Future<void> _reportComment(CommentModel c) =>
    showReportSheet(context, userUuid: widget.userUuid, commentId: c.id);
void _onPageChanged(int index) {
  _historyRepo.saveProgress(
    comicUuid: widget.comicId,
    episodeId: widget.comicIntId,
    pageNo: index + 1, 
  ).catchError((e) => print("บันทึกไม่สำเร็จ: $e"));
}
void _openPageComments() {
  if (_pageIndex >= _pages.length) return;

  final currentPage = _pages[_pageIndex];

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF1A1A1A),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => PageCommentSheet(
      pageId: currentPage.pageId,       
      pageNo: _pageIndex + 1,
      userUuid: widget.userUuid,
      comicIntId: widget.comicIntId,
      commentRepo: _commentRepo,
    ),
  );
}
//vote devote chapter
Widget _voteSection(int chapterId) {
  final theme = Theme.of(context);
  return  Column(
    children: [
      // ── Header Text ──
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          "How do you feel about this chapter?",
          style: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.8),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
       Row(
    children: [
      // ── ฝั่ง Like ──────────────────────────
      Expanded(
        child: InkWell(
          onTap: () async {
            await _voteRepo.voteChapter(chapterId, true);
            await _refreshVoteStatus();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: _currentVoteStatus == true
                  ? theme.colorScheme.primary.withOpacity(0.15)
                  : Colors.transparent,
              border: Border(
                right: BorderSide(color: Colors.white12, width: 1),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.thumb_up_alt_outlined,
                  color: _currentVoteStatus == true
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withOpacity(0.5),
                  size: 28,
                ),
                const SizedBox(height: 6),
                Text(
                  "$_currentLikeCount",
                  style: TextStyle(
                    color: _currentVoteStatus == true
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      // ── ฝั่ง Dislike ────────────────────────
      Expanded(
        child: InkWell(
          onTap: () async {
            await _voteRepo.voteChapter(chapterId, false);
            await _refreshVoteStatus();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: _currentVoteStatus == false
                  ? Colors.redAccent.withOpacity(0.15)
                  : Colors.transparent,
            ),
            child: Column(
              children: [
                Icon(
                  Icons.thumb_down_alt_outlined,
                  color: _currentVoteStatus == false
                      ? Colors.redAccent
                      : theme.colorScheme.onSurface.withOpacity(0.5),
                  size: 28,
                ),
                const SizedBox(height: 6),
                Text(
                  "$_currentDislikeCount",
                  style: TextStyle(
                    color: _currentVoteStatus == false
                        ? Colors.redAccent
                        : theme.colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
       ),
    ],
  
  );
}

Future<void> _refreshVoteStatus() async {
  final chapterId = widget.episodeId; 

  try {

    final response = await ApiService.get("/comics/${widget.comicId}/chapter"); 

    if (response.statusCode == 200) {
        // แปลง Response Body (List of JSON)
        final List<dynamic> chapterList = jsonDecode(response.body);

        // ค้นหา Chapter ที่เราสนใจจาก List
        final targetChapter = chapterList.firstWhere(
          (chapter) => chapter['id'] == chapterId,
          orElse: () => null,
        );
        
        if (targetChapter != null) {
            if (!mounted) return;
            setState(() {
                _currentLikeCount = targetChapter['likeCount'] ?? 0;
                _currentDislikeCount = targetChapter['dislikeCount'] ?? 0;
                _currentVoteStatus = targetChapter['currentUserVote'];
            });
        } else {
            print("Warning: Target chapter ID $chapterId not found in the response list.");
        }
    } else {
        throw Exception("Failed to refresh chapter list: ${response.statusCode}");
    }

  } catch (e) {
    print("Error loading vote status via list refresh: $e");
  }
}
}