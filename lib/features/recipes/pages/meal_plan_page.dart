import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/vision_service.dart';

// ═══════════════════════════════════════════
//  PLANNING DE REPAS SEMAINE
// ═══════════════════════════════════════════
class MealPlanPage extends StatefulWidget {
  const MealPlanPage({super.key});

  @override
  State<MealPlanPage> createState() => _MealPlanPageState();
}

class _MealPlanPageState extends State<MealPlanPage> {
  MealPlan? _plan;
  bool _loading = false;
  String? _error;
  int _selectedDay = 0;

  // Paramètres
  int _servings = 2;
  String _diet = '';
  String _budget = '';
  String _preferences = '';
  bool _showForm = true;

  final _prefCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();
  final _diets = ['Aucun', 'Végétarien', 'Vegan', 'Sans gluten',
      'Méditerranéen', 'Low carb', 'Keto'];
  String _selectedDiet = 'Aucun';

  @override
  void dispose() {
    _prefCtrl.dispose();
    _budgetCtrl.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    setState(() { _loading = true; _error = null; _showForm = false; });
    try {
      final plan = await VisionService.generateMealPlan(
        preferences: _prefCtrl.text.trim(),
        servings: _servings,
        budget: _budgetCtrl.text.trim(),
        diet: _selectedDiet == 'Aucun' ? '' : _selectedDiet,
      );
      if (mounted) setState(() { _plan = plan; _loading = false; _selectedDay = 0; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; _showForm = true; });
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
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
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
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('📅 Planning semaine', style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w900, color: textDark)),
                Text('7 jours de repas équilibrés',
                    style: TextStyle(fontSize: 12, color: textLight)),
              ])),
              if (_plan != null)
                GestureDetector(
                  onTap: () => setState(() { _showForm = true; _plan = null; }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Text('Recréer', style: TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                ),
            ]),
          ),

          Expanded(
            child: _loading
                ? _LoadingState(textLight: textLight)
                : _showForm
                    ? _buildForm(surface, textDark, textLight)
                    : _plan != null
                        ? _buildPlan(isDark, surface, textDark, textLight)
                        : const SizedBox(),
          ),

          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14)),
                child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
              ),
            ),
        ]),
      ),
    );
  }

  // ── Formulaire paramètres ──────────────────
  Widget _buildForm(Color surface, Color textDark, Color textLight) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Illustration
        Center(child: Container(
          width: 100, height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              AppColors.primary.withOpacity(0.1),
              AppColors.accent.withOpacity(0.1),
            ]),
            shape: BoxShape.circle,
          ),
          child: const Center(child: Text('📅', style: TextStyle(fontSize: 50))),
        )),
        const SizedBox(height: 24),

        // Personnes
        Text('👥 Nombre de personnes', style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w700, color: textDark)),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          GestureDetector(
            onTap: () => setState(() => _servings = (_servings - 1).clamp(1, 20)),
            child: Container(width: 40, height: 40,
                decoration: BoxDecoration(color: surface, shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 6)]),
                child: Icon(Icons.remove, color: textLight)),
          ),
          const SizedBox(width: 20),
          Text('$_servings', style: TextStyle(
              fontSize: 32, fontWeight: FontWeight.w900, color: textDark)),
          const SizedBox(width: 20),
          GestureDetector(
            onTap: () => setState(() => _servings = (_servings + 1).clamp(1, 20)),
            child: Container(width: 40, height: 40,
                decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8)]),
                child: const Icon(Icons.add, color: Colors.white)),
          ),
        ]),

        const SizedBox(height: 20),

        // Régime
        Text('🥗 Régime alimentaire', style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w700, color: textDark)),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8,
          children: _diets.map((d) => GestureDetector(
            onTap: () => setState(() => _selectedDiet = d),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _selectedDiet == d ? AppColors.primary : surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 4)],
              ),
              child: Text(d, style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: _selectedDiet == d ? Colors.white : textLight)),
            ),
          )).toList(),
        ),

        const SizedBox(height: 20),

        // Budget
        Text('💰 Budget (optionnel)', style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w700, color: textDark)),
        const SizedBox(height: 8),
        TextField(
          controller: _budgetCtrl,
          style: TextStyle(color: textDark),
          decoration: InputDecoration(
            hintText: 'Ex: 60€ par semaine',
            hintStyle: TextStyle(color: textLight, fontSize: 13),
            filled: true, fillColor: surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            prefixIcon: Icon(Icons.euro, color: textLight, size: 18),
          ),
        ),

        const SizedBox(height: 16),

        // Préférences
        Text('✨ Préférences & contraintes', style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w700, color: textDark)),
        const SizedBox(height: 8),
        TextField(
          controller: _prefCtrl,
          maxLines: 3,
          style: TextStyle(color: textDark, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Ex: Pas de poisson, j\'aime les cuisines asiatiques, repas rapides en semaine...',
            hintStyle: TextStyle(color: textLight, fontSize: 12),
            filled: true, fillColor: surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
          ),
        ),

        const SizedBox(height: 28),

        // Bouton générer
        GestureDetector(
          onTap: _generate,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.35),
                  blurRadius: 14, offset: const Offset(0, 6))],
            ),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('📅', style: TextStyle(fontSize: 22)),
              SizedBox(width: 10),
              Text('Générer mon planning', style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
            ]),
          ),
        ),

        const SizedBox(height: 20),
      ]),
    );
  }

  // ── Planning affiché ───────────────────────
  Widget _buildPlan(bool isDark, Color surface, Color textDark, Color textLight) {
    final plan = _plan!;

    return Column(children: [
      // Résumé semaine
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              AppColors.primary.withOpacity(0.1), AppColors.accent.withOpacity(0.1)]),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _SummaryChip('🔥', '${plan.weekSummary['avgCalories'] ?? '~'}', 'kcal/jour', textDark, textLight),
            _SummaryChip('💰', '${plan.weekSummary['totalBudget'] ?? '~'}', 'budget', textDark, textLight),
            _SummaryChip('⏱', '${plan.weekSummary['prepTime'] ?? '~'}', 'prépa', textDark, textLight),
          ]),
        ),
      ),

      const SizedBox(height: 14),

      // Sélecteur jour horizontal
      SizedBox(
        height: 68,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemCount: plan.days.length,
          itemBuilder: (_, i) {
            final day = plan.days[i];
            final selected = _selectedDay == i;
            return GestureDetector(
              onTap: () => setState(() => _selectedDay = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 60,
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 6)],
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(day.dayEmoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(height: 2),
                  Text(day.day.length > 3 ? day.day.substring(0, 3) : day.day,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
                          color: selected ? Colors.white : textLight)),
                ]),
              ),
            );
          },
        ),
      ),

      const SizedBox(height: 14),

      // Contenu du jour
      Expanded(
        child: plan.days.isEmpty
            ? Center(child: Text('Aucun jour', style: TextStyle(color: textLight)))
            : _DayView(
                day: plan.days[_selectedDay],
                isDark: isDark,
                textDark: textDark,
                textLight: textLight,
                surface: surface,
              ),
      ),
    ]);
  }
}

