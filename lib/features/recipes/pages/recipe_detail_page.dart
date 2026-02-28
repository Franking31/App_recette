import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../data/models/recipe.dart';
import '../../../core/services/favorites_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/shopping_service.dart';
import 'ai_assistant_page.dart';
import 'nutrition_page.dart';
import 'substitute_page.dart';
import 'shopping_list_page.dart';
import 'conversations_history_page.dart';
import '../../../core/services/ratings_service.dart';
import '../../../core/services/share_service.dart';
import '../widgets/recipe_ratings_widget.dart';
import 'package:flutter/services.dart';

class RecipeDetailPage extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailPage({super.key, required this.recipe});

  @override
  State<RecipeDetailPage> createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage> {
  final Set<int> _checkedIngredients = {};
  bool _isFavorite = false;
  bool _favLoading = false;
  bool _sharingLink = false;
  String? _liveImageUrl;
  bool _loadingImage = false;

  @override
  void initState() {
    super.initState();
    _isFavorite = FavoritesService.isFavorite(widget.recipe.id);
    _liveImageUrl = widget.recipe.imageUrl;
    _liveImageUrl = widget.recipe.imageUrl;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.background;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    // ignore: unused_local_variable
    final textDark = isDark ? AppColors.darkTextDark : AppColors.textDark;
    final textLight = isDark ? AppColors.darkTextLight : AppColors.textLight;
    final catColor = AppColors.categoryColor(widget.recipe.category);

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          // ── HERO APPBAR ───────────────────────
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: bg,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back_ios_new,
                      color: Colors.white, size: 18),
                ),
              ),
            ),
            actions: [
              // Bouton partage
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 8, right: 4),
                child: GestureDetector(
                  onTap: _shareRecipe,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(8),
                    child: _sharingLink
                        ? const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.share_outlined, color: Colors.white, size: 20),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: GestureDetector(
                  onTap: _favLoading ? null : _toggleFavorite,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(8),
                    child: _favLoading
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Icon(
                            _isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: _isFavorite
                                ? Colors.red
                                : Colors.white,
                            size: 20,
                          ),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Image ou placeholder
                  _liveImageUrl != null
                      ? Image.network(
                          _liveImageUrl!,
                          fit: BoxFit.cover,
                          loadingBuilder: (_, child, progress) =>
                              progress == null ? child : _heroPlaceholder(catColor),
                          errorBuilder: (_, __, ___) =>
                              _heroPlaceholder(catColor),
                        )
                      : Stack(
                          fit: StackFit.expand,
                          children: [
                            _heroPlaceholder(catColor),
                            if (AuthService.isLoggedIn)
                              Positioned(
                                bottom: 16,
                                left: 0, right: 0,
                                child: Center(
                                  child: GestureDetector(
                                    onTap: _refreshImage,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 9),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.6),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: _loadingImage
                                          ? const SizedBox(
                                              width: 16, height: 16,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2, color: Colors.white))
                                          : const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.image_search,
                                                    color: Colors.white, size: 16),
                                                SizedBox(width: 6),
                                                Text('Trouver une image',
                                                    style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.w700)),
                                              ],
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                  // Gradient bas → transparent
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 100,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, bg],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                  // Badge catégorie en bas gauche
                  if (widget.recipe.category != null)
                    Positioned(
                      bottom: 16,
                      left: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: catColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: catColor.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          widget.recipe.category!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── CONTENU ───────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre
                  Text(
                    widget.recipe.title,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: textDark,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.recipe.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: textLight,
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── INFOS RAPIDES ──────────────
                  Row(
                    children: [
                      _infoChip(
                        Icons.schedule_rounded,
                        '${widget.recipe.durationMinutes} min',
                        catColor,
                        surface,
                        textDark,
                      ),
                      const SizedBox(width: 10),
                      _infoChip(
                        Icons.people_rounded,
                        '${widget.recipe.servings} pers.',
                        catColor,
                        surface,
                        textDark,
                      ),
                      const SizedBox(width: 10),
                      _infoChip(
                        Icons.restaurant_rounded,
                        'Recette',
                        catColor,
                        surface,
                        textDark,
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // ── INGRÉDIENTS ────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _sectionTitle('🛒 Ingrédients', textDark),
                      Row(
                        children: [
                          // Ajouter sélection à une liste
                          GestureDetector(
                            onTap: () => _addIngredientsToList(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(children: [
                                const Icon(Icons.playlist_add, color: AppColors.primary, size: 16),
                                const SizedBox(width: 4),
                                Text('Ajouter', style: const TextStyle(
                                    fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w700)),
                              ]),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Liste complète depuis recette
                          GestureDetector(
                            onTap: () => _createFullListFromRecipe(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(children: [
                                const Icon(Icons.shopping_cart_checkout, color: Colors.green, size: 16),
                                const SizedBox(width: 4),
                                Text('Liste complète', style: const TextStyle(
                                    fontSize: 12, color: Colors.green, fontWeight: FontWeight.w700)),
                              ]),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Appuyez pour cocher les ingrédients',
                    style: TextStyle(fontSize: 12, color: textLight),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.cardShadow,
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: widget.recipe.ingredients
                          .asMap()
                          .entries
                          .map((e) {
                        final idx = e.key;
                        final ing = e.value;
                        final checked = _checkedIngredients.contains(idx);
                        final isLast =
                            idx == widget.recipe.ingredients.length - 1;
                        return GestureDetector(
                          onTap: () => setState(() {
                            checked
                                ? _checkedIngredients.remove(idx)
                                : _checkedIngredients.add(idx);
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              border: isLast
                                  ? null
                                  : Border(
                                      bottom: BorderSide(
                                        color: isDark
                                            ? AppColors.darkDivider
                                            : AppColors.divider,
                                        width: 1,
                                      ),
                                    ),
                            ),
                            child: Row(
                              children: [
                                AnimatedContainer(
                                  duration:
                                      const Duration(milliseconds: 200),
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: checked
                                        ? catColor
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: checked
                                          ? catColor
                                          : textLight,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: checked
                                      ? const Icon(Icons.check,
                                          color: Colors.white, size: 14)
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    ing,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: checked
                                          ? textLight
                                          : textDark,
                                      decoration: checked
                                          ? TextDecoration.lineThrough
                                          : null,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  // Progression ingrédients
                  if (_checkedIngredients.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: _checkedIngredients.length /
                                  widget.recipe.ingredients.length,
                              backgroundColor:
                                  catColor.withValues(alpha: 0.15),
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(catColor),
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${_checkedIngredients.length}/${widget.recipe.ingredients.length}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: catColor,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 28),

                  // ── ÉTAPES ────────────────────
                  _sectionTitle('👨‍🍳 Préparation', textDark),
                  const SizedBox(height: 12),
                  ...widget.recipe.steps.asMap().entries.map((entry) {
                    final i = entry.key;
                    final step = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  catColor,
                                  catColor.withValues(alpha: 0.7)
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: catColor.withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: surface,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: const [
                                  BoxShadow(
                                    color: AppColors.cardShadow,
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                step,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: textDark,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 28),

                  // ── NOTES & COMMENTAIRES ──────
                  RecipeRatingsWidget(
                    recipeId: widget.recipe.id,
                    recipeTitle: widget.recipe.title,
                  ),

                  const SizedBox(height: 28),

                  // ── BOUTONS ACTIONS ──────────
                  Row(children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => NutritionPage(recipe: widget.recipe))),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00BCD4).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
                          ),
                          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text('🥗', style: TextStyle(fontSize: 18)),
                            SizedBox(width: 6),
                            Text('Nutrition', style: TextStyle(
                                color: Color(0xFF00BCD4), fontWeight: FontWeight.w800, fontSize: 14)),
                          ]),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const SubstitutePage())),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            color: const Color(0xFF26A69A).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFF26A69A).withOpacity(0.3)),
                          ),
                          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text('🔄', style: TextStyle(fontSize: 18)),
                            SizedBox(width: 6),
                            Text('Substituer', style: TextStyle(
                                color: Color(0xFF26A69A), fontWeight: FontWeight.w800, fontSize: 14)),
                          ]),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),

                  // ── BOUTON IA ─────────────────
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AiAssistantPage(
                            recipeToAnalyze: widget.recipe),
                      ),
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color:
                                AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('🤖', style: TextStyle(fontSize: 20)),
                          SizedBox(width: 10),
                          Text(
                            'Analyser avec l\'IA',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_ios,
                              color: Colors.white, size: 14),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Ajouter ingrédients sélectionnés à une liste ──
  // ── Rafraîchir l'image via Unsplash ────────
  Future<void> _refreshImage() async {
    if (_loadingImage) return;
    setState(() => _loadingImage = true);
    try {
      final data = await ApiService.post(
        '/ai/refresh-image/${widget.recipe.id}',
        {'title': widget.recipe.title},
      );
      final url = data['imageUrl'] as String?;
      if (mounted) {
        setState(() {
          _liveImageUrl = url;
          _loadingImage = false;
        });
        if (url == null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: const Text('Pas d\'image trouvee. Verifiez la cle Unsplash sur Render.'),
            backgroundColor: Colors.orange,
          ));
        }
      }
    } catch (e) {
      if (mounted) setState(() => _loadingImage = false);
    }
  }

  Future<void> _addIngredientsToList(BuildContext context) async {
    final recipe = widget.recipe;
    // Afficher dialog de sélection d'ingrédients
    final selected = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _IngredientPickerSheet(ingredients: recipe.ingredients),
    );
    if (selected == null || selected.isEmpty) return;

    // Choisir ou créer une liste
    final lists = await ShoppingService.getLists();
    if (!context.mounted) return;

    ShoppingList? targetList;
    if (lists.isEmpty) {
      targetList = await ShoppingService.createList('🍽️ ${recipe.title}');
    } else {
      targetList = await showModalBottomSheet<ShoppingList>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => _ListPickerSheet(lists: lists, recipeName: recipe.title),
      );
    }
    if (targetList == null || !context.mounted) return;

    final newItems = ShoppingService.ingredientsToItems(selected);
    targetList.items.addAll(newItems);
    await ShoppingService.updateList(targetList);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('✅ ${selected.length} article(s) ajouté(s) à « ${targetList.name} »'),
      backgroundColor: Colors.green,
      action: SnackBarAction(
        label: 'Voir',
        textColor: Colors.white,
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ShoppingListPage())),
      ),
    ));
  }

  // ── Créer liste complète depuis la recette ──
  Future<void> _createFullListFromRecipe(BuildContext context) async {
    final recipe = widget.recipe;
    final list = await ShoppingService.listFromRecipe(recipe.title, recipe.ingredients);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('🛒 Liste « ${list.name} » créée avec ${recipe.ingredients.length} articles'),
      backgroundColor: AppColors.primary,
      action: SnackBarAction(
        label: 'Ouvrir',
        textColor: Colors.white,
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ShoppingListPage())),
      ),
    ));
  }

  // ── Partager la recette ───────────────────
  Future<void> _shareRecipe() async {
    if (_sharingLink) return;
    final isLoggedIn = AuthService.isLoggedIn;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ShareBottomSheet(
        recipe: widget.recipe,
        isLoggedIn: isLoggedIn,
        onShareLink: () async {
          Navigator.pop(ctx);
          setState(() => _sharingLink = true);
          final link = await ShareService.createShareLink(widget.recipe);
          if (mounted) setState(() => _sharingLink = false);
          if (link != null && mounted) {
            await Clipboard.setData(ClipboardData(text: link));
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: const Text('🔗 Lien copié dans le presse-papier !'),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ));
          }
        },
        onShareText: () {
          Navigator.pop(ctx);
          final text = _buildShareText(widget.recipe);
          Clipboard.setData(ClipboardData(text: text));
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('📋 Recette copiée dans le presse-papier !'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ));
        },
      ),
    );
  }

  String _buildShareText(Recipe r) {
    final buf = StringBuffer();
    buf.writeln('🍴 ${r.title}');
    if (r.category != null) buf.writeln('${r.category}');
    buf.writeln('⏱ ${r.durationMinutes} min · 👥 ${r.servings} pers.');
    buf.writeln('');
    buf.writeln('📝 ${r.description}');
    buf.writeln('');
    buf.writeln('🛒 Ingrédients :');
    for (final ing in r.ingredients) {
      buf.writeln('\u2022 $ing');
    }
    buf.writeln('');
    buf.writeln('👨‍🍳 Préparation :');
    for (var i = 0; i < r.steps.length; i++) {
      buf.writeln('${i + 1}. ${r.steps[i]}');
    }
    buf.writeln('');
    buf.writeln('— Partagé depuis ForkAI 🤖');
    return buf.toString();
  }

  Future<void> _toggleFavorite() async {
    // Vérifier connexion AVANT d'essayer
    if (!AuthService.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🔐 Connectez-vous pour sauvegarder vos favoris')),
      );
      return;
    }
    setState(() => _favLoading = true);
    try {
      final added = await FavoritesService.toggleFavorite(widget.recipe);
      setState(() => _isFavorite = added);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(added ? '❤️ Ajouté aux favoris !' : '💔 Retiré des favoris'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Favorites error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString().replaceAll("Exception: ", "")}')),
        );
      }
    } finally {
      if (mounted) setState(() => _favLoading = false);
    }
  }

  Widget _heroPlaceholder(Color color) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.6), color.withValues(alpha: 0.3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Icon(Icons.restaurant_rounded, size: 80,
              color: Colors.white.withValues(alpha: 0.8)),
        ),
      );

  Widget _infoChip(IconData icon, String label, Color catColor,
          Color surface, Color textDark) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 6,
                offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: catColor),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: textDark,
              ),
            ),
          ],
        ),
      );

  Widget _sectionTitle(String title, Color textDark) => Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: textDark,
        ),
      );
}

