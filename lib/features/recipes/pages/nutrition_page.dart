import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/vision_service.dart';
import '../data/models/recipe.dart';

// ═══════════════════════════════════════════
//  ANALYSE NUTRITIONNELLE
// ═══════════════════════════════════════════
class NutritionPage extends StatefulWidget {
  final Recipe? recipe;
  const NutritionPage({super.key, this.recipe});

  @override
  State<NutritionPage> createState() => _NutritionPageState();
}

class _NutritionPageState extends State<NutritionPage> {
  NutritionData? _data;
  bool _loading = false;
  String? _error;
  bool _perPortion = true;

  // Si pas de recette passée : saisie manuelle
  final _titleCtrl = TextEditingController();
  final _ingredientsCtrl = TextEditingController();
  int _servings = 4;

  @override
  void initState() {
    super.initState();
    if (widget.recipe != null) {
      _titleCtrl.text = widget.recipe!.title;
      _ingredientsCtrl.text = widget.recipe!.ingredients.join('\n');
      _servings = widget.recipe!.servings;
      _analyze();
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _ingredientsCtrl.dispose();
    super.dispose();
  }

  Future<void> _analyze() async {
    final title = _titleCtrl.text.trim();
    final ingredientsText = _ingredientsCtrl.text.trim();
    if (title.isEmpty || ingredientsText.isEmpty) {
      setState(() => _error = 'Veuillez remplir le nom et les ingrédients.');
      return;
    }

    setState(() { _loading = true; _error = null; _data = null; });
    try {
      final ingredients = ingredientsText.split('\n')
          .map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      final result = await VisionService.analyzeNutrition(
          title: title, ingredients: ingredients, servings: _servings);
      if (mounted) {
        if (result == null) {
          setState(() {
            _error = 'Erreur lors de l\'analyse. Vérifiez votre connexion et réessayez.';
            _loading = false;
          });
        } else {
          setState(() { _data = result; _loading = false; });
        }
      }
    } catch (e) {
      if (mounted) setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
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
        child: Column(children: [
          // ── HEADER gradient ─────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF00BCD4), Color(0xFF0097A7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [BoxShadow(color: Color(0x3300BCD4),
                  blurRadius: 12, offset: Offset(0, 4))],
            ),
            padding: const EdgeInsets.fromLTRB(12, 14, 20, 14),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new, size: 16, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              const Text('🥗', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Nutrition & Macros',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                Text('Analyse nutritionnelle complète',
                    style: TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w500)),
              ])),
            ]),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(children: [

                // ── FORMULAIRE ──────────────────
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: AppColors.cardShadow,
                        blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00BCD4).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.edit_note_rounded,
                            color: Color(0xFF00BCD4), size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text('Recette à analyser', style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w800, color: textDark)),
                      if (widget.recipe != null) ...[
                        const Spacer(),
                        GestureDetector(
                          onTap: () => setState(() {
                            _titleCtrl.clear();
                            _ingredientsCtrl.clear();
                          }),
                          child: Text('Modifier', style: TextStyle(
                              fontSize: 12, color: AppColors.textLight,
                              decoration: TextDecoration.underline)),
                        ),
                      ],
                    ]),
                    const SizedBox(height: 16),

                    _InputField(label: 'Nom de la recette', controller: _titleCtrl,
                        hint: 'Ex: Lasagnes bolognaise', surface: bg,
                        textDark: textDark, textLight: textLight),
                    const SizedBox(height: 12),
                    _InputField(label: 'Ingrédients (1 par ligne)',
                        controller: _ingredientsCtrl,
                        hint: '250g de farine\n3 œufs\n200ml de lait\n50g de beurre...',
                        maxLines: 5, surface: bg,
                        textDark: textDark, textLight: textLight),
                    const SizedBox(height: 14),

                    Row(children: [
                      Text('Portions :', style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700, color: textDark)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => setState(() => _servings = (_servings - 1).clamp(1, 20)),
                        child: Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(color: bg,
                              borderRadius: BorderRadius.circular(8)),
                          child: Icon(Icons.remove, size: 16, color: textLight),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text('$_servings', style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w900, color: textDark)),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _servings = (_servings + 1).clamp(1, 20)),
                        child: Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF00BCD4).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.add, size: 16, color: Color(0xFF00BCD4)),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 16),

                    GestureDetector(
                      onTap: _loading ? null : _analyze,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: _loading
                              ? null
                              : const LinearGradient(
                                  colors: [Color(0xFF00BCD4), Color(0xFF0097A7)]),
                          color: _loading ? AppColors.textLight : null,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: _loading ? [] : [
                            BoxShadow(color: const Color(0xFF00BCD4).withOpacity(0.35),
                                blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          if (_loading)
                            const SizedBox(width: 18, height: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                          else
                            const Text('🔬', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Text(_loading ? 'Analyse en cours...' : 'Analyser la nutrition',
                              style: const TextStyle(color: Colors.white,
                                  fontWeight: FontWeight.w800, fontSize: 15)),
                        ]),
                      ),
                    ),
                  ]),
                ),

                // ── LOADING ─────────────────
                if (_loading) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(color: surface,
                        borderRadius: BorderRadius.circular(18)),
                    child: Column(children: [
                      const Text('🔬', style: TextStyle(fontSize: 52)),
                      const SizedBox(height: 14),
                      const CircularProgressIndicator(color: Color(0xFF00BCD4)),
                      const SizedBox(height: 14),
                      Text('Analyse nutritionnelle...', style: TextStyle(
                          color: textDark, fontSize: 14, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text('L\'IA calcule calories, macros et vitamines',
                          style: TextStyle(color: textLight, fontSize: 12)),
                    ]),
                  ),
                ],

                // ── ERREUR ──────────────────
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.red.withOpacity(0.2)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error!.replaceAll('Exception: ', ''),
                          style: const TextStyle(color: Colors.red, fontSize: 13))),
                    ]),
                  ),
                ],

                // ── RÉSULTATS ────────────────
                if (_data != null) ...[
                  const SizedBox(height: 20),
                  _ScoreCard(data: _data!, isDark: isDark),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: surface,
                        borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      _ToggleBtn(label: 'Par portion', active: _perPortion,
                          onTap: () => setState(() => _perPortion = true)),
                      _ToggleBtn(label: 'Recette entière', active: !_perPortion,
                          onTap: () => setState(() => _perPortion = false)),
                    ]),
                  ),
                  const SizedBox(height: 14),
                  _MacrosGrid(
                    values: _perPortion ? _data!.perPortion : _data!.perRecipe,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 14),
                  if (_data!.vitamins.isNotEmpty) ...[
                    _SectionCard(
                      title: '💊 Vitamines & Minéraux',
                      isDark: isDark,
                      child: Column(children: _data!.vitamins.map((v) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(children: [
                          Expanded(child: Text(v.name, style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600, color: textDark))),
                          Text(v.amount, style: TextStyle(fontSize: 13, color: textLight)),
                          const SizedBox(width: 10),
                          SizedBox(width: 90,
                            child: ClipRRect(borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: _parsePercent(v.daily),
                                backgroundColor: const Color(0xFF00BCD4).withOpacity(0.1),
                                color: const Color(0xFF00BCD4), minHeight: 6),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(v.daily, style: TextStyle(fontSize: 11, color: textLight)),
                        ]),
                      )).toList()),
                    ),
                    const SizedBox(height: 14),
                  ],
                  _DietCompatibility(data: _data!, isDark: isDark),
                  const SizedBox(height: 14),
                  _StrengthsImprovements(data: _data!, isDark: isDark),
                  const SizedBox(height: 14),
                  if (_data!.tip.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00BCD4).withOpacity(0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.2)),
                      ),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00BCD4).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Text('💡', style: TextStyle(fontSize: 16)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Conseil nutritionnel', style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w800,
                                color: Color(0xFF00838F))),
                            const SizedBox(height: 4),
                            Text(_data!.tip, style: TextStyle(
                                fontSize: 13, color: textDark, height: 1.5)),
                          ],
                        )),
                      ]),
                    ),
                  const SizedBox(height: 30),
                ],

                // ── ÉTAT VIDE ────────────────
                if (!_loading && _data == null && _error == null) ...[
                  const SizedBox(height: 20),
                  _EmptyState(textLight: textLight),
                ],
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  double _parsePercent(String s) {
    final m = RegExp(r'(\d+)').firstMatch(s);
    if (m == null) return 0;
    return (int.tryParse(m.group(1)!) ?? 0) / 100;
  }
}

