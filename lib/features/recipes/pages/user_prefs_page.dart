import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/user_prefs_service.dart';

// ═══════════════════════════════════════════
//  PAGE PRÉFÉRENCES IA
//  Permet à l'utilisateur de configurer
//  son profil pour l'apprentissage IA
// ═══════════════════════════════════════════

class UserPrefsPage extends StatefulWidget {
  const UserPrefsPage({super.key});

  @override
  State<UserPrefsPage> createState() => _UserPrefsPageState();
}

class _UserPrefsPageState extends State<UserPrefsPage> {
  bool _loading = true;
  bool _saving = false;
  late UserPrefs _prefs;

  // Options disponibles
  static const _goals = [
    ('🥗', 'Perte de poids', 'perte_poids'),
    ('💪', 'Prise de masse', 'prise_masse'),
    ('💰', 'Budget étudiant', 'budget'),
    ('⚡', 'Cuisine rapide', 'rapide'),
    ('👨‍🍳', 'Gastronomie', 'gastro'),
    ('🌱', 'Végétarien', 'vegetarien'),
  ];

  static const _restrictions = [
    'Végétarien', 'Végétalien', 'Sans gluten',
    'Sans lactose', 'Halal', 'Casher', 'Sans porc',
  ];

  static const _allergies = [
    'Arachides', 'Fruits à coque', 'Lait', 'Œufs',
    'Blé', 'Soja', 'Poisson', 'Fruits de mer',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await UserPrefsService.getPrefs(forceRefresh: true);
    if (mounted) setState(() { _prefs = prefs; _loading = false; });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await UserPrefsService.savePrefs(_prefs);
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Préférences sauvegardées !'),
            backgroundColor: Colors.green),
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

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('🧠 Mon profil IA',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                color: textDark)),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2,
                      color: AppColors.primary)),
            )
          else
            TextButton(
              onPressed: _save,
              child: const Text('Sauvegarder',
                  style: TextStyle(color: AppColors.primary,
                      fontWeight: FontWeight.w800)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(
              color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Stats IA ─────────────────
                  _StatsCard(prefs: _prefs, surface: surface,
                      textDark: textDark, textLight: textLight),

                  const SizedBox(height: 24),

                  // ── Objectif ─────────────────
                  _sectionTitle('🎯 Mon objectif', textDark),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10, runSpacing: 10,
                    children: _goals.map((g) {
                      final (emoji, label, value) = g;
                      final selected = _prefs.goal == value;
                      return GestureDetector(
                        onTap: () => setState(() =>
                            _prefs = _prefs.copyWith(
                                goal: selected ? null : value)),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.primary
                                : surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: selected
                                  ? AppColors.primary
                                  : textLight.withOpacity(0.2),
                            ),
                            boxShadow: selected ? [
                              BoxShadow(color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 8, offset: const Offset(0, 3)),
                            ] : [],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(emoji),
                              const SizedBox(width: 6),
                              Text(label, style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700,
                                color: selected ? Colors.white : textDark,
                              )),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // ── Restrictions ─────────────
                  _sectionTitle('🚫 Restrictions alimentaires', textDark),
                  const SizedBox(height: 4),
                  Text('L\'IA ne te proposera jamais ces plats',
                      style: TextStyle(fontSize: 12, color: textLight)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: _restrictions.map((r) {
                      final selected = _prefs.dietaryRestrictions.contains(r);
                      return _FilterChip(
                        label: r,
                        selected: selected,
                        surface: surface,
                        textDark: textDark,
                        onTap: () {
                          final list = List<String>.from(
                              _prefs.dietaryRestrictions);
                          selected ? list.remove(r) : list.add(r);
                          setState(() =>
                              _prefs = _prefs.copyWith(
                                  dietaryRestrictions: list));
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // ── Allergies ────────────────
                  _sectionTitle('⚠️ Allergies', textDark),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: _allergies.map((a) {
                      final selected = _prefs.allergies.contains(a);
                      return _FilterChip(
                        label: a,
                        selected: selected,
                        selectedColor: Colors.orange,
                        surface: surface,
                        textDark: textDark,
                        onTap: () {
                          final list = List<String>.from(_prefs.allergies);
                          selected ? list.remove(a) : list.add(a);
                          setState(() =>
                              _prefs = _prefs.copyWith(allergies: list));
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // ── Budget moyen ─────────────
                  _sectionTitle('💶 Budget moyen par repas', textDark),
                  const SizedBox(height: 12),
                  _BudgetSlider(
                    value: _prefs.avgBudget ?? 10,
                    surface: surface,
                    textDark: textDark,
                    textLight: textLight,
                    onChanged: (v) =>
                        setState(() => _prefs = _prefs.copyWith(avgBudget: v)),
                  ),

                  const SizedBox(height: 24),

                  // ── Ce que l'IA a appris ──────
                  if (_prefs.likedCategories.isNotEmpty ||
                      _prefs.ignoredRecipes.isNotEmpty) ...[
                    _sectionTitle('🤖 Ce que l\'IA a appris', textDark),
                    const SizedBox(height: 12),
                    _AILearnedCard(
                        prefs: _prefs, surface: surface,
                        textDark: textDark, textLight: textLight),
                    const SizedBox(height: 24),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _sectionTitle(String t, Color c) => Text(t,
      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: c));
}

// ── Stats card ────────────────────────────
class _StatsCard extends StatelessWidget {
  final UserPrefs prefs;
  final Color surface, textDark, textLight;
  const _StatsCard({required this.prefs, required this.surface,
      required this.textDark, required this.textLight});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ton profil IA',
              style: TextStyle(color: Colors.white70, fontSize: 12,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              _stat('🍽️', '${prefs.totalRecipesSaved}', 'sauvegardées'),
              const SizedBox(width: 16),
              _stat('👨‍🍳', '${prefs.totalRecipesCooked}', 'cuisinées'),
              const SizedBox(width: 16),
              if (prefs.avgCookTime != null)
                _stat('⏱️', '${prefs.avgCookTime}', 'min moy.'),
            ],
          ),
          if (prefs.skillLevel != 'débutant') ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Niveau : ${prefs.skillLevel}',
                  style: const TextStyle(color: Colors.white,
                      fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _stat(String emoji, String value, String label) => Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          Text(value, style: const TextStyle(color: Colors.white,
              fontSize: 18, fontWeight: FontWeight.w900)),
          Text(label, style: const TextStyle(color: Colors.white70,
              fontSize: 10)),
        ],
      );
}

// ── Ce que l'IA a appris ─────────────────
class _AILearnedCard extends StatelessWidget {
  final UserPrefs prefs;
  final Color surface, textDark, textLight;
  const _AILearnedCard({required this.prefs, required this.surface,
      required this.textDark, required this.textLight});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (prefs.dominantCuisine != null)
            _learnedRow('❤️', 'Cuisine favorite détectée',
                prefs.dominantCuisine!, textDark, textLight),
          if (prefs.likedCategories.isNotEmpty)
            _learnedRow('✅', 'Aime cuisiner',
                prefs.likedCategories.take(3).join(', '),
                textDark, textLight),
          if (prefs.dislikedCategories.isNotEmpty)
            _learnedRow('❌', 'Évite souvent',
                prefs.dislikedCategories.join(', '),
                textDark, textLight),
          if (prefs.avgCookTime != null)
            _learnedRow('⏱️', 'Temps moyen cuisine',
                '${prefs.avgCookTime} min', textDark, textLight),
        ],
      ),
    );
  }

  Widget _learnedRow(String e, String label, String value,
      Color textDark, Color textLight) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(e, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 8),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(fontSize: 13, color: textLight),
                  children: [
                    TextSpan(text: '$label : '),
                    TextSpan(text: value,
                        style: TextStyle(color: textDark,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}

// ── Chip filtre ───────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? selectedColor;
  final Color surface, textDark;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected,
      this.selectedColor, required this.surface, required this.textDark,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = selectedColor ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.12) : surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: selected ? color : Colors.transparent, width: 1.5),
        ),
        child: Text(label, style: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w700,
          color: selected ? color : textDark,
        )),
      ),
    );
  }
}

// ── Budget slider ─────────────────────────
class _BudgetSlider extends StatelessWidget {
  final double value;
  final Color surface, textDark, textLight;
  final ValueChanged<double> onChanged;
  const _BudgetSlider({required this.value, required this.surface,
      required this.textDark, required this.textLight,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final labels = ['< 5€', '~10€', '~15€', '~20€', '> 25€'];
    final idx = (value / 5).clamp(0, 4).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Budget par repas', style: TextStyle(
                  fontSize: 13, color: textLight)),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(labels[idx], style: const TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w800,
                    fontSize: 13)),
              ),
            ],
          ),
          Slider(
            value: value.clamp(1, 25),
            min: 1, max: 25,
            divisions: 24,
            activeColor: AppColors.primary,
            inactiveColor: AppColors.primary.withOpacity(0.2),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}