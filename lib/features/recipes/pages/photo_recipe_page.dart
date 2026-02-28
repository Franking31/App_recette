import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/vision_service.dart';
import '../data/models/recipe.dart';
import 'add_recipe_page.dart';

// ═══════════════════════════════════════════
//  PHOTO → RECETTE
// ═══════════════════════════════════════════
class PhotoRecipePage extends StatefulWidget {
  final void Function(Recipe)? onRecipeAdded;
  const PhotoRecipePage({super.key, this.onRecipeAdded});

  @override
  State<PhotoRecipePage> createState() => _PhotoRecipePageState();
}

class _PhotoRecipePageState extends State<PhotoRecipePage>
    with TickerProviderStateMixin {
  Uint8List? _imageBytes;
  String _imageMimeType = 'image/jpeg';
  bool _analyzing = false;
  String _step = '';
  List<String> _detectedIngredients = [];
  List<Recipe> _recipes = [];
  String? _error;
  int _servings = 4;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _pulse = Tween(begin: 0.97, end: 1.03)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: source, maxWidth: 1200, maxHeight: 1200, imageQuality: 85);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final ext = picked.name.split('.').last.toLowerCase();
    final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
    setState(() {
      _imageBytes = bytes;
      _imageMimeType = mime;
      _recipes = [];
      _detectedIngredients = [];
      _error = null;
    });
  }

  Future<void> _analyze() async {
    if (_imageBytes == null) return;
    setState(() { _analyzing = true; _error = null; _step = '🔍 Analyse de l\'image...'; });

    try {
      await Future.delayed(const Duration(milliseconds: 300));
      setState(() => _step = '🥦 Détection des ingrédients...');

      final result = await VisionService.analyzePhotoBytes(_imageBytes!, mimeType: _imageMimeType, servings: _servings);

      setState(() => _step = '👨‍🍳 Génération des recettes...');
      await Future.delayed(const Duration(milliseconds: 200));

      setState(() {
        _detectedIngredients = result.ingredients;
        _recipes = result.recipes;
        _analyzing = false;
        _step = '';
        if (_recipes.isEmpty) _error = result.message;
      });
    } catch (e) {
      setState(() {
        _analyzing = false;
        _step = '';
        _error = 'Erreur : ${e.toString().replaceAll('Exception: ', '')}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.background;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final textDark = isDark ? AppColors.darkTextDark : AppColors.textDark;
    final textLight = isDark ? AppColors.darkTextLight : AppColors.textLight;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── HEADER ─────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: surface,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 6)]),
                      child: Icon(Icons.arrow_back_ios_new, size: 18, color: textDark),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('📸 Photo → Recette', style: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w900, color: textDark)),
                      Text('Photographiez votre frigo ou vos ingrédients',
                          style: TextStyle(fontSize: 12, color: textLight)),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // ── ZONE IMAGE ──────────────
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: double.infinity,
                      height: 240,
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _imageBytes != null
                              ? AppColors.primary.withValues(alpha: 0.4)
                              : textLight.withValues(alpha: 0.2),
                          width: 2,
                        ),
                        boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 12)],
                      ),
                      child: _imageBytes != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Stack(fit: StackFit.expand, children: [
                                Image.memory(_imageBytes!, fit: BoxFit.cover),
                                // Bouton modifier en haut à droite
                                Positioned(top: 10, right: 10,
                                  child: GestureDetector(
                                    onTap: () => _showImagePicker(context),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(color: Colors.black54,
                                          borderRadius: BorderRadius.circular(10)),
                                      child: const Row(children: [
                                        Icon(Icons.edit, color: Colors.white, size: 14),
                                        SizedBox(width: 4),
                                        Text('Changer', style: TextStyle(
                                            color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                                      ]),
                                    ),
                                  ),
                                ),
                              ]),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Boutons Caméra + Galerie côte à côte
                                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                  _PickerButton(
                                    icon: Icons.camera_alt_rounded,
                                    label: 'Caméra',
                                    onTap: () => _pickImage(ImageSource.camera),
                                  ),
                                  const SizedBox(width: 16),
                                  _PickerButton(
                                    icon: Icons.photo_library_rounded,
                                    label: 'Galerie',
                                    onTap: () => _pickImage(ImageSource.gallery),
                                  ),
                                ]),
                                const SizedBox(height: 16),
                                Text('Frigo, placard, marché...',
                                    style: TextStyle(fontSize: 13, color: textLight)),
                              ],
                            ),
                    ),

                    const SizedBox(height: 16),

                    // ── PERSONNES + ANALYSER ────
                    Row(children: [
                      // Sélecteur personnes
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(color: surface,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 6)]),
                        child: Row(children: [
                          const Text('👥', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => setState(() => _servings = (_servings - 1).clamp(1, 20)),
                            child: Icon(Icons.remove_circle_outline, color: textLight, size: 20)),
                          const SizedBox(width: 8),
                          Text('$_servings', style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800, color: textDark)),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => setState(() => _servings = (_servings + 1).clamp(1, 20)),
                            child: const Icon(Icons.add_circle_outline, color: AppColors.primary, size: 20)),
                        ]),
                      ),
                      const SizedBox(width: 10),
                      // Bouton analyser
                      Expanded(
                        child: GestureDetector(
                          onTap: (_imageBytes != null && !_analyzing) ? _analyze : null,
                          child: AnimatedBuilder(
                            animation: _pulse,
                            builder: (_, child) => Transform.scale(
                              scale: (_imageBytes != null && !_analyzing) ? _pulse.value : 1.0,
                              child: child,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                gradient: _imageBytes != null
                                    ? AppColors.primaryGradient
                                    : LinearGradient(colors: [
                                        textLight.withValues(alpha: 0.3),
                                        textLight.withValues(alpha: 0.2),
                                      ]),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: _imageBytes != null ? [BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.3),
                                    blurRadius: 12, offset: const Offset(0, 4))] : [],
                              ),
                              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                const Text('🔍', style: TextStyle(fontSize: 18)),
                                const SizedBox(width: 8),
                                Text('Analyser & Cuisiner', style: TextStyle(
                                    color: _imageBytes != null ? Colors.white : textLight,
                                    fontWeight: FontWeight.w800, fontSize: 15)),
                              ]),
                            ),
                          ),
                        ),
                      ),
                    ]),

                    const SizedBox(height: 20),

                    // ── LOADING ─────────────────
                    if (_analyzing) ...[
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(color: surface,
                            borderRadius: BorderRadius.circular(20)),
                        child: Column(
                          children: [
                            const CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
                            const SizedBox(height: 16),
                            Text(_step, style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700, color: textDark)),
                            const SizedBox(height: 6),
                            Text('Gemini Vision + Groq au travail...',
                                style: TextStyle(fontSize: 12, color: textLight)),
                          ],
                        ),
                      ),
                    ],

                    // ── ERREUR ──────────────────
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.red.withOpacity(0.2)),
                        ),
                        child: Row(children: [
                          const Text('😕', style: TextStyle(fontSize: 24)),
                          const SizedBox(width: 12),
                          Expanded(child: Text(_error!,
                              style: const TextStyle(color: Colors.red, fontSize: 13))),
                        ]),
                      ),
                    ],

                    // ── INGRÉDIENTS DÉTECTÉS ────
                    if (_detectedIngredients.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('🔍 Ingrédients détectés',
                                style: TextStyle(fontSize: 14,
                                    fontWeight: FontWeight.w800, color: textDark)),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6, runSpacing: 6,
                              children: _detectedIngredients.map((ing) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(ing, style: const TextStyle(
                                    fontSize: 12, color: AppColors.primary,
                                    fontWeight: FontWeight.w700)),
                              )).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // ── RECETTES ────────────────
                    if (_recipes.isNotEmpty) ...[
                      Row(children: [
                        Text('✨ ${_recipes.length} recettes suggérées',
                            style: TextStyle(fontSize: 18,
                                fontWeight: FontWeight.w800, color: textDark)),
                      ]),
                      const SizedBox(height: 12),
                      ..._recipes.map((recipe) => _RecipeResultCard(
                        recipe: recipe,
                        isDark: isDark,
                        onAdd: () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => AddRecipePage(onRecipeAdded: widget.onRecipeAdded ?? (_) {}),
                          ));
                        },
                      )),
                    ],

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final surface = isDark ? AppColors.darkSurface : AppColors.surface;
        return Container(
          decoration: BoxDecoration(color: surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text('Choisir une photo', style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            _PickerOption(icon: Icons.camera_alt_rounded, label: 'Prendre une photo',
                onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); }),
            const SizedBox(height: 10),
            _PickerOption(icon: Icons.photo_library_rounded, label: 'Choisir depuis la galerie',
                onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); }),
          ]),
        );
      },
    );
  }
}

