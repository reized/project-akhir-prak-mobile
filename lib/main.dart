import 'package:coba_project_prak/screens/main_page.dart';
import 'package:coba_project_prak/screens/login_page.dart';
import 'package:coba_project_prak/services/auth_service.dart';
import 'package:coba_project_prak/services/bookmark_service.dart';
import 'package:coba_project_prak/theme/app_theme.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize AuthService
  final authService = AuthService();
  await authService.init();

  // Migrate old bookmarks if user is logged in
  if (authService.isLoggedIn) {
    final bookmarkService = BookmarkService();
    await bookmarkService.migrateOldBookmarks();
  }

  runApp(MyApp(isLoggedIn: authService.isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Whatnime',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: isLoggedIn ? const MainPage() : const LoginPage(),
    );
  }
}
