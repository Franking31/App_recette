import 'dart:js' as js;
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/vision_service.dart';

// ═══════════════════════════════════════════
//  PLANNING DE REPAS SEMAINE — v2
//  ✅ Layout adaptatif PC / Mobile
//  ✅ Export PDF / Partage
//  ✅ Réponses IA visuellement enrichies
// ═══════════════════════════════════════════

class MealPlanPage extends StatefulWidget {
  const MealPlanPage({super.key});
  @override
  State<MealPlanPage> createState() => _MealPlanPageState();
}

class _MealPlanPageState extends State<MealPlanPage>
    with SingleTickerProviderStateMixin {
  MealPlan? _plan;
  bool _loading = false;
  String? _error;
  int _selectedDay = 0;
  late TabController _tabController;

  int _servings = 2;
  final _prefCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();
  final _diets = ['Aucun', 'Végétarien', 'Vegan', 'Sans gluten',
      'Méditerranéen', 'Low carb', 'Keto'];
  String _selectedDiet = 'Aucun';
  bool _showForm = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _selectedDay = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _prefCtrl.dispose();
    _budgetCtrl.dispose();
    _tabController.dispose();
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
      if (mounted) {
        setState(() { _plan = plan; _loading = false; _selectedDay = 0; });
        _tabController.animateTo(0);
      }
    } catch (e) {
      if (mounted) setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
        _showForm = true;
      });
    }
  }

  // ── Export PDF via window.print() ─────────
  void _exportPDF() {
    if (_plan == null) return;
    final html = _buildPlanHTML(_plan!);
    js.context.callMethod('eval', ['''
      (function() {
        var w = window.open('', '_blank');
        w.document.write(${_jsStr(html)});
        w.document.close();
        setTimeout(function(){ w.print(); }, 500);
      })();
    ''']);
  }

  // ── Partage via Web Share API ──────────────
  void _share() {
    if (_plan == null) return;
    final text = _buildPlanText(_plan!);
    js.context.callMethod('eval', ['''
      (function() {
        if (navigator.share) {
          navigator.share({
            title: 'Mon Planning ForkAI',
            text: ${_jsStr(text)},
          });
        } else {
          navigator.clipboard.writeText(${_jsStr(text)}).then(function() {
            alert('Planning copié dans le presse-papier !');
          });
        }
      })();
    ''']);
  }

  String _jsStr(String s) =>
      '`${s.replaceAll('\\', '\\\\').replaceAll('`', '\\`').replaceAll('\$', '\\\$')}`';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.background;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final textDark = isDark ? AppColors.darkTextDark : AppColors.textDark;
    final textLight = isDark ? AppColors.darkTextLight : AppColors.textLight;
    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(children: [
          // ── HEADER ───────────────────────────
          _buildHeader(surface, textDark, textLight, isDark),

          Expanded(
            child: _loading
                ? _LoadingState(textLight: textLight)
                : _showForm
                    ? _buildForm(surface, textDark, textLight, isWide)
                    : _plan != null
                        ? isWide
                            ? _buildWideLayout(isDark, surface, textDark, textLight)
                            : _buildMobileLayout(isDark, surface, textDark, textLight)
                        : const SizedBox(),
          ),

          if (_error != null)
            _ErrorBanner(error: _error!),
        ]),
      ),
    );
  }

  // ── HEADER ────────────────────────────────
  Widget _buildHeader(Color surface, Color textDark, Color textLight, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.primary),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('📅 Planning Semaine', style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.w900, color: textDark)),
          Text('7 jours de repas équilibrés · personnalisé par IA',
              style: TextStyle(fontSize: 11, color: textLight)),
        ])),

        if (_plan != null) ...[
          // Export PDF
          _HeaderAction(
            icon: Icons.picture_as_pdf_rounded,
            label: 'PDF',
            color: Colors.red,
            onTap: _exportPDF,
            surface: AppColors.surface,
          ),
          const SizedBox(width: 8),
          // Partager
          _HeaderAction(
            icon: Icons.share_rounded,
            label: 'Partager',
            color: AppColors.primary,
            onTap: _share,
            surface: AppColors.surface,
          ),
          const SizedBox(width: 8),
          // Recréer
          _HeaderAction(
            icon: Icons.refresh_rounded,
            label: 'Recréer',
            color: AppColors.textLight,
            onTap: () => setState(() { _showForm = true; _plan = null; }),
            surface: AppColors.surface,
          ),
        ],
      ]),
    );
  }

  // ── FORMULAIRE ────────────────────────────
  Widget _buildForm(Color surface, Color textDark, Color textLight, bool isWide) {
    final formContent = SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Hero illustration
        Center(child: Container(
          width: 90, height: 90,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              AppColors.primary.withOpacity(0.15),
              AppColors.accent.withOpacity(0.15),
            ]),
            shape: BoxShape.circle,
          ),
          child: const Center(child: Text('📅', style: TextStyle(fontSize: 44))),
        )),
        const SizedBox(height: 8),
        Center(child: Text('Générer mon planning',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textDark))),
        Center(child: Text('L\'IA adapte chaque repas à vos préférences',
            style: TextStyle(fontSize: 12, color: textLight))),
        const SizedBox(height: 28),

        // Personnes
        _FormLabel('👥 Nombre de personnes', textDark),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _CounterBtn(icon: Icons.remove, onTap: () =>
              setState(() => _servings = (_servings - 1).clamp(1, 20)),
              color: textLight, bg: surface),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('$_servings', style: TextStyle(
                  fontSize: 36, fontWeight: FontWeight.w900, color: textDark))),
          _CounterBtn(icon: Icons.add, onTap: () =>
              setState(() => _servings = (_servings + 1).clamp(1, 20)),
              color: Colors.white, bg: AppColors.primary),
        ]),
        const SizedBox(height: 20),

        // Régime
        _FormLabel('🥗 Régime alimentaire', textDark),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8,
          children: _diets.map((d) {
            final sel = _selectedDiet == d;
            return GestureDetector(
              onTap: () => setState(() => _selectedDiet = d),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: sel ? AppColors.primary : surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 4)],
                ),
                child: Text(d, style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    color: sel ? Colors.white : textLight)),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        // Budget
        _FormLabel('💰 Budget hebdomadaire (optionnel)', textDark),
        const SizedBox(height: 8),
        _StyledField(controller: _budgetCtrl, hint: 'Ex: 60€ par semaine',
            icon: Icons.euro_rounded, surface: surface, textDark: textDark,
            textLight: textLight),
        const SizedBox(height: 16),

        // Préférences
        _FormLabel('✨ Préférences & contraintes', textDark),
        const SizedBox(height: 8),
        _StyledField(controller: _prefCtrl,
            hint: 'Ex: Pas de poisson, j\'aime les cuisines asiatiques, repas rapides en semaine...',
            icon: Icons.tune_rounded, surface: surface, textDark: textDark,
            textLight: textLight, maxLines: 3),
        const SizedBox(height: 28),

        // Bouton
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

    if (!isWide) return formContent;

    // Layout PC : centré avec largeur max
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: formContent,
      ),
    );
  }

  // ── LAYOUT MOBILE ─────────────────────────
  Widget _buildMobileLayout(bool isDark, Color surface, Color textDark, Color textLight) {
    final plan = _plan!;
    return Column(children: [
      _WeekSummaryBar(plan: plan, textDark: textDark, textLight: textLight),
      const SizedBox(height: 12),
      _DayTabBar(
        days: plan.days,
        selectedDay: _selectedDay,
        surface: surface,
        textLight: textLight,
        onSelect: (i) => setState(() {
          _selectedDay = i;
          _tabController.animateTo(i);
        }),
      ),
      const SizedBox(height: 12),
      Expanded(child: _DayView(
        day: plan.days[_selectedDay],
        isDark: isDark,
        textDark: textDark,
        textLight: textLight,
        surface: surface,
      )),
    ]);
  }

  // ── LAYOUT PC : sidebar + contenu ─────────
  Widget _buildWideLayout(bool isDark, Color surface, Color textDark, Color textLight) {
    final plan = _plan!;
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Sidebar : tous les jours
      Container(
        width: 220,
        decoration: BoxDecoration(
          color: surface,
          boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 8)],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Résumé semaine
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Semaine', style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w800, color: textDark)),
              const SizedBox(height: 10),
              _WeekSummaryBar(plan: plan, textDark: textDark,
                  textLight: textLight, compact: true),
            ]),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: plan.days.length,
              itemBuilder: (_, i) {
                final day = plan.days[i];
                final sel = _selectedDay == i;
                return GestureDetector(
                  onTap: () => setState(() => _selectedDay = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: sel ? AppColors.primary.withOpacity(0.3) : Colors.transparent,
                      ),
                    ),
                    child: Row(children: [
                      Text(day.dayEmoji, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 10),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(day.day, style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w800,
                              color: sel ? AppColors.primary : textDark)),
                          if (day.totalCalories > 0)
                            Text('${day.totalCalories} kcal',
                                style: TextStyle(fontSize: 10, color: textLight)),
                        ],
                      )),
                      if (sel)
                        const Icon(Icons.chevron_right_rounded,
                            size: 16, color: AppColors.primary),
                    ]),
                  ),
                );
              },
            ),
          ),
        ]),
      ),

      // Contenu principal
      Expanded(child: _DayView(
        day: plan.days[_selectedDay],
        isDark: isDark,
        textDark: textDark,
        textLight: textLight,
        surface: surface,
        wide: true,
      )),
    ]);
  }

  // ── GÉNÉRATION HTML POUR PDF ───────────────
  String _buildPlanHTML(MealPlan plan) {
    final sb = StringBuffer();
    sb.write('''<!DOCTYPE html>
<html><head><meta charset="UTF-8">
<style>
  body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
    background: #FAF6F1; color: #1C1C1E; margin: 0; padding: 30px; }
  h1 { font-size: 28px; color: #E8604A; margin-bottom: 4px; }
  .subtitle { color: #8E8E93; font-size: 13px; margin-bottom: 24px; }
  .week-summary { background: linear-gradient(135deg, #FFF8F0, #FAF6F1);
    border: 1px solid #E8604A33; border-radius: 14px;
    padding: 16px 20px; display: flex; gap: 24px; margin-bottom: 24px; }
  .sum-item { text-align: center; }
  .sum-value { font-size: 20px; font-weight: 900; color: #E8604A; }
  .sum-label { font-size: 11px; color: #8E8E93; }
  .day { page-break-inside: avoid; margin-bottom: 28px; }
  .day-title { font-size: 18px; font-weight: 800; color: #E8604A;
    border-bottom: 2px solid #E8604A22; padding-bottom: 6px; margin-bottom: 12px; }
  .meal { background: white; border-radius: 12px; padding: 12px 16px;
    margin-bottom: 10px; display: flex; align-items: flex-start; gap: 12px;
    box-shadow: 0 2px 8px rgba(0,0,0,0.06); }
  .meal-emoji { font-size: 28px; }
  .meal-label { font-size: 10px; color: #8E8E93; text-transform: uppercase;
    font-weight: 700; letter-spacing: 0.5px; }
  .meal-name { font-size: 15px; font-weight: 800; color: #1C1C1E; }
  .meal-desc { font-size: 12px; color: #8E8E93; margin-top: 2px; }
  .meal-kcal { background: #E8604A15; color: #E8604A; font-weight: 700;
    font-size: 11px; padding: 3px 8px; border-radius: 6px; white-space: nowrap; }
  .tip { background: #FFD16620; border: 1px solid #FFD16640; border-radius: 10px;
    padding: 10px 14px; font-size: 12px; color: #666; margin-top: 8px; }
  .footer { text-align: center; color: #8E8E93; font-size: 11px; margin-top: 40px;
    padding-top: 16px; border-top: 1px solid #E5E5E5; }
  @media print { body { background: white; } }
</style></head><body>
<h1>📅 Planning de repas</h1>
<p class="subtitle">Généré par ForkAI · ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}</p>''');

    // Résumé semaine
    final s = plan.weekSummary;
    sb.write('''<div class="week-summary">
      <div class="sum-item"><div class="sum-value">🔥 ${s['avgCalories'] ?? '~'}</div><div class="sum-label">kcal/jour</div></div>
      <div class="sum-item"><div class="sum-value">💰 ${s['totalBudget'] ?? '~'}</div><div class="sum-label">budget</div></div>
      <div class="sum-item"><div class="sum-value">⏱ ${s['prepTime'] ?? '~'}</div><div class="sum-label">prépa moy.</div></div>
    </div>''');

    // Jours
    final mealOrder = ['breakfast', 'lunch', 'snack', 'dinner'];
    final mealLabels = {
      'breakfast': '🌅 Petit-déjeuner', 'lunch': '☀️ Déjeuner',
      'snack': '🍎 Collation', 'dinner': '🌙 Dîner',
    };
    for (final day in plan.days) {
      sb.write('<div class="day">');
      sb.write('<div class="day-title">${day.dayEmoji} ${day.day}'
          '${day.totalCalories > 0 ? " · ${day.totalCalories} kcal" : ""}</div>');
      for (final key in mealOrder.where((k) => day.meals.containsKey(k))) {
        final meal = day.meals[key]!;
        sb.write('''<div class="meal">
          <div class="meal-emoji">${meal.emoji}</div>
          <div style="flex:1">
            <div class="meal-label">${mealLabels[key] ?? key}</div>
            <div class="meal-name">${meal.name}</div>
            ${meal.description.isNotEmpty ? '<div class="meal-desc">${meal.description}</div>' : ''}
          </div>
          ${meal.calories > 0 ? '<div class="meal-kcal">${meal.calories} kcal</div>' : ''}
        </div>''');
      }
      if (day.tip.isNotEmpty) {
        sb.write('<div class="tip">💡 ${day.tip}</div>');
      }
      sb.write('</div>');
    }
    sb.write('<div class="footer">ForkAI · Votre chef personnel IA</div>');
    sb.write('</body></html>');
    return sb.toString();
  }

  String _buildPlanText(MealPlan plan) {
    final sb = StringBuffer();
    sb.writeln('📅 MON PLANNING FORKAI');
    sb.writeln('═══════════════════════');
    for (final day in plan.days) {
      sb.writeln('\n${day.dayEmoji} ${day.day.toUpperCase()}');
      final mealOrder = ['breakfast', 'lunch', 'snack', 'dinner'];
      final mealLabels = {
        'breakfast': 'Petit-déj', 'lunch': 'Déjeuner',
        'snack': 'Collation', 'dinner': 'Dîner',
      };
      for (final key in mealOrder.where((k) => day.meals.containsKey(k))) {
        final meal = day.meals[key]!;
        sb.writeln('  ${meal.emoji} ${mealLabels[key]}: ${meal.name}'
            '${meal.calories > 0 ? " (${meal.calories} kcal)" : ""}');
      }
      if (day.tip.isNotEmpty) sb.writeln('  💡 ${day.tip}');
    }
    sb.writeln('\nGénéré par ForkAI 🍴');
    return sb.toString();
  }
}

