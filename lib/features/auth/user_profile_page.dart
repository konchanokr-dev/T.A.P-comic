import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:tapcomic/data/models/comic.dart';
import 'package:tapcomic/data/models/user.dart';
import 'package:tapcomic/data/repos/user_repo.dart';
import 'package:tapcomic/features/auth/auth_service.dart';
import 'package:tapcomic/features/auth/comic_detail_page.dart';

class UserProfilePage extends StatefulWidget {
  final User user;
  const UserProfilePage({super.key, required this.user});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final _userRepo = UserRepo();
bool _isFriend = false;
bool _loadingAdd = false;
  late Future<List<Comic>>? _recentReadFuture;
  late Future<List<Comic>>? _followedComicsFuture;

  @override
  void initState() {
    super.initState();
    debugPrint(' UserProfilePage uuid = "${widget.user.uuid}"');
    debugPrint(' UserProfilePage name = "${widget.user.name}"');
  _checkFriendStatus();

    
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: theme.colorScheme.surface,
                      child: Icon(Icons.person,
                          size: 48,
                          color: theme.colorScheme.onSurface.withOpacity(0.5)),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.user.name,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  _loadingAdd
  ? const CircularProgressIndicator()
  : ElevatedButton.icon(
      onPressed: _toggleFriend,
      icon: Icon(_isFriend ? Icons.person_remove : Icons.person_add),
      label: Text(_isFriend ? 'Remove Friend' : 'Add Friend'),
    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── Recent Read ──────────────────────────────────────────
              _sectionTitle(context, 'Recent read'),
              const SizedBox(height: 12),
              if (!_isFriend)
  _lockedState(context, 'Add friend to see this user information')
else if (_recentReadFuture == null)
  const SizedBox(height: 60, child: Center(child: CircularProgressIndicator()))
else
             FutureBuilder<List<Comic>>(
  future: _recentReadFuture,
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const SizedBox(
        height: 260,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (snapshot.hasError) {
      return _errorState(context, 'fail to load history\n${snapshot.error}');
    }

    final comics = snapshot.data ?? [];
    if (comics.isEmpty) {
      return _emptyState(context, 'dont have reading history');
    }

    return SizedBox(
      height: 260,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: comics.length,
        itemBuilder: (_, i) => _comicCard(context, comics[i]),
      ),
    );
  },
),

              const SizedBox(height: 28),

              // ── Followed Comics ──────────────────────────────────────
          
              _sectionTitle(context, 'Followed'),
              const SizedBox(height: 12),
                  if (!_isFriend)
  _lockedState(context, '')
else if (_followedComicsFuture == null)
  const SizedBox(height: 60, child: Center(child: CircularProgressIndicator()))
else
              FutureBuilder<List<Comic>>(
  future: _followedComicsFuture,
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const SizedBox(
        height: 260,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (snapshot.hasError) {
      return _errorState(context, 'โหลด Followed ไม่สำเร็จ\n${snapshot.error}');
    }

    final comics = snapshot.data ?? [];
    if (comics.isEmpty) {
      return _emptyState(context, 'ยังไม่มีการติดตาม');
    }

    return SizedBox(
      height: 260,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: comics.length,
        itemBuilder: (_, i) => _comicCard(context, comics[i]),
      ),
    );
  },
),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ── Widgets ────────────────────────────────────────────────────────

  Widget _sectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: TextStyle(
        color: theme.colorScheme.onSurface,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _emptyState(BuildContext context, String msg) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 60,
      child: Center(
        child: Text(
          msg,
          style: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.4),
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _errorState(BuildContext context, String msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        msg,
        style: const TextStyle(color: Colors.redAccent, fontSize: 13),
      ),
    );
  }

  Widget _comicCard(BuildContext context, Comic c) {
  final theme = Theme.of(context);
  return InkWell(
    borderRadius: BorderRadius.circular(8),
    onTap: () => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ComicDetailPage(comicId: c.uuid)),
    ),
    child: Container(
      width: 150, 
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8), 
            child: CachedNetworkImage(
              imageUrl: c.url,
              httpHeaders: AuthService.token == null
                  ? null
                  : {'Authorization': 'Bearer ${AuthService.token}'},
              height: 200, 
              width: double.infinity,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(
                height: 200,
                color: theme.colorScheme.surface,
                child: Icon(Icons.broken_image,
                    color: theme.colorScheme.onSurface),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chapter ${c.chapterCount}',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  c.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
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

  
Future<void> _toggleFriend() async {
  setState(() => _loadingAdd = true);
  try {
    final isNowFriend = await _userRepo.addFriend(
      AuthService.userUuid!, 
      widget.user.uuid,
    );
    
    setState(() {
      _isFriend = isNowFriend;
      if (isNowFriend) {
        _recentReadFuture = _userRepo.getUserRecentRead(widget.user.uuid, limit: 5);
        _followedComicsFuture = _userRepo.getUserFavorites(widget.user.uuid);
      }
    });
  } catch (e) {
    debugPrint('❌ $e');
  }
  if (mounted) setState(() => _loadingAdd = false);
}
Future<void> _checkFriendStatus() async {
  final myUuid = AuthService.userUuid;
  debugPrint('🔍 _checkFriendStatus called');
  debugPrint('🔍 myUuid: $myUuid');
  debugPrint('🔍 targetUuid: ${widget.user.uuid}');

  if (myUuid == null) {
    debugPrint('❌ myUuid is null! AuthService.userUuid ไม่ได้ถูก set');
    return;
  }

  final result = await _userRepo.isFriend(myUuid, widget.user.uuid);
  debugPrint('🔍 isFriend result: $result');

  if (mounted) {
    setState(() {
      _isFriend = result;
      if (result) {
        _recentReadFuture = _userRepo.getUserRecentRead(widget.user.uuid, limit: 5);
        _followedComicsFuture = _userRepo.getUserFavorites(widget.user.uuid);
      }
    });
  }
}
Widget _lockedState(BuildContext context, String msg) {
  final theme = Theme.of(context);
  return SizedBox(
    height: 60,
    child: Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline,
              size: 16,
              color: theme.colorScheme.onSurface.withOpacity(0.3)),
          const SizedBox(width: 6),
          Text(
            msg,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.4),
              fontSize: 14,
            ),
          ),
        ],
      ),
    ),
  );
}
}