import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/favorites_service.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/shopping_service.dart';
import '../../../app.dart';
import '../../../core/widgets/recipe_card.dart';
import '../auth/pages/login_page.dart';
import '../recipes/pages/shopping_list_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _loading = true;
  List _favorites = [];
  int _aiCount = 0;
  int _shoppingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    if (!AuthService.isLoggedIn) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final results = await Future.wait([
        FavoritesService.getFavorites().catchError((_) => <dynamic>[]),
        ApiService.get('/ai/stats').catchError((_) => <String, dynamic>{'aiRecipesCount': 0}),
        ShoppingService.getLists().catchError((_) => <ShoppingList>[]),
      ]);
      if (mounted) {
        setState(() {
          _favorites = results[0] as List;
          final statsMap = results[1] as Map;
          _aiCount = (statsMap['aiRecipesCount'] ?? 0) as int;
          _shoppingCount = (results[2] as List).length;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Déconnexion',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkTextDark : AppColors.textDark)),
          content: Text('Voulez-vous vraiment vous déconnecter ?',
              style: TextStyle(
                  color: isDark ? AppColors.darkTextLight : AppColors.textLight)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text('Se déconnecter'),
            ),
          ],
        );
      },
    );
    if (confirm != true || !mounted) return;
    await AuthService.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
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
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 6)],
            ),
            child: Icon(Icons.arrow_back_ios_new, size: 16, color: textDark),
          ),
        ),
        title: Text('Mon profil',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800, color: textDark)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadAll,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // ── AVATAR CARD ───────────────────────────
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 64, height: 64,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                user != null ? user.email[0].toUpperCase() : '?',
                                style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white),
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
                                      fontWeight: FontWeight.w700),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
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

                    // ── STATS ─────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          _StatCard(
                            emoji: '❤️',
                            value: '${_favorites.length}',
                            label: 'Favoris',
                            isDark: isDark,
                          ),
                          const SizedBox(width: 12),
                          _StatCard(
                            emoji: '🤖',
                            value: '$_aiCount',
                            label: 'Recettes IA',
                            isDark: isDark,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => const ShoppingListPage())),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkSurface : AppColors.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 8)],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('🛒', style: TextStyle(fontSize: 22)),
                                    const SizedBox(height: 4),
                                    Text('$_shoppingCount',
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900,
                                            color: isDark ? AppColors.darkTextDark : AppColors.textDark)),
                                    const SizedBox(height: 2),
                                    Text('Listes courses',
                                        style: TextStyle(fontSize: 10,
                                            color: isDark ? AppColors.darkTextLight : AppColors.textLight),
                                        textAlign: TextAlign.center),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── MES FAVORIS ───────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text('❤️ Mes favoris',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: textDark)),
                    ),
                    const SizedBox(height: 12),

                    if (_favorites.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                  color: AppColors.cardShadow, blurRadius: 8)
                            ],
                          ),
                          child: Column(
                            children: [
                              const Text('💔',
                                  style: TextStyle(fontSize: 40)),
                              const SizedBox(height: 10),
                              Text('Aucun favori pour le moment',
                                  style: TextStyle(
                                      color: textLight,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15)),
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
                      LayoutBuilder(builder: (ctx, constraints) {
                        final cols = constraints.maxWidth > 700 ? 3 : 2;
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

                    const SizedBox(height: 28),

                    // ── ACTIONS ───────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          // Toggle thème
                          ValueListenableBuilder<ThemeMode>(
                            valueListenable: themeNotifier,
                            builder: (_, mode, __) {
                              final isDarkMode = mode == ThemeMode.dark;
                              return _ActionTile(
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
                          _ActionTile(
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

                    Center(
                      child: Text('ForkAI v1.0.0',
                          style: TextStyle(fontSize: 11, color: textLight)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// ─────────────────────────────────────────────
//  Stat Card — widget indépendant
// ─────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  final bool isDark;

  const _StatCard({
    required this.emoji,
    required this.value,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final textDark = isDark ? AppColors.darkTextDark : AppColors.textDark;
    final textLight = isDark ? AppColors.darkTextLight : AppColors.textLight;

    return Expanded(
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: textDark)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(fontSize: 10, color: textLight),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Action Tile — widget indépendant
// ─────────────────────────────────────────────
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color surface;
  final Color textDark;
  final Color textLight;
  final Color? iconColor;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.surface,
    required this.textDark,
    required this.textLight,
    this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: AppColors.cardShadow, blurRadius: 8)
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? AppColors.primary, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textDark)),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: textLight),
          ],
        ),
      ),
    );
  }
}