// ─────────────────────────────────────────────
//  Sheet sélection d'ingrédients
// ─────────────────────────────────────────────
class _IngredientPickerSheet extends StatefulWidget {
  final List<String> ingredients;
  const _IngredientPickerSheet({required this.ingredients});

  @override
  State<_IngredientPickerSheet> createState() => _IngredientPickerSheetState();
}

class _IngredientPickerSheetState extends State<_IngredientPickerSheet> {
  late List<bool> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List.filled(widget.ingredients.length, true);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final textDark = isDark ? AppColors.darkTextDark : AppColors.textDark;
    final count = _selected.where((s) => s).length;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.textLight.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Expanded(child: Text('Sélectionner les ingrédients',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textDark))),
                TextButton(
                  onPressed: () => setState(() => _selected = List.filled(widget.ingredients.length, true)),
                  child: const Text('Tout', style: TextStyle(color: AppColors.primary)),
                ),
              ],
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.45),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.ingredients.length,
              itemBuilder: (_, i) => CheckboxListTile(
                value: _selected[i],
                activeColor: AppColors.primary,
                title: Text(widget.ingredients[i],
                    style: TextStyle(fontSize: 14, color: textDark)),
                onChanged: (v) => setState(() => _selected[i] = v ?? false),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: count == 0 ? null : () {
                  final sel = widget.ingredients
                      .asMap()
                      .entries
                      .where((e) => _selected[e.key])
                      .map((e) => e.value)
                      .toList();
                  Navigator.pop(context, sel);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('Ajouter $count article${count > 1 ? 's' : ''}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Sheet choix de liste existante ou nouvelle
// ─────────────────────────────────────────────
class _ListPickerSheet extends StatelessWidget {
  final List<ShoppingList> lists;
  final String recipeName;
  const _ListPickerSheet({required this.lists, required this.recipeName});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final textDark = isDark ? AppColors.darkTextDark : AppColors.textDark;
    final textLight = isDark ? AppColors.darkTextLight : AppColors.textLight;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.textLight.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Text('Ajouter à quelle liste ?', style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w800, color: textDark)),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
            child: ListView(
              shrinkWrap: true,
              children: [
                // Créer nouvelle liste
                ListTile(
                  leading: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.add, color: AppColors.primary),
                  ),
                  title: Text('Nouvelle liste', style: TextStyle(
                      fontWeight: FontWeight.w700, color: AppColors.primary)),
                  onTap: () async {
                    final ctrl = TextEditingController(text: '🍽️ $recipeName');
                    final name = await showDialog<String>(
                      context: context,
                      builder: (_) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: const Text('Nom de la liste'),
                        content: TextField(controller: ctrl, autofocus: true,
                            decoration: const InputDecoration(border: OutlineInputBorder())),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, ctrl.text),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                            child: const Text('Créer'),
                          ),
                        ],
                      ),
                    );
                    if (name != null && name.isNotEmpty && context.mounted) {
                      final newList = await ShoppingService.createList(name.trim());
                      Navigator.pop(context, newList);
                    }
                  },
                ),
                const Divider(height: 1),
                ...lists.map((l) => ListTile(
                  leading: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.shopping_cart_outlined, color: AppColors.primary, size: 20),
                  ),
                  title: Text(l.name, style: TextStyle(fontWeight: FontWeight.w600, color: textDark)),
                  subtitle: Text('${l.totalCount} articles', style: TextStyle(fontSize: 12, color: textLight)),
                  onTap: () => Navigator.pop(context, l),
                )),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Sheet : Partage de recette