// ── Carte résultat recette ─────────────────────
class _RecipeResultCard extends StatelessWidget {
  final Recipe recipe;
  final bool isDark;
  final VoidCallback? onAdd;

  const _RecipeResultCard({required this.recipe, required this.isDark, this.onAdd});

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final textDark = isDark ? AppColors.darkTextDark : AppColors.textDark;
    final textLight = isDark ? AppColors.darkTextLight : AppColors.textLight;
    final catColor = AppColors.categoryColor(recipe.category);

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => _RecipePreviewSheet(recipe: recipe, isDark: isDark, onAdd: onAdd),
      )),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: surface,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: AppColors.cardShadow,
                blurRadius: 10, offset: const Offset(0, 4))]),
        child: Row(children: [
          // Image ou placeholder
          ClipRRect(
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18), bottomLeft: Radius.circular(18)),
            child: recipe.imageUrl != null
                ? Image.network(recipe.imageUrl!, width: 100, height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder(catColor))
                : _placeholder(catColor),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (recipe.category != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(color: catColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6)),
                    child: Text(recipe.category!, style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w700, color: catColor)),
                  ),
                const SizedBox(height: 4),
                Text(recipe.title, style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w800, color: textDark),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.schedule, size: 12, color: textLight),
                  const SizedBox(width: 3),
                  Text('${recipe.durationMinutes} min',
                      style: TextStyle(fontSize: 11, color: textLight)),
                  const SizedBox(width: 10),
                  Icon(Icons.restaurant_menu, size: 12, color: textLight),
                  const SizedBox(width: 3),
                  Text('${recipe.ingredients.length} ingr.',
                      style: TextStyle(fontSize: 11, color: textLight)),
                ]),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Icon(Icons.arrow_forward_ios, size: 13, color: textLight),
          ),
        ]),
      ),
    );
  }

  Widget _placeholder(Color color) => Container(
    width: 100, height: 100,
    color: color.withOpacity(0.12),
    child: Icon(Icons.restaurant, color: color, size: 32),
  );
}

