import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/ratings_service.dart';

// ═══════════════════════════════════════════
//  WIDGET NOTES & COMMENTAIRES
// ═══════════════════════════════════════════
class RecipeRatingsWidget extends StatefulWidget {
  final String recipeId;
  final String recipeTitle; // Pour générer une clé stable basée sur le titre

  const RecipeRatingsWidget({
    super.key,
    required this.recipeId,
    required this.recipeTitle,
  });

  /// Clé stable = titre normalisé (minuscules, sans accents, sans espaces)
  /// Permet que tous les utilisateurs partagent les mêmes notes
  /// même si l'ID local diffère
  String get stableKey {
    // Si c'est un UUID Supabase (recette cloud) → on l'utilise directement
    final uuidRegex = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$');
    if (uuidRegex.hasMatch(recipeId)) return recipeId;

    // Sinon (recette locale/dummy) → clé basée sur le titre normalisé
    return 'title_' + recipeTitle
        .toLowerCase()
        .replaceAll(RegExp(r'[àâä]'), 'a')
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[îï]'), 'i')
        .replaceAll(RegExp(r'[ôö]'), 'o')
        .replaceAll(RegExp(r'[ùûü]'), 'u')
        .replaceAll(RegExp(r'[^a-z0-9]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  @override
  State<RecipeRatingsWidget> createState() => _RecipeRatingsWidgetState();
}

class _RecipeRatingsWidgetState extends State<RecipeRatingsWidget> {
  List<RecipeRating> _ratings = [];
  RatingStats _stats = RatingStats(average: 0, count: 0);
  bool _loading = true;
  int _myRating = 0;
  String? _myComment;
  bool _showForm = false;
  bool _submitting = false;
  final _commentCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await RatingsService.getRatings(widget.stableKey);
    if (mounted) {
      setState(() {
        _ratings = result.ratings;
        _stats = result.stats;
        _loading = false;
        // Pré-remplir si déjà noté
        final mine = _ratings.where(
            (r) => r.userId == AuthService.currentUser?.userId).firstOrNull;
        if (mine != null) {
          _myRating = mine.rating;
          _myComment = mine.comment;
          _commentCtrl.text = mine.comment ?? '';
        }
      });
    }
  }

  Future<void> _submit() async {
    if (_myRating == 0 || _submitting) return;
    setState(() => _submitting = true);
    await RatingsService.submitRating(
      recipeId: widget.stableKey,
      rating: _myRating,
      comment: _commentCtrl.text.trim().isEmpty ? null : _commentCtrl.text.trim(),
      userEmail: AuthService.currentUser?.email,
    );
    await _load();
    if (mounted) setState(() { _showForm = false; _submitting = false; });
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('✅ Note enregistrée !'),
      backgroundColor: Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final textDark = isDark ? AppColors.darkTextDark : AppColors.textDark;
    final textLight = isDark ? AppColors.darkTextLight : AppColors.textLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── EN-TÊTE ───────────────────────────
        Row(
          children: [
            Text('⭐ Notes & Avis',
                style: TextStyle(fontSize: 20,
                    fontWeight: FontWeight.w800, color: textDark)),
            const Spacer(),
            if (_stats.count > 0) ...[
              Text(_stats.average.toStringAsFixed(1),
                  style: TextStyle(fontSize: 18,
                      fontWeight: FontWeight.w900, color: textDark)),
              const SizedBox(width: 4),
              Text('/5 · ${_stats.count} avis',
                  style: TextStyle(fontSize: 12, color: textLight)),
            ],
          ],
        ),

        const SizedBox(height: 12),

        // ── RÉSUMÉ ÉTOILES ────────────────────
        if (_stats.count > 0) ...[
          _StarSummary(average: _stats.average, isDark: isDark),
          const SizedBox(height: 16),
        ],

        // ── BOUTON NOTER ──────────────────────
        if (AuthService.isLoggedIn && !_showForm)
          GestureDetector(
            onTap: () => setState(() => _showForm = true),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star_outline, color: AppColors.primary, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    _myRating > 0 ? 'Modifier ma note ($_myRating/5)' : 'Donner mon avis',
                    style: const TextStyle(color: AppColors.primary,
                        fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),

        // ── FORMULAIRE NOTE ───────────────────
        if (_showForm) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 8)],
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Votre note', style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, color: textDark)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) => GestureDetector(
                    onTap: () => setState(() => _myRating = i + 1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        i < _myRating ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: i < _myRating ? const Color(0xFFFFD166) : textLight,
                        size: 36,
                      ),
                    ),
                  )),
                ),
                const SizedBox(height: 14),
                Text('Commentaire (optionnel)',
                    style: TextStyle(fontSize: 13,
                        fontWeight: FontWeight.w700, color: textLight)),
                const SizedBox(height: 6),
                TextField(
                  controller: _commentCtrl,
                  maxLines: 3,
                  style: TextStyle(color: textDark, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Partagez votre expérience...',
                    hintStyle: TextStyle(color: textLight),
                    filled: true,
                    fillColor: isDark ? AppColors.darkBackground : AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _showForm = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            color: textLight.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(child: Text('Annuler',
                              style: TextStyle(fontWeight: FontWeight.w700))),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: _myRating > 0 ? _submit : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            color: _myRating > 0
                                ? AppColors.primary
                                : AppColors.primary.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: _submitting
                                ? const SizedBox(width: 18, height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : const Text('Publier',
                                    style: TextStyle(color: Colors.white,
                                        fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 16),

        // ── LISTE DES AVIS ────────────────────
        if (_loading)
          const Center(child: CircularProgressIndicator(color: AppColors.primary))
        else if (_ratings.isEmpty)
          Center(
            child: Text('Pas encore d\'avis — soyez le premier !',
                style: TextStyle(color: textLight, fontSize: 13)),
          )
        else
          ..._ratings.map((r) => _RatingCard(rating: r, isDark: isDark,
              currentUserId: AuthService.currentUser?.userId,
              onDelete: () async {
                await RatingsService.deleteRating(widget.stableKey);
                _load();
              })),
      ],
    );
  }
}

