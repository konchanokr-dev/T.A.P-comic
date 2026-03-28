import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tapcomic/features/auth/auth_service.dart';
import 'core/app_settings.dart';
import 'core/app_setting_scope.dart';
import 'features/auth/main_shell.dart';
import 'features/auth/login.dart';

void main() async {
WidgetsFlutterBinding.ensureInitialized();
PaintingBinding.instance.imageCache.maximumSize = 200;
PaintingBinding.instance.imageCache.maximumSizeBytes = 1024 * 1024 * 200;
  final settings = AppSettings();
       await settings.loadUserSettings();  
await AuthService.init();
  runApp(MyApp(settings: settings));

}

class MyApp extends StatelessWidget {
  final AppSettings settings;
  const MyApp({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    return AppSettingsScope(
      settings: settings,
       child: ListenableBuilder(              // 👈 เพิ่มตรงนี้
        listenable: settings,
         builder: (context, _) {
      return  MaterialApp(
        themeMode: settings.themeMode,
  theme: ThemeData.light().copyWith(
  scaffoldBackgroundColor: const Color(0xFFF5F5F5),
  colorScheme: const ColorScheme.light(
    surface: Color(0xFFE8E8E8),      // แทน 0xFF1E1E1E
    onSurface: Colors.black,
    onBackground: Colors.black87,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFF5F5F5),
    foregroundColor: Colors.black,
  ),
  cardColor: const Color(0xFFE0E0E0), // แทน 0xFF282828
),
darkTheme: ThemeData.dark().copyWith(
  scaffoldBackgroundColor: const Color(0xFF171717),
  colorScheme: const ColorScheme.dark(
    surface: Color(0xFF1E1E1E),
    onSurface: Colors.white,
    onBackground: Colors.white70,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF171717),
    foregroundColor: Colors.white,
  ),
  cardColor: const Color(0xFF282828),
),
  debugShowCheckedModeBanner: false,
  home: const AuthGate(),
);
         }
       ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool? isLoggedIn;

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

Future<void> _checkLogin() async {
  final prefs = await SharedPreferences.getInstance();
  final userUuid = prefs.getString("userUuid");
  final token = prefs.getString("token"); 

   setState(() {
    isLoggedIn = AuthService.token != null;
  });
}

  @override
  Widget build(BuildContext context) {
    if (isLoggedIn == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return isLoggedIn!
        ? const MainShell()
        : const LoginPage();
  }
}
