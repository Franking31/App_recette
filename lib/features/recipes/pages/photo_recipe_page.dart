import 'dart:convert';
import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../data/models/recipe.dart';
import 'recipe_detail_page.dart';

// ═══════════════════════════════════════════
//  PHOTO → RECETTE  (Flutter Web compatible)
//  Utilise dart:html FileUploadInputElement
//  au lieu de image_picker (non supporté web)
// ═══════════════════════════════════════════
class PhotoRecipePage extends StatefulWidget {
  final void Function(Recipe)? onRecipeAdded;
  const PhotoRecipePage({super.key, this.onRecipeAdded});

  @override
  State<PhotoRecipePage> createState() => _PhotoRecipePageState();
}

class _PhotoRecipePageState extends State<PhotoRecipePage> {
  Uint8List? _imageBytes;
  String _imageMimeType = 'image/jpeg';
  String? _imageObjectUrl; // Pour afficher l'image via URL blob
  bool _analyzing = false;
  String _step = '';
  List<String> _detectedIngredients = [];
  List<Recipe> _recipes = [];
  String? _error;
  int _servings = 4;

  // ── Ouvrir le sélecteur de fichier natif du navigateur ──
  void _pickImageFromWeb() {
    final input = html.FileUploadInputElement()
      ..accept = 'image/*'
      ..click();

    input.onChange.listen((event) async {
      final files = input.files;
      if (files == null || files.isEmpty) return;

      final file = files.first;
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);

      reader.onLoadEnd.listen((_) {
        final bytes = reader.result as Uint8List;
        final mime = file.type.isNotEmpty ? file.type : 'image/jpeg';

        // Créer une URL blob pour afficher l'image
        final blob = html.Blob([bytes], mime);
        final objectUrl = html.Url.createObjectUrlFromBlob(blob);

        // Révoquer l'ancienne URL si elle existe
        if (_imageObjectUrl != null) {
          html.Url.revokeObjectUrl(_imageObjectUrl!);
        }

        if (mounted) {
          setState(() {
            _imageBytes = bytes;
            _imageMimeType = mime;
            _imageObjectUrl = objectUrl;
            _recipes = [];
            _detectedIngredients = [];
            _error = null;
          });
        }
      });
    });
  }

  Future<void> _analyze() async {
    if (_imageBytes == null) return;

    setState(() {
      _analyzing = true;
      _error = null;
      _step = '🔍 Analyse de l\'image avec Gemini...';
    });

    try {
      final base64Image = base64Encode(_imageBytes!);

      setState(() => _step = '🥦 Détection des ingrédients...');

      final data = await ApiService.post('/vision/analyze', {
        'image': base64Image,
        'mimeType': _imageMimeType,
        'servings': _servings,
      });

      setState(() => _step = '👨‍🍳 Génération des recettes...');

      final ingredients = List<String>.from(data['ingredients'] ?? []);
      final recipesRaw = data['recipes'] as List? ?? [];
      final recipes = recipesRaw
          .map((r) => Recipe.fromJson(Map<String, dynamic>.from(r)))
          .toList();

      setState(() {
        _detectedIngredients = ingredients;
        _recipes = recipes;
        _analyzing = false;
        _step = '';
        if (recipes.isEmpty) {
          _error = data['message'] ?? 'Aucune recette générée';
        }
      });
    } catch (e) {
      setState(() {
        _analyzing = false;
        _step = '';
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  void dispose() {
    if (_imageObjectUrl != null) {
      html.Url.revokeObjectUrl(_imageObjectUrl!);
    }
    super.dispose();
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
            // ── HEADER ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 6)],
                      ),
                      child: Icon(Icons.arrow_back_ios_new, size: 18, color: textDark),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('📸 Photo → Recette',
                            style: TextStyle(fontSize: 20,
                                fontWeight: FontWeight.w900, color: textDark)),
                        Text('Photographiez votre frigo ou vos ingrédients',
                            style: TextStyle(fontSize: 12, color: textLight)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                child: Column(
                  children: [

                    // ── ZONE IMAGE ───────────────────────────────
                    GestureDetector(
                      onTap: _pickImageFromWeb,
                      child: Container(
                        width: double.infinity,
                        height: 260,
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _imageBytes != null
                                ? AppColors.primary.withValues(alpha: 0.5)
                                : textLight.withValues(alpha: 0.2),
                            width: 2,
                          ),
                          boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 10)],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _imageObjectUrl != null
                            // ── Image sélectionnée ──────────────
                            ? Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.network(
                                    _imageObjectUrl!,
                                    fit: BoxFit.cover,
                                  ),
                                  // Bouton changer
                                  Positioned(
                                    bottom: 10, right: 10,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.55),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.edit, color: Colors.white, size: 13),
                                          SizedBox(width: 4),
                                          Text('Changer',
                                              style: TextStyle(color: Colors.white,
                                                  fontSize: 12, fontWeight: FontWeight.w700)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            // ── Placeholder ─────────────────────
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 72, height: 72,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.add_photo_alternate_outlined,
                                        color: AppColors.primary, size: 36),
                                  ),
                                  const SizedBox(height: 14),
                                  Text('Cliquez pour sélectionner une photo',
                                      style: TextStyle(fontSize: 15,
                                          fontWeight: FontWeight.w700, color: textDark)),
                                  const SizedBox(height: 4),
                                  Text('JPG, PNG • Frigo, placard, ingrédients',
                                      style: TextStyle(fontSize: 12, color: textLight)),
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: AppColors.primary.withValues(alpha: 0.3)),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.upload, color: AppColors.primary, size: 18),
                                        SizedBox(width: 6),
                                        Text('Choisir une photo',
                                            style: TextStyle(color: AppColors.primary,
                                                fontWeight: FontWeight.w700, fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── PERSONNES + BOUTON ANALYSER ──────────────
                    Row(
                      children: [
                        // Sélecteur personnes
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: surface,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 6)],
                          ),
                          child: Row(
                            children: [
                              const Text('👥', style: TextStyle(fontSize: 16)),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => setState(
                                    () => _servings = (_servings - 1).clamp(1, 20)),
                                child: Icon(Icons.remove_circle_outline,
                                    color: textLight, size: 22),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: Text('$_servings',
                                    style: TextStyle(fontSize: 18,
                                        fontWeight: FontWeight.w900, color: textDark)),
                              ),
                              GestureDetector(
                                onTap: () => setState(
                                    () => _servings = (_servings + 1).clamp(1, 20)),
                                child: const Icon(Icons.add_circle_outline,
                                    color: AppColors.primary, size: 22),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Bouton analyser
                        Expanded(
                          child: GestureDetector(
                            onTap: (_imageBytes != null && !_analyzing) ? _analyze : null,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              decoration: BoxDecoration(
                                gradient: _imageBytes != null
                                    ? AppColors.primaryGradient
                                    : LinearGradient(colors: [
                                        Colors.grey.withValues(alpha: 0.3),
                                        Colors.grey.withValues(alpha: 0.2),
                                      ]),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: _imageBytes != null
                                    ? [BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.35),
                                        blurRadius: 12, offset: const Offset(0, 4))]
                                    : [],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(_analyzing ? '⏳' : '🔍',
                                      style: const TextStyle(fontSize: 18)),
                                  const SizedBox(width: 8),
                                  Text(
                                    _analyzing
                                        ? _step.replaceAll(RegExp(r'^[^\s]*\s'), '')
                                        : 'Analyser & Cuisiner',
                                    style: TextStyle(
                                      color: _imageBytes != null
                                          ? Colors.white
                                          : textLight,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // ── LOADING ──────────────────────────────────
                    if (_analyzing) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            const LinearProgressIndicator(
                              color: AppColors.primary,
                              backgroundColor: Color(0x22E8604A),
                            ),
                            const SizedBox(height: 14),
                            Text(_step,
                                style: TextStyle(fontSize: 14,
                                    fontWeight: FontWeight.w700, color: textDark)),
                            const SizedBox(height: 4),
                            Text('Gemini Vision + Groq (~20-40s)',
                                style: TextStyle(fontSize: 11, color: textLight)),
                          ],
                        ),
                      ),
                    ],

                    // ── ERREUR ───────────────────────────────────
                    if (_error != null && !_analyzing) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('😕', style: TextStyle(fontSize: 22)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Erreur', style: TextStyle(
                                      color: Colors.red, fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 4),
                                  Text(_error!, style: const TextStyle(
                                      color: Colors.red, fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // ── INGRÉDIENTS DÉTECTÉS ─────────────────────
                    if (_detectedIngredients.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.15)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('🔍 ${_detectedIngredients.length} ingrédients détectés',
                                style: TextStyle(fontSize: 13,
                                    fontWeight: FontWeight.w800, color: textDark)),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6, runSpacing: 6,
                              children: _detectedIngredients
                                  .map((ing) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(ing,
                                        style: const TextStyle(fontSize: 12,
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w700)),
                                  ))
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // ── RECETTES GÉNÉRÉES ────────────────────────
                    if (_recipes.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Text('✨ ${_recipes.length} recettes suggérées',
                              style: TextStyle(fontSize: 18,
                                  fontWeight: FontWeight.w800, color: textDark)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ..._recipes.map((r) => _RecipeCard(
                            recipe: r,
                            surface: surface,
                            textDark: textDark,
                            textLight: textLight,
                          )),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Carte recette résultat ─────────────────────────────
class _RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final Color surface, textDark, textLight;
  const _RecipeCard(
      {required this.recipe,
      required this.surface,
      required this.textDark,
      required this.textLight});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => RecipeDetailPage(recipe: recipe))),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: AppColors.cardShadow,
                    blurRadius: 8, offset: const Offset(0, 3))
              ]),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                child: recipe.imageUrl != null
                    ? Image.network(recipe.imageUrl!,
                        width: 90, height: 90, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder())
                    : _placeholder(),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (recipe.category != null)
                        Text(recipe.category!,
                            style: const TextStyle(fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary)),
                      const SizedBox(height: 3),
                      Text(recipe.title,
                          style: TextStyle(fontSize: 14,
                              fontWeight: FontWeight.w800, color: textDark),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),
                      Row(children: [
                        Icon(Icons.schedule, size: 11, color: textLight),
                        const SizedBox(width: 3),
                        Text('${recipe.durationMinutes} min',
                            style: TextStyle(fontSize: 11, color: textLight)),
                        const SizedBox(width: 10),
                        Icon(Icons.restaurant_menu, size: 11, color: textLight),
                        const SizedBox(width: 3),
                        Text('${recipe.ingredients.length} ingr.',
                            style: TextStyle(fontSize: 11, color: textLight)),
                      ]),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(Icons.arrow_forward_ios, size: 13, color: textLight),
              ),
            ],
          ),
        ),
      );

  Widget _placeholder() => Container(
        width: 90, height: 90,
        color: AppColors.primary.withValues(alpha: 0.1),
        child: const Icon(Icons.restaurant, color: AppColors.primary, size: 30),
      );
}