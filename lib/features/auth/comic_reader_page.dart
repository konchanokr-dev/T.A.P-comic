import 'dart:async';
import 'dart:convert';
import 'package:tapcomic/data/models/comment.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http show get, post;
import 'package:tapcomic/data/repos/comment_repo.dart';
import 'package:tapcomic/features/auth/readersetting/readerstyle_setting.dart';
import 'package:tapcomic/features/auth/reply.dart';
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
   int _initialPage = 0; // เก็บหน้าที่อ่านค้างไว้จาก DB
   
bool _isFirstLoad = true;
   double _screenHeight = 0;
final TextEditingController _commentController = TextEditingController();
  String? _comicId;
  int? _episodeId;
 
  List<PageModel> _pages = [];
  bool _loadingPages = true;
  late final ScrollController _scrollController;
  late PageController _ppageController;   // สำหรับ Horizontal & Tap

  Timer? _saveTimer;
  
Map<String, String> userMap = {};
@override
void initState() {
  super.initState();

  _pageController = PageController();
  _comicId = widget.comicId;
  _episodeId = widget.episodeId;
  _scrollController = ScrollController();
  _scrollController.addListener(_onVerticalScroll);

  _init(); // โหลด token ก่อน
}Future<void> _init() async {
  final prefs = await SharedPreferences.getInstance();
  _token = prefs.getString("accessToken");

 final progress = await _historyRepo.getComicProgress(widget.comicId);
if (progress != null) {
  print("🎬 ประวัติจากเซิร์ฟเวอร์: Chapter ${progress.chapterId}, Page ${progress.pageNumber}");
  
  if (progress.chapterId == widget.episodeId) {
    setState(() {
      // ⚠️ ระวัง: ใน Log คุณบันทึกว่า "Page 3" 
      // ต้องดูว่าใน Model ReadingHistory ใช้ชื่อว่า .pageNo หรือ .pageNumber
      _initialPage = progress.pageNumber; 
      _pageIndex = _initialPage;
    });
  }
}
  // 2. โหลดข้อมูลอื่นๆ ตามลำดับ
  await _loadPages();   
  await _loadUsers();
  await _loadComments();

  // 3. สำคัญ: สั่งให้กระโดดไปยังหน้าที่ค้างไว้หลังจากโหลด Pages เสร็จแล้ว
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
        comicUuid: widget.comicId,   // ใช้ String UUID ตาม Repo
        episodeId: _episodeId!,      // ID ของตอน (ควรเป็น Primary Key จาก DB)
        pageNo: _pageIndex,          // ส่ง index ปัจจุบัน (0, 1, 2...)
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
    // เพิ่มบรรทัดนี้เพื่อป้องกัน Keyboard ดันหน้าจอจนพัง
    resizeToAvoidBottomInset: false, 
    body: Stack(
      children: [
        // 1. ส่วนเนื้อหา (Reader)
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggleMenu,
          child: _buildReader(settings),
        ),

        // 2. Custom Top Menu (แก้แทน AppBar ที่ Error)
        AnimatedPositioned(
          duration: const Duration(milliseconds: 200),
          top: _showMenu ? 0 : -120, // ถ้าซ่อนให้ดันขึ้นไปพ้นจอ
          left: 0,
          right: 0,
          child: Material(
            color: Colors.black.withOpacity(0.9),
            elevation: 5,
            child: SafeArea( // กัน Notch รอยบาก
              bottom: false,
              child: Container(
                height: 60, // ล็อกความสูงแน่นอน แก้ปัญหา RenderBox not laid out
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
                    const SizedBox(width: 48), // เพื่อให้ Title อยู่ตรงกลาง
                  ],
                ),
              ),
            ),
          ),
        ),

        // 3. Bottom Menu
        AnimatedPositioned(
          duration: const Duration(milliseconds: 200),
          bottom: _showMenu ? 0 : -100,
          left: 0,
          right: 0,
          child: _bottomMenu(context),
        ),
        // Stack children เพิ่มต่อจาก Bottom Menu