// ═══════════════════════════════════════════
//  WIDGETS RÉUTILISABLES
// ═══════════════════════════════════════════

class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color, surface;
  final VoidCallback onTap;
  const _HeaderAction({required this.icon, required this.label,
      required this.color, required this.surface, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12,
            fontWeight: FontWeight.w700, color: color)),
      ]),
    ),
  );
}

class _WeekSummaryBar extends StatelessWidget {
  final MealPlan plan;
  final Color textDark, textLight;
  final bool compact;
  const _WeekSummaryBar({required this.plan, required this.textDark,
      required this.textLight, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final s = plan.weekSummary;
    return Container(
      margin: compact ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          AppColors.primary.withOpacity(0.08),
          AppColors.accent.withOpacity(0.08),
        ]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: compact
          ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _chip('🔥', '${s['avgCalories'] ?? '~'} kcal/j', textDark, textLight),
              const SizedBox(height: 6),
              _chip('💰', '${s['totalBudget'] ?? '~'}', textDark, textLight),
              const SizedBox(height: 6),
              _chip('⏱', '${s['prepTime'] ?? '~'} prépa', textDark, textLight),
            ])
          : Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _SummaryChip('🔥', '${s['avgCalories'] ?? '~'}', 'kcal/jour', textDark, textLight),
              _SummaryChip('💰', '${s['totalBudget'] ?? '~'}', 'budget', textDark, textLight),
              _SummaryChip('⏱', '${s['prepTime'] ?? '~'}', 'prépa moy.', textDark, textLight),
            ]),
    );
  }

  Widget _chip(String e, String t, Color td, Color tl) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(e, style: const TextStyle(fontSize: 12)),
      const SizedBox(width: 6),
      Text(t, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: td)),
    ],
  );
}