// ─────────────────────────────────────────────
class _ShareBottomSheet extends StatelessWidget {
  final Recipe recipe;
  final bool isLoggedIn;
  final VoidCallback onShareLink;
  final VoidCallback onShareText;

  const _ShareBottomSheet({
    required this.recipe,
    required this.isLoggedIn,
    required this.onShareLink,
    required this.onShareText,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final textDark = isDark ? AppColors.darkTextDark : AppColors.textDark;
    final textLight = isDark ? AppColors.darkTextLight : AppColors.textLight;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: textLight.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Partager "${recipe.title}"',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textDark),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          _ShareOption(
            icon: Icons.link_rounded,
            color: AppColors.primary,
            title: 'Copier le lien de partage',
            subtitle: isLoggedIn ? 'Lien unique visible par tous' : 'Connexion requise',
            enabled: isLoggedIn,
            onTap: onShareLink,
          ),
          const SizedBox(height: 10),
          _ShareOption(
            icon: Icons.content_copy_rounded,
            color: const Color(0xFF6C63FF),
            title: 'Copier le texte complet',
            subtitle: 'Ingredients + etapes prets a coller',
            enabled: true,
            onTap: onShareText,
          ),
        ],
      ),
    );
  }
}

class _ShareOption extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback onTap;

  const _ShareOption({
    required this.icon, required this.color, required this.title,
    required this.subtitle, required this.enabled, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.background;
    final textDark = isDark ? AppColors.darkTextDark : AppColors.textDark;
    final textLight = isDark ? AppColors.darkTextLight : AppColors.textLight;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.4,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, color: textDark)),
                Text(subtitle, style: TextStyle(fontSize: 12, color: textLight)),
              ],
            )),
            Icon(Icons.arrow_forward_ios, size: 13, color: textLight),
          ]),
        ),
      ),
    );
  }
}