// ── Résumé visuel étoiles ──────────────────────
class _StarSummary extends StatelessWidget {
  final double average;
  final bool isDark;
  const _StarSummary({required this.average, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final filled = i < average.floor();
        final half = !filled && i < average;
        return Icon(
          filled ? Icons.star_rounded
              : half ? Icons.star_half_rounded
              : Icons.star_outline_rounded,
          color: const Color(0xFFFFD166),
          size: 28,
        );
      }),
    );
  }
}

// ── Carte d'un avis ────────────────────────────
class _RatingCard extends StatelessWidget {
  final RecipeRating rating;
  final bool isDark;
  final String? currentUserId;
  final VoidCallback onDelete;

  const _RatingCard({
    required this.rating, required this.isDark,
    required this.currentUserId, required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final textDark = isDark ? AppColors.darkTextDark : AppColors.textDark;
    final textLight = isDark ? AppColors.darkTextLight : AppColors.textLight;
    final isMe = rating.userId == currentUserId;
    final initials = rating.userEmail.isNotEmpty
        ? rating.userEmail[0].toUpperCase() : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 6)],
        border: isMe ? Border.all(color: AppColors.primary.withValues(alpha: 0.3)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                child: Text(initials, style: const TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 13)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(
                        isMe ? 'Moi' : rating.userEmail.split('@')[0],
                        style: TextStyle(fontSize: 13,
                            fontWeight: FontWeight.w700, color: textDark),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Mon avis',
                              style: TextStyle(fontSize: 9,
                                  color: AppColors.primary, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ]),
                    Row(children: List.generate(5, (i) => Icon(
                      i < rating.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: const Color(0xFFFFD166), size: 14,
                    ))),
                  ],
                ),
              ),
              if (isMe)
                GestureDetector(
                  onTap: onDelete,
                  child: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                ),
            ],
          ),
          if (rating.comment != null && rating.comment!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(rating.comment!, style: TextStyle(
                fontSize: 13, color: textDark, height: 1.4)),
          ],
        ],
      ),
    );
  }
}