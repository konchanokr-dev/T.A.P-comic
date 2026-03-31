import 'dart:convert';
import 'package:http/http.dart';
import 'package:tapcomic/data/api/api_service.dart';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tapcomic/data/models/user.dart';
import 'package:tapcomic/features/auth/about_page.dart';
import 'package:tapcomic/features/auth/auth_service.dart';
import 'package:tapcomic/features/auth/help_page.dart';
import 'package:tapcomic/features/auth/user_profile_page.dart';
import 'package:tapcomic/widget/NameAvatar.dart';
import 'history_page.dart';
import '../login.dart';
import '../../../core/app_setting_scope.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String username = 'Loading...';
List _friends = [];
int _friendCount = 0;
bool _isPrivate = false;

  @override
  void initState() {
    super.initState();
    _loadFriends();
    _loadUsername();
     _loadPrivateStatus();
  }
 Future<void> _loadPrivateStatus() async {
  final prefs = await SharedPreferences.getInstance();
  setState(() {
    _isPrivate = prefs.getBool('isPrivate') ?? false;
  });
}

Future<void> _togglePrivate() async {
  try {
    final res = await ApiService.patch("/users/private");
    print("status: ${res.statusCode}"); // ดู status
    print("body: ${res.body}");         // ดู response
     final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    print("token: $token");
    if (res.statusCode == 200) {
      final newValue = !_isPrivate;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isPrivate', newValue);
      setState(() => _isPrivate = newValue);
    }
  } catch (e) {
    print("toggle private error: $e");
  }
}
Future<void> _loadFriends() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final uuid = prefs.getString('userUuid') ?? '';
    final res = await ApiService.get("/users/$uuid/friends");
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body)['content'] as List;
      setState(() {
        _friends = data;
        _friendCount = data.length;
      });
    }
  } catch (e) {
    print("load friends error: $e");
  }
}
  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('username') ?? 'Guest';
    });
  }

  Future<void> _logout() async {
    final theme = Theme.of(context); 
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface, 
        title: Text('Logout', style: TextStyle(color: theme.colorScheme.onSurface)),
        content: Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;
await AuthService.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }
void _openFriendsSheet() {
  final theme = Theme.of(context);
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF1A1A1A),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.6,
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
          Text(
            "Friends ($_friendCount)",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _friends.isEmpty
                ? const Center(
                    child: Text("No friends yet", style: TextStyle(color: Colors.white54)),
                  )
                : ListView.builder(
                    controller: scrollController,
                    itemCount: _friends.length,
                    itemBuilder: (_, i) {
                      final f = _friends[i];
                      return ListTile(
                      leading: NameAvatar(name: f['name'] ?? '?', radius: 20),

                        title: Text(
                          f['name'] ?? 'Unknown',
                          style: const TextStyle(color: Colors.white),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
builder: (_) => UserProfilePage(
  user: User(
    uuid: f['uuid'],
    name: f['name'] ?? 'Unknown',
    password: '',
  ),
),                            ),
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
  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final isDark = settings.themeMode == ThemeMode.dark;
    final theme = Theme.of(context); 

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, 
      appBar: AppBar(
        title: Text(
          'Profile & Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 30,
            color: theme.colorScheme.onSurface, 
          ),
          textAlign: TextAlign.center,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Username card
         InkWell(
  onTap: _openFriendsSheet,
  borderRadius: BorderRadius.circular(12),
  child: Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
       NameAvatar(name: username, radius: 22),

        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                username,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                "$_friendCount Friends",
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        Icon(Icons.chevron_right, color: theme.colorScheme.onSurface.withOpacity(0.5)),
      ],
    ),
  ),
),

          const SizedBox(height: 18),

          Text(
            'Settings',
            style: TextStyle(
              color: theme.colorScheme.onSurface, 
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),

          // Dark mode toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface, 
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  isDark ? Icons.dark_mode : Icons.light_mode,
                  color: theme.colorScheme.onSurface.withOpacity(0.7), 
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Dark Mode',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface, 
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Switch(
                  value: isDark,
                  onChanged: (_) => settings.toggleTheme(),
                  activeColor: Colors.white,
                  activeTrackColor: Colors.blueGrey,
                ),
              ],
            ),
          ),
Container(
  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
  decoration: BoxDecoration(
    color: theme.colorScheme.surface,
    borderRadius: BorderRadius.circular(12),
  ),
  child: Row(
    children: [
      Icon(
        _isPrivate ? Icons.lock : Icons.lock_open,
        color: theme.colorScheme.onSurface.withOpacity(0.7),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Private Account',
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              _isPrivate ? 'Only friends can see your profile' : 'Everyone can see your profile',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
      Switch(
        value: _isPrivate,
        onChanged: (_) => _togglePrivate(),
        activeColor: Colors.white,
        activeTrackColor: Colors.blueGrey,
      ),
    ],
  ),
),
          const SizedBox(height: 8),

          _SettingsTile(
            icon: Icons.history,
            title: 'Reading history',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HistoryPage()),
            ),
          ),

          const SizedBox(height: 8),

          _SettingsTile(
            icon: Icons.logout,
            title: 'Logout',
            textColor: Colors.red,
            onTap: _logout,
          ),

          const SizedBox(height: 18),

          Text(
            'About',
            style: TextStyle(
              color: theme.colorScheme.onSurface, 
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),

          _SettingsTile(
            icon: Icons.help_outline,
            title: 'Help',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpPage())),
          ),

          const SizedBox(height: 8),

          _SettingsTile(
            icon: Icons.info_outline,
            title: 'About Us',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutPage())),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
  
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? textColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); 

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface, 
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: textColor ?? theme.colorScheme.onSurface.withOpacity(0.7)), 
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: textColor ?? theme.colorScheme.onSurface, 
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: theme.colorScheme.onSurface.withOpacity(0.5)), // ✅
          ],
        ),
      ),
    );
  }
  
}