class _DayTabBar extends StatelessWidget {
  final List<MealDay> days;
  final int selectedDay;
  final Color surface, textLight;
  final ValueChanged<int> onSelect;
  const _DayTabBar({required this.days, required this.selectedDay,
      required this.surface, required this.textLight, required this.onSelect});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 68,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemCount: days.length,
      itemBuilder: (_, i) {
        final day = days[i];
        final sel = selectedDay == i;
        return GestureDetector(
          onTap: () => onSelect(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 62,
            decoration: BoxDecoration(
              color: sel ? AppColors.primary : surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: sel ? [
                BoxShadow(color: AppColors.primary.withOpacity(0.35),
                    blurRadius: 10, offset: const Offset(0, 4)),
              ] : [BoxShadow(color: AppColors.cardShadow, blurRadius: 6)],
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(day.dayEmoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 2),
              Text(day.day.length > 3 ? day.day.substring(0, 3) : day.day,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
                      color: sel ? Colors.white : textLight)),
            ]),
          ),
        );
      },
    ),
  );
}

// ── Vue d'un jour — améliorée visuellement ──
class _DayView extends StatelessWidget {
  final MealDay day;
  final bool isDark;
  final Color textDark, textLight, surface;
  final bool wide;

  const _DayView({required this.day, required this.isDark,
      required this.textDark, required this.textLight,
      required this.surface, this.wide = false});