Positioned(
  right: 16,
  bottom: _showMenu ? 72 : 16, // ขยับขึ้นเมื่อ menu โชว์
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
    }
  }Widget _buildImage(String url, {bool isVertical = false}) {
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
    width: maxWidth,
    fit: BoxFit.fitWidth,
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
  Future.delayed(const Duration(milliseconds: 400), () { // เพิ่ม delay นิดหน่อยให้ชัวร์ว่า Render เสร็จ
    if (!mounted) return;

    // ดึงโหมดปัจจุบันจาก AppSettings
    final settings = AppSettingsScope.of(context);

    // 1. โหมด Vertical (แนวตั้ง)
    if (settings.readerMode == ReaderMode.vertical) {
      if (_scrollController.hasClients) {
        // ใช้ความสูงหน้าจอในการคำนวณจุดเลื่อน
        double targetOffset = _initialPage * MediaQuery.of(context).size.height;
        _scrollController.jumpTo(targetOffset);
        print("🚀 [Vertical] Jumped to offset: $targetOffset");
      }
    } 
    
    // 2. โหมด Horizontal หรือ Tap (ใช้ PageView ทั้งคู่)
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
    itemCount: pages.length + 1, // + comment
    itemBuilder: (_, i) {

      /// ถ้า index เป็นหน้าการ์ตูน
      if (i < pages.length) {
        return RepaintBoundary(
          key: ValueKey(pages[i].pageUrl),
          child: _buildImage(pages[i].pageUrl, isVertical: true),
        );
      }

      /// ถ้า index สุดท้าย = comment 
      return SizedBox(
  width: double.infinity,
  child: _commentSection(),
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
  _pageIndex = i; // อัปเดต index ปัจจุบัน
  
  // ยกเลิก Timer เก่าและเริ่มนับใหม่ 2 วินาทีค่อยบันทึก (เพื่อไม่ให้ยิง API บ่อยเกินไป)
  _saveTimer?.cancel();
  _saveTimer = Timer(const Duration(seconds: 2), _saveProgress);

  if (i < _pages.length) {
    _preloadAround(i);
  }
},
    itemBuilder: (_, i) {

      /// หน้าการ์ตูน
      if (i < pages.length) {
        return SizedBox.expand(
          child: _buildImage(pages[i].pageUrl),
        );
      }
    // ตัวอย่างในโหมด _horizontal หรือ _tap
return SingleChildScrollView(
  child: ConstrainedBox(
    constraints: BoxConstraints(
      // กำหนดความสูงขั้นต่ำให้เท่ากับหน้าจอ เพื่อไม่ให้ Layout คำนวณเป็น 0
      minHeight: MediaQuery.of(context).size.height, 
    ),
    child: Padding(
      padding: const EdgeInsets.only(top: 60), 
      child: _commentSection(),
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
  _pageIndex = i; // อัปเดต index ปัจจุบัน
  
  // ยกเลิก Timer เก่าและเริ่มนับใหม่ 2 วินาทีค่อยบันทึก (เพื่อไม่ให้ยิง API บ่อยเกินไป)
  _saveTimer?.cancel();
  _saveTimer = Timer(const Duration(seconds: 2), _saveProgress);

  if (i < _pages.length) {
    _preloadAround(i);
  }
},
      itemBuilder: (_, i) {

        /// page
        if (i < pages.length) {
          return Center(
  child: _buildImage(pages[i].pageUrl),
);
        }

    
       // ตัวอย่างในโหมด _horizontal หรือ _tap
return SingleChildScrollView(
  child: ConstrainedBox(
    constraints: BoxConstraints(
      // กำหนดความสูงขั้นต่ำให้เท่ากับหน้าจอ เพื่อไม่ให้ Layout คำนวณเป็น 0
      minHeight: MediaQuery.of(context).size.height, 
    ),
    child: Padding(
      padding: const EdgeInsets.only(top: 60), 
      child: _commentSection(),
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
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.only(top: 40), // เว้นจากรูปการ์ตูน
    padding: const EdgeInsets.all(16),

    decoration: BoxDecoration(
      color: const Color(0xFF1A1A1A),
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(30),
      ),
    ),

    child: Column(
      mainAxisSize: MainAxisSize.min, // ⭐ สำคัญ
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        const Text(
          "Comments",
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 16),

        /// ช่องพิมพ์คอมเมนต์
        Row(
          children: [
            const CircleAvatar(radius: 18),
            const SizedBox(width: 10),

            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: _commentController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: "Write Your Comment Here!",
                    hintStyle: TextStyle(color: Colors.white54),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),

            IconButton(
              icon: const Icon(Icons.send, color: Colors.greenAccent),
              onPressed: _sendComment,
            ),
          ],
        ),

        const SizedBox(height: 20),

        /// loading
        if (_loadingComments)
          const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),

        /// comment list
        ...comments.map((c) => _commentItem(c)).toList(),

        const SizedBox(height: 30),
      ],
    ),
  );
}
Widget _buildCommentInput() {
  return Row(
    children: [
      Expanded(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white10),
          ),
          child: TextField(
            controller: _commentController,
            style: const TextStyle(color: Colors.white),
            minLines: 1,
            maxLines: 3, // ให้พิมพ์ได้หลายบรรทัดแต่จำกัดความสูง
            decoration: const InputDecoration(
              hintText: "Write a comment...",
              hintStyle: TextStyle(color: Colors.white38),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              border: InputBorder.none,
            ),
          ),
        ),
      ),
      const SizedBox(width: 8),
      IconButton(
        onPressed: _sendComment,
        icon: const Icon(Icons.send, color: Colors.blueAccent),
      ),
    ],
  );
}
Widget _commentItem(CommentModel c) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12), // ระยะห่างระหว่างกล่อง
    padding: const EdgeInsets.all(10), // ระยะห่างภายในกล่อง
    decoration: BoxDecoration(
      color: const Color(0xFF333333), // 👈 ใส่สีพื้นหลังตรงนี้ (สีเทาเข้มแบบในรูป)
      borderRadius: BorderRadius.circular(20), // ความมนของมุมกล่อง
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white24, // สีวงกลมรูปโปรไฟล์
            ),
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
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // ปุ่ม Report มุมขวาบน
                      GestureDetector(
                        onTap: () => _reportComment(c),
                        child: const Text(
                          "report",
                          style: TextStyle(color: Colors.redAccent, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    c.text,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        // ส่วนล่าง: Like / Dislike / Reply
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.thumb_up_alt_outlined, color: Colors.white70, size: 18),
                const SizedBox(width: 4),
                const Text("40", style: TextStyle(color: Colors.white70)),
                const SizedBox(width: 16),
                const Icon(Icons.thumb_down_alt_outlined, color: Colors.white70, size: 18),
              ],
            ),
            TextButton.icon(
              onPressed: () => _openReplyThread(c),
              icon: const Icon(Icons.mode_comment_outlined, color: Colors.white70, size: 12),
              label: const Text("reply", style: TextStyle(color: Colors.white70)),
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
    print("❌ ERROR: $e"); // ดู error ตรงนี้
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

    await _loadComments(); // ✅ ใส่ await ตรงนี้
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Failed to send comment")),
    );
  }
}
Future<void> _reportComment(CommentModel c) async {
  try {

    await http.post(
      Uri.parse("https://xacetx123.share.zrok.io/api/report"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "uuid": widget.userUuid,
        "commentId": c.id,
        "reason": "spam"
      }),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Reported successfully")),
    );

  } catch (e) {

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Report failed")),
    );

  }
}
void _onPageChanged(int index) {
  // บันทึกหน้าปัจจุบันไปยัง Server
  // index + 1 เพราะ page ปกติเริ่มจาก 1
  _historyRepo.saveProgress(
    comicUuid: widget.comicId,
    episodeId: widget.comicIntId,
    pageNo: index + 1, 
  ).catchError((e) => print("บันทึกไม่สำเร็จ: $e"));
}
void _openPageComments() {
  // ตรวจว่า index ปัจจุบันไม่เกิน pages
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
      pageId: currentPage.pageNumber,       // ต้องมี id ใน PageModel
      pageNo: _pageIndex + 1,
      userUuid: widget.userUuid,
      comicIntId: widget.comicIntId,
      commentRepo: _commentRepo,
    ),
  );
}

}