// ── Widgets composants ─────────────────────────

class _ScoreCard extends StatelessWidget {
  final NutritionData data;
  final bool isDark;
  const _ScoreCard({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final textDark = isDark ? AppColors.darkTextDark : AppColors.textDark;
    final textLight = isDark ? AppColors.darkTextLight : AppColors.textLight;
    final scoreColor = data.scoreColor == 'green'
        ? Colors.green : data.scoreColor == 'red' ? Colors.red : Colors.orange;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 10)]),
      child: Row(children: [
        Stack(alignment: Alignment.center, children: [
          SizedBox(width: 70, height: 70,
            child: CircularProgressIndicator(
              value: data.score / 10,
              strokeWidth: 7,
              backgroundColor: scoreColor.withOpacity(0.15),
              color: scoreColor,
            ),
          ),
          Text('${data.score}', style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.w900, color: scoreColor)),
        ]),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Score nutritionnel', style: TextStyle(
              fontSize: 12, color: textLight, fontWeight: FontWeight.w600)),
          Text(data.scoreLabel, style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.w900, color: scoreColor)),
          Text('Index glycémique : ${data.glycemicIndex}',
              style: TextStyle(fontSize: 12, color: textLight)),
        ])),
      ]),
    );
  }
}

class _MacrosGrid extends StatelessWidget {
  final Map<String, double> values;
  final bool isDark;
  const _MacrosGrid({required this.values, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final macros = [
      {'key': 'calories', 'label': 'Calories', 'unit': 'kcal', 'emoji': '🔥', 'color': const Color(0xFFE8604A)},
      {'key': 'proteins', 'label': 'Protéines', 'unit': 'g', 'emoji': '💪', 'color': const Color(0xFF5B8DEF)},
      {'key': 'carbs', 'label': 'Glucides', 'unit': 'g', 'emoji': '🌾', 'color': const Color(0xFFFFD166)},
      {'key': 'fats', 'label': 'Lipides', 'unit': 'g', 'emoji': '🥑', 'color': const Color(0xFF4CAF50)},
      {'key': 'fiber', 'label': 'Fibres', 'unit': 'g', 'emoji': '🌿', 'color': const Color(0xFF26A69A)},
      {'key': 'sugar', 'label': 'Sucres', 'unit': 'g', 'emoji': '🍬', 'color': const Color(0xFFE91E63)},
    ];
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final textDark = isDark ? AppColors.darkTextDark : AppColors.textDark;
    final textLight = isDark ? AppColors.darkTextLight : AppColors.textLight;

    return GridView.count(
      crossAxisCount: 3, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.1,
      children: macros.map((m) {
        final val = values[m['key']] ?? 0;
        final color = m['color'] as Color;
        return Container(
          decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 6)]),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(m['emoji'] as String, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(val % 1 == 0 ? '${val.toInt()}' : val.toStringAsFixed(1),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
            Text(m['unit'] as String, style: TextStyle(fontSize: 10, color: textLight)),
            Text(m['label'] as String, style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: textDark)),
          ]),
        );
      }).toList(),
    );
  }
}

