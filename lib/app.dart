import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/services/auth_service.dart';
import 'features/recipes/pages/recipes_list_page.dart';
import 'features/auth/pages/login_page.dart';

final themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'ForkAI',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: mode,
          // Redirection selon l'état de connexion
          home: AuthService.isLoggedIn
              ? const RecipesListPage()
              : const LoginPage(),
        );
      },
    );
  }
}