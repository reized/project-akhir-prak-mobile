import 'package:coba_project_prak/screens/main_page.dart';
import 'package:coba_project_prak/screens/login_page.dart';
import 'package:coba_project_prak/services/auth_service.dart';
import 'package:coba_project_prak/services/bookmark_service.dart';
import 'package:coba_project_prak/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authService = AuthService();
  await authService.init();

  if (authService.isLoggedIn) {
    final bookmarkService = BookmarkService();
    await bookmarkService.migrateOldBookmarks();
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Whatnime',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.currentTheme,
          home: FutureBuilder<bool>(
            future: Future.value(AuthService().isLoggedIn),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final isLoggedIn = snapshot.data ?? false;
              return isLoggedIn ? const MainPage() : const LoginPage();
            },
          ),
        );
      },
    );
  }
}
