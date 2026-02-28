import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/vision_service.dart';

// ═══════════════════════════════════════════
//  SUBSTITUTION D'INGRÉDIENTS
// ═══════════════════════════════════════════
class SubstitutePage extends StatefulWidget {
  final String? initialIngredient;
  const SubstitutePage({super.key, this.initialIngredient});

  @override
  State<SubstitutePage> createState() => _SubstitutePageState();
}

class _SubstitutePageState extends State<SubstitutePage> {
  final _ingredientCtrl = TextEditingController();
  final _contextCtrl = TextEditingController();
  String _selectedDiet = 'Aucun';
  bool _loading = false;
  SubstituteResult? _result;
  String? _error;

  final _diets = ['Aucun', 'Végétarien', 'Vegan', 'Sans gluten', 'Sans lactose', 'Keto'];

  // Suggestions rapides
  final _suggestions = [
    '🥚 Œufs', '🧈 Beurre', '🥛 Lait', '🍶 Crème fraîche',
    '🧀 Parmesan', '🌾 Farine', '🍯 Sucre', '🧄 Ail',
    '🫒 Huile d\'olive', '🍷 Vin blanc', '🧂 Sel', '🍋 Citron',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialIngredient != null) {
      _ingredientCtrl.text = widget.initialIngredient!;
      _search();
    }
  }

  @override
  void dispose() {
    _ingredientCtrl.dispose();
    _contextCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final ingredient = _ingredientCtrl.text.trim();
    if (ingredient.isEmpty) return;
    setState(() { _loading = true; _error = null; _result = null; });
    try {
      final result = await VisionService.getSubstitutes(
        ingredient: ingredient,
        context: _contextCtrl.text.trim().isEmpty ? null : _contextCtrl.text.trim(),
        diet: _selectedDiet == 'Aucun' ? null : _selectedDiet,
      );
      if (mounted) setState(() { _result = result; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
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
          // ── HEADER ─────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(width: 40, height: 40,
                    decoration: BoxDecoration(color: surface,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 6)]),
                    child: Icon(Icons.arrow_back_ios_new, size: 18, color: textDark)),
              ),
              const SizedBox(width: 14),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('🔄 Substitution', style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w900, color: textDark)),
                Text('Je n\'ai pas... Par quoi remplacer ?',
                    style: TextStyle(fontSize: 12, color: textLight)),
              ]),
            ]),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // ── CHAMP INGRÉDIENT ─────────
                Container(
                  decoration: BoxDecoration(color: surface,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 8)]),
                  child: Row(children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 14),
                      child: Text('🔍', style: TextStyle(fontSize: 20)),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _ingredientCtrl,
                        style: TextStyle(color: textDark, fontSize: 15,
                            fontWeight: FontWeight.w600),
                        onSubmitted: (_) => _search(),
                        decoration: InputDecoration(
                          hintText: 'Quel ingrédient remplacer ?',
                          hintStyle: TextStyle(color: textLight),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(14),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _search,
                      child: Container(
                        margin: const EdgeInsets.all(6),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(10)),
                        child: const Text('Chercher', style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                      ),
                    ),
                  ]),
                ),

                const SizedBox(height: 12),

                // ── SUGGESTIONS RAPIDES ──────
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: _suggestions.map((s) {
                    final name = s.replaceAll(RegExp(r'^[^\w]*'), '').trim();
                    return GestureDetector(
                      onTap: () {
                        _ingredientCtrl.text = name;
                        _search();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 4)],
                        ),
                        child: Text(s, style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600, color: textDark)),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                // ── CONTEXTE + RÉGIME ────────
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _contextCtrl,
                      style: TextStyle(color: textDark, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Contexte (optionnel)',
                        hintStyle: TextStyle(color: textLight, fontSize: 12),
                        filled: true, fillColor: surface,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(color: surface,
                        borderRadius: BorderRadius.circular(12)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedDiet,
                        style: TextStyle(color: textDark, fontSize: 12,
                            fontWeight: FontWeight.w600),
                        dropdownColor: surface,
                        items: _diets.map((d) => DropdownMenuItem(
                            value: d, child: Text(d))).toList(),
                        onChanged: (v) => setState(() => _selectedDiet = v!),
                      ),
                    ),
                  ),
                ]),

                const SizedBox(height: 20),

                // ── LOADING ──────────────────
                if (_loading)
                  Center(child: Column(children: [
                    const CircularProgressIndicator(color: AppColors.primary),
                    const SizedBox(height: 12),
                    Text('Recherche des meilleures alternatives...',
                        style: TextStyle(color: textLight, fontSize: 13)),
                  ])),

                // ── ERREUR ───────────────────
                if (_error != null)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.red.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14)),
                    child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                  ),

                // ── RÉSULTATS ────────────────
                if (_result != null) ...[
                  Row(children: [
                    Text('🔄 Substituts pour "${_result!.ingredient}"',
                        style: TextStyle(fontSize: 16,
                            fontWeight: FontWeight.w800, color: textDark)),
                  ]),
                  const SizedBox(height: 6),
                  Text(_result!.reason, style: TextStyle(
                      fontSize: 13, color: textLight, height: 1.4)),
                  const SizedBox(height: 14),

                  ..._result!.substitutes.asMap().entries.map((e) =>
                    _SubstituteCard(item: e.value, rank: e.key + 1,
                        isDark: isDark, textDark: textDark, textLight: textLight)),

                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                    ),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('💡', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 10),
                      Expanded(child: Text(_result!.tips,
                          style: TextStyle(fontSize: 13,
                              color: textDark, height: 1.4))),
                    ]),
                  ),
                  const SizedBox(height: 30),
                ],
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

class _SubstituteCard extends StatelessWidget {
  final SubstituteItem item;
  final int rank;
  final bool isDark;
  final Color textDark, textLight;

  const _SubstituteCard({required this.item, required this.rank,
      required this.isDark, required this.textDark, required this.textLight});

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 8,
            offset: const Offset(0, 3))],
        border: rank == 1
            ? Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.5)
            : null,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(item.emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(item.name, style: TextStyle(fontSize: 16,
                  fontWeight: FontWeight.w800, color: textDark)),
              if (rank == 1) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: AppColors.primary, borderRadius: BorderRadius.circular(6)),
                  child: const Text('Meilleur choix', style: TextStyle(
                      color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                ),
              ],
            ]),
            Text(item.ratio, style: TextStyle(
                fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _availabilityColor(item.availability).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(item.availability, style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w700,
                color: _availabilityColor(item.availability))),
          ),
        ]),
        const SizedBox(height: 10),
        _InfoRow('💬 Impact', item.impact, textLight),
        _InfoRow('🍳 Idéal pour', item.bestFor, textLight),
        if (item.tags.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 4,
            children: item.tags.map((t) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Text(t, style: const TextStyle(
                  fontSize: 10, color: Colors.green, fontWeight: FontWeight.w600)),
            )).toList(),
          ),
        ],
      ]),
    );
  }

  Color _availabilityColor(String a) => a.toLowerCase().contains('facile')
      ? Colors.green : a.toLowerCase().contains('moyen') ? Colors.orange : Colors.red;
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  final Color textLight;
  const _InfoRow(this.label, this.value, this.textLight);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: RichText(text: TextSpan(
      text: '$label : ',
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textLight),
      children: [TextSpan(text: value,
          style: TextStyle(fontWeight: FontWeight.w400, color: textLight))],
    )),
  );
}