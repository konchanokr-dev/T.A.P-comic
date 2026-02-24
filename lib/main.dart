import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tapcomic/data/db/app_db2.dart';
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

  runApp(MyApp(settings: settings));

}

class MyApp extends StatelessWidget {
  final AppSettings settings;
  const MyApp({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    return AppSettingsScope(
      settings: settings,
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: AuthGate(),
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
    setState(() {
      isLoggedIn = userUuid != null;
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