  @override
  Widget build(BuildContext context) {
    final mealOrder = ['breakfast', 'lunch', 'snack', 'dinner'];
    final mealLabels = {
      'breakfast': '🌅 Petit-déjeuner', 'lunch': '☀️ Déjeuner',
      'snack': '🍎 Collation', 'dinner': '🌙 Dîner',
    };
    final mealColors = {
      'breakfast': const Color(0xFFFF9800),
      'lunch': const Color(0xFF4CAF50),
      'snack': const Color(0xFF9C27B0),
      'dinner': const Color(0xFF2196F3),
    };

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(wide ? 24 : 20, 12, wide ? 24 : 20, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Titre du jour + calories
        Row(children: [
          Text('${day.dayEmoji} ${day.day}',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textDark)),
          const Spacer(),
          if (day.totalCalories > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('🔥 ${day.totalCalories} kcal',
                  style: const TextStyle(fontSize: 12, color: AppColors.primary,
                      fontWeight: FontWeight.w800)),
            ),
        ]),
        const SizedBox(height: 14),

        // Repas — layout 2 colonnes sur PC
        if (wide)
          _buildWideGrid(mealOrder as Map<String, String>, mealLabels, mealColors)
        else
          ...mealOrder.where((k) => day.meals.containsKey(k)).map((key) =>
            _MealCard(
              label: mealLabels[key] ?? key,
              accentColor: mealColors[key] ?? AppColors.primary,
              meal: day.meals[key]!,
              isDark: isDark, textDark: textDark,
              textLight: textLight, surface: surface,
            ),
          ),

        // Conseil IA enrichi visuellement
        if (day.tip.isNotEmpty) ...[
          const SizedBox(height: 8),
          _AITipCard(tip: day.tip, textDark: textDark, textLight: textLight),
        ],
      ]),
    );
  }

  Widget _buildWideGrid(Map<String, String> mealLabels,
      Map<String, String> mealOrder, Map<String, Color> mealColors) {
    final keys = ['breakfast', 'lunch', 'snack', 'dinner']
        .where((k) => day.meals.containsKey(k)).toList();
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: keys.map((key) => _MealCard(
        label: mealLabels[key] ?? key,
        accentColor: mealColors[key] ?? AppColors.primary,
        meal: day.meals[key]!,
        isDark: isDark, textDark: textDark,
        textLight: textLight, surface: surface,
      )).toList(),
    );
  }
}