class _DietCompatibility extends StatelessWidget {
  final NutritionData data;
  final bool isDark;
  const _DietCompatibility({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final labels = {
      'vegetarian': '🌱 Végétarien', 'vegan': '🌿 Vegan',
      'glutenFree': '🌾 Sans gluten', 'dairyFree': '🥛 Sans lactose',
      'keto': '🥩 Keto', 'lowCarb': '📉 Low carb',
    };
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final textDark = isDark ? AppColors.darkTextDark : AppColors.textDark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 8)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('🍽️ Compatibilité régimes', style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w800, color: textDark)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8,
          children: labels.entries.map((e) {
            final ok = data.dietCompatibility[e.key] ?? false;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: ok ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: ok ? Colors.green.withOpacity(0.3) : Colors.grey.withOpacity(0.2)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(ok ? Icons.check_circle : Icons.cancel,
                    size: 14, color: ok ? Colors.green : Colors.grey),
                const SizedBox(width: 4),
                Text(e.value, style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: ok ? Colors.green : Colors.grey)),
              ]),
            );
          }).toList(),
        ),
      ]),
    );
  }
}

class _StrengthsImprovements extends StatelessWidget {
  final NutritionData data;
  final bool isDark;
  const _StrengthsImprovements({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final textDark = isDark ? AppColors.darkTextDark : AppColors.textDark;

    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 6)]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('✅ Points forts', style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w800, color: Colors.green)),
          const SizedBox(height: 8),
          ...data.strengths.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text('• $s', style: TextStyle(fontSize: 12, color: textDark)),
          )),
        ]),
      )),
      const SizedBox(width: 10),
      Expanded(child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 6)]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('💡 À améliorer', style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w800, color: Colors.orange)),
          const SizedBox(height: 8),
          ...data.improvements.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text('• $s', style: TextStyle(fontSize: 12, color: textDark)),
          )),
        ]),
      )),
    ]);
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final bool isDark;
  const _SectionCard({required this.title, required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final textDark = isDark ? AppColors.darkTextDark : AppColors.textDark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 8)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textDark)),
        const SizedBox(height: 12),
        child,
      ]),
    );
  }
}

