import 'package:flutter/material.dart' hide Badge;
import '../../../core/constants/app_colors.dart';
import '../../../core/services/streak_service.dart';

// ═══════════════════════════════════════════
//  STREAK WIDGET — Gamification ForkAI
//  Affichable dans la page profil ou accueil
// ═══════════════════════════════════════════

class StreakWidget extends StatefulWidget {
  final bool compact;
  const StreakWidget({super.key, this.compact = false});

  @override
  State<StreakWidget> createState() => _StreakWidgetState();
}

class _StreakWidgetState extends State<StreakWidget>
    with SingleTickerProviderStateMixin {
  StreakData? _streak;
  bool _loading = true;
  late AnimationController _fireCtrl;

  @override
  void initState() {
    super.initState();
    _fireCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _load();
  }

  @override
  void dispose() { _fireCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    final streak = await StreakService.getStreak();
    if (mounted) setState(() { _streak = streak; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;

    if (_loading) return const SizedBox(height: 80,
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)));

    final s = _streak ?? StreakData.empty();
    return widget.compact ? _buildCompact(s, isDark) : _buildFull(s, surface, isDark);
  }

  // ── Version compacte (pour l'accueil) ─────
  Widget _buildCompact(StreakData s, bool isDark) {
    final textDark = isDark ? AppColors.darkTextDark : AppColors.textDark;
    return GestureDetector(
      onTap: () => _showFullSheet(context, s),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            const Color(0xFFFF6B00).withOpacity(0.12),
            const Color(0xFFFFD166).withOpacity(0.08),
          ]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFF6B00).withOpacity(0.25)),
        ),
        child: Row(children: [
          AnimatedBuilder(
            animation: _fireCtrl,
            builder: (_, __) => Transform.scale(
              scale: 1.0 + 0.05 * _fireCtrl.value,
              child: Text(s.currentStreak > 0 ? '🔥' : '💤',
                  style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${s.currentStreak} jour${s.currentStreak > 1 ? "s" : ""}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900,
                    color: s.currentStreak > 0 ? const Color(0xFFFF6B00) : AppColors.textLight)),
            Text(s.currentStreak > 0 ? 'de streak ! 🎯' : 'Cuisinez aujourd\'hui !',
                style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
          ]),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _levelColor(s.level).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('Niv. ${s.level} · ${s.levelName}',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                    color: _levelColor(s.level))),
          ),
        ]),
      ),
    );
  }

  // ── Version complète (profil) ──────────────
  Widget _buildFull(StreakData s, Color surface, bool isDark) {
    final textDark = isDark ? AppColors.darkTextDark : AppColors.textDark;
    final textLight = isDark ? AppColors.darkTextLight : AppColors.textLight;
    final xpForNext = StreakService.xpForLevel(s.level + 1);
    final xpProgress = s.xp / xpForNext;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Header streak principal
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: s.currentStreak > 0
                ? [const Color(0xFFFF6B00), const Color(0xFFFFD166)]
                : [AppColors.textLight, AppColors.textLight.withOpacity(0.7)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(
            color: (s.currentStreak > 0
                ? const Color(0xFFFF6B00) : AppColors.textLight).withOpacity(0.3),
            blurRadius: 14, offset: const Offset(0, 6),
          )],
        ),
        child: Row(children: [
          AnimatedBuilder(
            animation: _fireCtrl,
            builder: (_, __) => Transform.scale(
              scale: 1.0 + 0.08 * _fireCtrl.value,
              child: Text(s.currentStreak > 0 ? '🔥' : '💤',
                  style: const TextStyle(fontSize: 48)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${s.currentStreak}', style: const TextStyle(
                fontSize: 44, fontWeight: FontWeight.w900, color: Colors.white,
                height: 1.0)),
            Text(s.currentStreak > 1 ? 'jours de suite 🎯'
                : s.currentStreak == 1 ? 'jour · C\'est parti !'
                : 'Commencez votre streak !',
                style: const TextStyle(fontSize: 14, color: Colors.white,
                    fontWeight: FontWeight.w700)),
            if (!s.cookedToday) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Cuisinez aujourd\'hui pour continuer !',
                    style: TextStyle(fontSize: 10, color: Colors.white,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ])),
          Column(children: [
            Text('🏆 Record', style: TextStyle(
                fontSize: 10, color: Colors.white.withOpacity(0.8))),
            Text('${s.longestStreak}j', style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
          ]),
        ]),
      ),

      const SizedBox(height: 16),

      // Stats row
      Row(children: [
        _StatCard('📅', '${s.totalDays}', 'jours cuisinés', surface, textDark, textLight),
        const SizedBox(width: 10),
        _StatCard('⭐', '${s.xp}', 'points XP', surface, textDark, textLight),
        const SizedBox(width: 10),
        _StatCard('🎖️', '${s.badges.where((b) => b.isUnlocked).length}', 'badges', surface, textDark, textLight),
      ]),

      const SizedBox(height: 16),

      // Niveau + barre XP
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 8)]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _levelColor(s.level).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('⚡ Niv. ${s.level} · ${s.levelName}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800,
                      color: _levelColor(s.level))),
            ),
            const Spacer(),
            Text('${s.xp} / ${xpForNext} XP',
                style: TextStyle(fontSize: 11, color: textLight)),
          ]),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: xpProgress.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: _levelColor(s.level).withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation(_levelColor(s.level)),
            ),
          ),
          const SizedBox(height: 6),
          Text('${xpForNext - s.xp} XP pour atteindre ${StreakService.getLevelName(s.level + 1)}',
              style: TextStyle(fontSize: 11, color: textLight)),
        ]),
      ),

      const SizedBox(height: 16),

      // Badges
      Text('🏅 Badges', style: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w800, color: textDark)),
      const SizedBox(height: 10),

      GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10, crossAxisSpacing: 10,
        childAspectRatio: 0.85,
        children: _allBadges(s).map((b) => _BadgeTile(badge: b)).toList(),
      ),
    ]);
  }

  List<Badge> _allBadges(StreakData s) {
    final unlocked = {for (final b in s.badges) b.id: b};
    final all = [
      Badge(id: 'first_cook', name: 'Premier plat', emoji: '🍽️',
          description: 'Cuisiner pour la première fois'),
      Badge(id: 'streak_3', name: '3 jours', emoji: '🔥',
          description: '3 jours de suite'),
      Badge(id: 'streak_7', name: 'Semaine', emoji: '🌟',
          description: '7 jours de suite'),
      Badge(id: 'streak_30', name: 'Mois', emoji: '👑',
          description: '30 jours de suite'),
      Badge(id: 'recipes_10', name: '10 recettes', emoji: '📚',
          description: '10 recettes générées'),
      Badge(id: 'budget_master', name: 'Éco-chef', emoji: '💰',
          description: '5 recettes budget'),
      Badge(id: 'healthy', name: 'Healthy', emoji: '🥗',
          description: '10 recettes saines'),
      Badge(id: 'creative', name: 'Créatif', emoji: '🎨',
          description: '5 plats créatifs'),
    ];
    return all.map((b) => unlocked[b.id] ?? b).toList();
  }

  Color _levelColor(int level) {
    if (level >= 7) return const Color(0xFFFFD700);
    if (level >= 5) return const Color(0xFF9C27B0);
    if (level >= 3) return const Color(0xFF2196F3);
    return const Color(0xFF4CAF50);
  }

  void _showFullSheet(BuildContext context, StreakData s) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85, maxChildSize: 0.95, minChildSize: 0.5,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkSurface : AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: ListView(controller: controller, children: [
            Center(child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.textLight.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            )),
            const SizedBox(height: 16),
            StreakWidget(),
          ]),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String emoji, value, label;
  final Color surface, textDark, textLight;
  const _StatCard(this.emoji, this.value, this.label,
      this.surface, this.textDark, this.textLight);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 6)]),
      child: Column(children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 18,
            fontWeight: FontWeight.w900, color: textDark)),
        Text(label, style: TextStyle(fontSize: 10, color: textLight)),
      ]),
    ),
  );
}

class _BadgeTile extends StatelessWidget {
  final Badge badge;
  const _BadgeTile({required this.badge});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    return Container(
      decoration: BoxDecoration(
        color: badge.isUnlocked ? surface : surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: badge.isUnlocked
              ? const Color(0xFFFFD166).withOpacity(0.5) : Colors.transparent,
        ),
        boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 6)],
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        ColorFiltered(
          colorFilter: badge.isUnlocked
              ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
              : const ColorFilter.matrix([
                  0.2, 0.2, 0.2, 0, 0,
                  0.2, 0.2, 0.2, 0, 0,
                  0.2, 0.2, 0.2, 0, 0,
                  0,   0,   0,   0.5, 0,
                ]),
          child: Text(badge.emoji, style: const TextStyle(fontSize: 26)),
        ),
        const SizedBox(height: 4),
        Text(badge.name,
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                color: badge.isUnlocked ? AppColors.textDark : AppColors.textLight),
            textAlign: TextAlign.center, maxLines: 2),
      ]),
    );
  }
}