// ── Carte repas — design enrichi ─────────
class _MealCard extends StatelessWidget {
  final String label;
  final Color accentColor;
  final MealItem meal;
  final bool isDark;
  final Color textDark, textLight, surface;

  const _MealCard({required this.label, required this.accentColor,
      required this.meal, required this.isDark, required this.textDark,
      required this.textLight, required this.surface});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [BoxShadow(color: AppColors.cardShadow,
          blurRadius: 10, offset: const Offset(0, 4))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // En-tête coloré
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: accentColor.withOpacity(0.1),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
          ),
        ),
        child: Row(children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w800, color: accentColor)),
          const Spacer(),
          if (meal.calories > 0)
            Text('${meal.calories} kcal', style: TextStyle(
                fontSize: 11, color: accentColor.withOpacity(0.8),
                fontWeight: FontWeight.w600)),
        ]),
      ),
      // Contenu
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        child: Row(children: [
          Text(meal.emoji, style: const TextStyle(fontSize: 30)),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(meal.name, style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w800, color: textDark)),
              if (meal.description.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(meal.description, style: TextStyle(
                    fontSize: 12, color: textLight, height: 1.3),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
              if (meal.duration > 0) ...[
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.schedule_rounded, size: 11, color: textLight),
                  const SizedBox(width: 3),
                  Text('${meal.duration} min',
                      style: TextStyle(fontSize: 11, color: textLight)),
                ]),
              ],
            ],
          )),
        ]),
      ),
    ]),
  );
}

