import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/recipes/pages/recipes_list_page.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mes Recettes',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const RecipesListPage(),
    );
  }
}