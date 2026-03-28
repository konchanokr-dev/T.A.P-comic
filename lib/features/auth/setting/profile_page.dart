import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tapcomic/features/auth/about_page.dart';
import 'package:tapcomic/features/auth/help_page.dart';
import 'history_page.dart';
import '../login.dart';
import '../../../core/app_settings.dart';
import '../../../core/app_setting_scope.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String username = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('username') ?? 'Guest';
    });
  }

  Future<void> _logout() async {
    final theme = Theme.of(context); // ✅ ดึง theme ก่อน showDialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface, // ✅
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

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final isDark = settings.themeMode == ThemeMode.dark;
    final theme = Theme.of(context); // ✅

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // ✅
      appBar: AppBar(
        // ✅ ไม่ต้องใส่สี AppBarTheme จัดการให้แล้วใน main.dart
        title: Text(
          'Profile & Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 30,
            color: theme.colorScheme.onSurface, // ✅
          ),
          textAlign: TextAlign.center,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Username card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface, // ✅
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: theme.colorScheme.onSurface.withOpacity(0.15), // ✅
                  child: Icon(Icons.person, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    username,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface, // ✅
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, color: theme.colorScheme.onSurface.withOpacity(0.5)),
              ],
            ),
          ),

          const SizedBox(height: 18),

          Text(
            'Settings',
            style: TextStyle(
              color: theme.colorScheme.onSurface, // ✅
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),

          // Dark mode toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface, // ✅
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  isDark ? Icons.dark_mode : Icons.light_mode,
                  color: theme.colorScheme.onSurface.withOpacity(0.7), // ✅
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Dark Mode',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface, // ✅
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
              color: theme.colorScheme.onSurface, // ✅
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
    final theme = Theme.of(context); // ✅ ต้องดึงใน build ของ widget นี้เอง

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface, // ✅
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: textColor ?? theme.colorScheme.onSurface.withOpacity(0.7)), // ✅
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: textColor ?? theme.colorScheme.onSurface, // ✅
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