// ── Conseil IA — visuellement enrichi ────
class _AITipCard extends StatelessWidget {
  final String tip;
  final Color textDark, textLight;
  const _AITipCard({required this.tip, required this.textDark, required this.textLight});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [AppColors.accent.withOpacity(0.15), AppColors.accent.withOpacity(0.05)],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.accent.withOpacity(0.3)),
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: const Text('💡', style: TextStyle(fontSize: 16)),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Conseil du jour', style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w800,
              color: const Color(0xFFB8860B))),
          const SizedBox(height: 4),
          Text(tip, style: TextStyle(
              fontSize: 13, color: textDark, height: 1.5)),
        ],
      )),
    ]),
  );
}

class _SummaryChip extends StatelessWidget {
  final String emoji, value, label;
  final Color textDark, textLight;
  const _SummaryChip(this.emoji, this.value, this.label, this.textDark, this.textLight);

  @override
  Widget build(BuildContext context) => Column(children: [
    Text(emoji, style: const TextStyle(fontSize: 20)),
    Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: textDark)),
    Text(label, style: TextStyle(fontSize: 10, color: textLight)),
  ]);
}

class _FormLabel extends StatelessWidget {
  final String text;
  final Color color;
  const _FormLabel(this.text, this.color);
  @override
  Widget build(BuildContext context) => Text(text,
      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color));
}

class _CounterBtn extends StatelessWidget {
  final IconData icon;
  final Color color, bg;
  final VoidCallback onTap;
  const _CounterBtn({required this.icon, required this.color,
      required this.bg, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 42, height: 42,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 6)]),
      child: Icon(icon, color: color, size: 20),
    ),
  );
}

class _StyledField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final Color surface, textDark, textLight;
  final int maxLines;
  const _StyledField({required this.controller, required this.hint,
      required this.icon, required this.surface, required this.textDark,
      required this.textLight, this.maxLines = 1});

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    maxLines: maxLines,
    style: TextStyle(color: textDark, fontSize: 14),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: textLight, fontSize: 13),
      filled: true, fillColor: surface,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      prefixIcon: Icon(icon, color: textLight, size: 18),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
  );
}

class _ErrorBanner extends StatelessWidget {
  final String error;
  const _ErrorBanner({required this.error});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.all(16),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14)),
    child: Row(children: [
      const Icon(Icons.error_outline, color: Colors.red, size: 18),
      const SizedBox(width: 8),
      Expanded(child: Text(error, style: const TextStyle(color: Colors.red, fontSize: 13))),
    ]),
  );
}

class _LoadingState extends StatelessWidget {
  final Color textLight;
  const _LoadingState({required this.textLight});
  @override
  Widget build(BuildContext context) => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Text('📅', style: TextStyle(fontSize: 64)),
      const SizedBox(height: 20),
      const SizedBox(width: 36, height: 36,
          child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3)),
      const SizedBox(height: 16),
      Text('Création de votre planning sur mesure...',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textLight)),
      const SizedBox(height: 6),
      Text('L\'IA analyse vos préférences · 10-20 secondes',
          style: TextStyle(fontSize: 12, color: textLight.withOpacity(0.6))),
    ],
  ));
}