// ── Aperçu rapide recette (bottom sheet style) ─
class _RecipePreviewSheet extends StatelessWidget {
  final Recipe recipe;
  final bool isDark;
  final VoidCallback? onAdd;
  const _RecipePreviewSheet({required this.recipe, required this.isDark, this.onAdd});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkBackground : AppColors.background;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final textDark = isDark ? AppColors.darkTextDark : AppColors.textDark;
    final textLight = isDark ? AppColors.darkTextLight : AppColors.textLight;
    final catColor = AppColors.categoryColor(recipe.category);

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          backgroundColor: bg,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: Colors.black38, shape: BoxShape.circle),
              child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: recipe.imageUrl != null
                ? Image.network(recipe.imageUrl!, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _heroPlaceholder(catColor))
                : _heroPlaceholder(catColor),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (recipe.category != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: catColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(recipe.category!, style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700, color: catColor)),
                ),
              const SizedBox(height: 8),
              Text(recipe.title, style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w900, color: textDark)),
              const SizedBox(height: 6),
              Text(recipe.description, style: TextStyle(
                  fontSize: 14, color: textLight, height: 1.5)),
              const SizedBox(height: 16),
              Row(children: [
                _chip(Icons.schedule, '${recipe.durationMinutes} min', surface, textDark),
                const SizedBox(width: 10),
                _chip(Icons.people, '${recipe.servings} pers.', surface, textDark),
              ]),
              const SizedBox(height: 24),
              Text('🛒 Ingrédients', style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800, color: textDark)),
              const SizedBox(height: 12),
              ...recipe.ingredients.map((ing) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Container(width: 7, height: 7,
                      decoration: BoxDecoration(color: catColor, shape: BoxShape.circle)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(ing, style: TextStyle(
                      fontSize: 14, color: textDark))),
                ]),
              )),
              const SizedBox(height: 24),
              Text('👨‍🍳 Préparation', style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800, color: textDark)),
              const SizedBox(height: 12),
              ...recipe.steps.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(color: catColor, shape: BoxShape.circle),
                    child: Center(child: Text('${e.key + 1}', style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(e.value, style: TextStyle(
                      fontSize: 14, color: textDark, height: 1.5))),
                ]),
              )),
              const SizedBox(height: 24),
              // Bouton ajouter
              GestureDetector(
                onTap: () { Navigator.pop(context); onAdd?.call(); },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('➕', style: TextStyle(fontSize: 18)),
                    SizedBox(width: 8),
                    Text('Ajouter à mes recettes', style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                  ]),
                ),
              ),
              const SizedBox(height: 30),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _heroPlaceholder(Color color) => Container(
    color: color.withOpacity(0.15),
    child: Center(child: Icon(Icons.restaurant, size: 70, color: color)));

  Widget _chip(IconData icon, String label, Color surface, Color textDark) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 4)]),
        child: Row(children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 13,
              fontWeight: FontWeight.w700, color: textDark)),
        ]),
      );
}

class _PickerOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _PickerOption({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.background;
    final textDark = isDark ? AppColors.darkTextDark : AppColors.textDark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          Container(width: 42, height: 42,
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(11)),
              child: Icon(icon, color: AppColors.primary, size: 22)),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontSize: 15,
              fontWeight: FontWeight.w700, color: textDark)),
          const Spacer(),
          Icon(Icons.arrow_forward_ios, size: 13, color: textDark.withValues(alpha: 0.4)),
        ]),
      ),
    );
  }
}

// ── Bouton caméra/galerie compact dans la zone image ──
class _PickerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _PickerButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(children: [
          Icon(icon, color: Colors.white, size: 30),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
        ]),
      ),
    );
  }
}