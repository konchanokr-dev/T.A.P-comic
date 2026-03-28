import 'package:flutter/material.dart';
import 'package:tapcomic/features/auth/home.dart';
import 'package:tapcomic/features/auth/library.dart';
import 'package:tapcomic/features/auth/setting/profile_page.dart';
import 'SearchPage.dart';
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  final _pages = const [
    Home(),
    Searchpage(),
    Library(),
    ProfilePage(),
  ];


@override
Widget build(BuildContext context) {
  final theme = Theme.of(context);
  return Scaffold(
    backgroundColor: theme.scaffoldBackgroundColor, // ✅
    body: _pages[_index],
    bottomNavigationBar: BottomNavigationBar(
      currentIndex: _index,
      onTap: (i) => setState(() => _index = i),
      type: BottomNavigationBarType.fixed,
      backgroundColor: theme.colorScheme.surface,        // ✅
      selectedItemColor: theme.colorScheme.onSurface,    // ✅
      unselectedItemColor: theme.colorScheme.onSurface.withOpacity(0.5), // ✅
      showSelectedLabels: false,
      showUnselectedLabels: false,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.library_books), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
      ],
    ),
  );
}
}