class _InputField extends StatelessWidget {
  final String label, hint;
  final TextEditingController controller;
  final int maxLines;
  final Color surface, textDark, textLight;

  const _InputField({required this.label, required this.hint,
      required this.controller, this.maxLines = 1,
      required this.surface, required this.textDark, required this.textLight});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 13,
          fontWeight: FontWeight.w700, color: textDark)),
      const SizedBox(height: 6),
      TextField(
        controller: controller, maxLines: maxLines,
        style: TextStyle(color: textDark, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint, hintStyle: TextStyle(color: textLight, fontSize: 13),
          filled: true, fillColor: surface,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2)),
        ),
      ),
    ]);
  }
}

class _ToggleBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _ToggleBtn({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(child: Text(label, style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w700,
            color: active ? Colors.white : AppColors.textLight))),
      ),
    ),
  );
}


class _EmptyState extends StatelessWidget {
  final Color textLight;
  const _EmptyState({required this.textLight});

  @override
  Widget build(BuildContext context) => Column(children: [
    const Text('🔬', style: TextStyle(fontSize: 64)),
    const SizedBox(height: 16),
    Text('Analysez n\'importe quelle recette',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textLight)),
    const SizedBox(height: 8),
    Text('Entrez les ingrédients et laissez l\'IA calculer calories, macros, vitamines et plus encore !',
        style: TextStyle(fontSize: 13, color: textLight.withOpacity(0.7), height: 1.5),
        textAlign: TextAlign.center),
    const SizedBox(height: 20),
    Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center,
      children: ['🔥 Calories', '💪 Protéines', '🌾 Glucides', '🥑 Lipides',
                  '💊 Vitamines', '🍽️ Régimes'].map((t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF00BCD4).withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.2)),
        ),
        child: Text(t, style: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF00BCD4))),
      )).toList(),
    ),
  ]);
}