// ── Vue d'un jour ─────────────────────────────
class _DayView extends StatelessWidget {
  final MealDay day;
  final bool isDark;
  final Color textDark, textLight, surface;

  const _DayView({required this.day, required this.isDark,
      required this.textDark, required this.textLight, required this.surface});

  @override
  Widget build(BuildContext context) {
    final mealOrder = ['breakfast', 'lunch', 'snack', 'dinner'];
    final mealLabels = {
      'breakfast': '🌅 Petit-déjeuner',
      'lunch': '☀️ Déjeuner',
      'snack': '🍎 Collation',
      'dinner': '🌙 Dîner',
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Total calories du jour
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(children: [
            const Text('🔥', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text('${day.totalCalories} kcal aujourd\'hui',
                style: TextStyle(fontSize: 13,
                    fontWeight: FontWeight.w700, color: textDark)),
          ]),
        ),
        const SizedBox(height: 14),

        // Repas
        ...mealOrder.where((k) => day.meals.containsKey(k)).map((key) {
          final meal = day.meals[key]!;
          return _MealCard(
            label: mealLabels[key] ?? key,
            meal: meal,
            isDark: isDark,
            textDark: textDark,
            textLight: textLight,
            surface: surface,
          );
        }),

        // Conseil du jour
        if (day.tip.isNotEmpty) ...[
          const SizedBox(height: 6),
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
              Expanded(child: Text(day.tip, style: TextStyle(
                  fontSize: 13, color: textDark, height: 1.4))),
            ]),
          ),
        ],
      ]),
    );
  }
}

class _MealCard extends StatelessWidget {
  final String label;
  final MealItem meal;
  final bool isDark;
  final Color textDark, textLight, surface;

  const _MealCard({required this.label, required this.meal, required this.isDark,
      required this.textDark, required this.textLight, required this.surface});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: surface, borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: AppColors.cardShadow,
          blurRadius: 8, offset: const Offset(0, 3))],
    ),
    child: Row(children: [
      Text(meal.emoji, style: const TextStyle(fontSize: 32)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: textLight)),
        Text(meal.name, style: TextStyle(
            fontSize: 15, fontWeight: FontWeight.w800, color: textDark)),
        if (meal.description.isNotEmpty)
          Text(meal.description, style: TextStyle(
              fontSize: 12, color: textLight, height: 1.3), maxLines: 2,
              overflow: TextOverflow.ellipsis),
      ])),
      const SizedBox(width: 8),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        if (meal.calories > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('${meal.calories} kcal',
                style: const TextStyle(fontSize: 11,
                    color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
        if (meal.duration > 0) ...[
          const SizedBox(height: 4),
          Text('${meal.duration} min',
              style: TextStyle(fontSize: 11, color: textLight)),
        ],
      ]),
    ]),
  );
}

class _SummaryChip extends StatelessWidget {
  final String emoji, value, label;
  final Color textDark, textLight;
  const _SummaryChip(this.emoji, this.value, this.label, this.textDark, this.textLight);

  @override
  Widget build(BuildContext context) => Column(children: [
    Text(emoji, style: const TextStyle(fontSize: 18)),
    Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: textDark)),
    Text(label, style: TextStyle(fontSize: 10, color: textLight)),
  ]);
}

class _LoadingState extends StatelessWidget {
  final Color textLight;
  const _LoadingState({required this.textLight});

  @override
  Widget build(BuildContext context) => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Text('📅', style: TextStyle(fontSize: 60)),
      const SizedBox(height: 16),
      const CircularProgressIndicator(color: AppColors.primary),
      const SizedBox(height: 16),
      Text('Création de votre planning sur mesure...', style: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w700, color: textLight)),
      const SizedBox(height: 6),
      Text('Cela peut prendre 10-20 secondes', style: TextStyle(
          fontSize: 12, color: textLight)),
    ],
  ));
}