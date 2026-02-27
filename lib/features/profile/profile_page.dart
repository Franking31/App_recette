import 'package:flutter/material.dart';
import 'package:frank_recette/features/recipes/pages/shopping_list_page.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/favorites_service.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/shopping_service.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../app.dart';
import '../../../core/widgets/recipe_card.dart';
import '../auth/pages/login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _loadingFavs = true;
  List _favorites = [];
  int _aiCount = 0;
  int _shoppingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    if (!AuthService.isLoggedIn) {
      setState(() => _loadingFavs = false);
      return;
    }
    // Charger en parallèle
    final results = await Future.wait([
      FavoritesService.getFavorites().catchError((_) => []),
      ApiService.get('/ai/stats').catchError((_) => {'aiRecipesCount': 0}),
      ShoppingService.getLists().catchError((_) => []),
    ]);
    if (mounted) {
      setState(() {
        _favorites = results[0] as List;
        _aiCount = ((results[1] as Map)['aiRecipesCount'] ?? 0) as int;
        _shoppingCount = (results[2] as List).length;
        _loadingFavs = false;
      });
    }
  }

  Future<void> _loadFavorites() => _loadAll();

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Text('Déconnexion',
              style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: isDark
                      ? AppColors.darkTextDark
                      : AppColors.textDark)),
          content: Text('Voulez-vous vraiment vous déconnecter ?',
              style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextLight
                      : AppColors.textLight)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler',
                  style: TextStyle(color: AppColors.textLight)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Déconnexion',
                  style: TextStyle(
                      color: Colors.red, fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await AuthService.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.background;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final textDark = isDark ? AppColors.darkTextDark : AppColors.textDark;
    final textLight = isDark ? AppColors.darkTextLight : AppColors.textLight;
    final user = AuthService.currentUser;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── HEADER ────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [BoxShadow(
                              color: AppColors.cardShadow, blurRadius: 6)],
                        ),
                        child: Icon(Icons.arrow_back_ios_new,
                            color: textDark, size: 18),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text('Mon profil',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: textDark,
                        )),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── AVATAR + EMAIL ─────────────
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 20, offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          user != null
                              ? user.email[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.email ?? 'Non connecté',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text('✨ Membre ForkAI',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── STATS ─────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _statCard('❤️', '${_favorites.length}',
                        'Favoris', surface, textDark, textLight),
                    const SizedBox(width: 12),
                    _statCard('🤖', '$_aiCount',
                        'Recettes IA', surface, textDark, textLight),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const ShoppingListPage())),
                      child: _statCard('🛒', '$_shoppingCount',
                          'Listes courses', surface, textDark, textLight),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── MES FAVORIS ───────────────
              if (AuthService.isLoggedIn) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text('❤️ Mes favoris',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: textDark)),
                      const Spacer(),
                      if (_loadingFavs)
                        const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (_favorites.isEmpty && !_loadingFavs)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          const Text('💔',
                              style: TextStyle(fontSize: 36)),
                          const SizedBox(height: 8),
                          Text('Aucun favori pour le moment',
                              style: TextStyle(
                                  color: textLight,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(
                              'Appuyez sur ❤️ dans une recette pour la sauvegarder',
                              style: TextStyle(
                                  color: textLight, fontSize: 12),
                              textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  )
                else
                  LayoutBuilder(builder: (context, constraints) {
                    final cols = constraints.maxWidth > 900 ? 3 : 2;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.80,
                      ),
                      itemCount: _favorites.length,
                      itemBuilder: (_, i) =>
                          RecipeCard(recipe: _favorites[i]),
                    );
                  }),
              ],

              const SizedBox(height: 24),

              // ── ACTIONS ───────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Toggle thème
                    ValueListenableBuilder(
                      valueListenable: themeNotifier,
                      builder: (_, mode, __) {
                        final isDarkMode = mode == ThemeMode.dark;
                        return _actionTile(
                          icon: isDarkMode
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                          label: isDarkMode ? 'Mode clair' : 'Mode sombre',
                          surface: surface,
                          textDark: textDark,
                          textLight: textLight,
                          onTap: () {
                            themeNotifier.value = isDarkMode
                                ? ThemeMode.light
                                : ThemeMode.dark;
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    // Déconnexion
                    _actionTile(
                      icon: Icons.logout_rounded,
                      label: 'Se déconnecter',
                      surface: surface,
                      textDark: Colors.red,
                      textLight: Colors.red.withValues(alpha: 0.6),
                      iconColor: Colors.red,
                      onTap: _logout,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── VERSION ───────────────────
              Text('ForkAI v1.0.0',
                  style: TextStyle(fontSize: 11, color: textLight)),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(String emoji, String value, String label,
      Color surface, Color textDark, Color textLight) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(color: AppColors.cardShadow, blurRadius: 8)
            ],
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 4),
              Text(value,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: textDark)),
              Text(label,
                  style: TextStyle(fontSize: 10, color: textLight),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );

  Widget _actionTile({
    required IconData icon,
    required String label,
    required Color surface,
    required Color textDark,
    required Color textLight,
    Color? iconColor,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(color: AppColors.cardShadow, blurRadius: 6)
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor ?? AppColors.primary, size: 20),
              const SizedBox(width: 12),
              Text(label,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textDark)),
              const Spacer(),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: textLight),
            ],
          ),
        ),
      );
}