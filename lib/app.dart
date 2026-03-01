import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/services/auth_service.dart';
import 'features/recipes/pages/recipes_list_page.dart';
import 'features/auth/pages/login_page.dart';
import 'features/onboarding/onboarding_page.dart';

final themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);

class App extends StatelessWidget {
  final bool showOnboarding;
  const App({super.key, required this.showOnboarding});

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
          home: showOnboarding
              ? const OnboardingPage()
              : AuthService.isLoggedIn
                  ? const RecipesListPage()
                  : const LoginPage(),
        );
      },
    );
  }
}