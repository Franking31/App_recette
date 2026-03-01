import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

// ═══════════════════════════════════════════
//  STREAK SERVICE — Gamification
//  ✅ Streak de cuisine quotidien
//  ✅ Badges & achievements
//  ✅ Points XP
//  ✅ Niveaux chef
// ═══════════════════════════════════════════

class StreakData {
  final int currentStreak;
  final int longestStreak;
  final int totalDays;
  final int xp;
  final int level;
  final String levelName;
  final List<Badge> badges;
  final DateTime? lastCookedAt;
  final bool cookedToday;

  const StreakData({
    required this.currentStreak,
    required this.longestStreak,
    required this.totalDays,
    required this.xp,
    required this.level,
    required this.levelName,
    required this.badges,
    this.lastCookedAt,
    required this.cookedToday,
  });

  factory StreakData.fromJson(Map<String, dynamic> json) {
    final badges = (json['badges'] as List? ?? [])
        .map((b) => Badge.fromJson(b as Map<String, dynamic>))
        .toList();
    return StreakData(
      currentStreak: json['currentStreak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
      totalDays: json['totalDays'] ?? 0,
      xp: json['xp'] ?? 0,
      level: json['level'] ?? 1,
      levelName: json['levelName'] ?? 'Novice',
      badges: badges,
      lastCookedAt: json['lastCookedAt'] != null
          ? DateTime.tryParse(json['lastCookedAt']) : null,
      cookedToday: json['cookedToday'] == true,
    );
  }

  factory StreakData.empty() => const StreakData(
    currentStreak: 0, longestStreak: 0, totalDays: 0,
    xp: 0, level: 1, levelName: 'Novice', badges: [], cookedToday: false,
  );
}

class Badge {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final DateTime? unlockedAt;

  const Badge({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    this.unlockedAt,
  });

  factory Badge.fromJson(Map<String, dynamic> json) => Badge(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    emoji: json['emoji'] ?? '🏆',
    description: json['description'] ?? '',
    unlockedAt: json['unlockedAt'] != null
        ? DateTime.tryParse(json['unlockedAt']) : null,
  );

  bool get isUnlocked => unlockedAt != null;
}

class StreakService {
  static StreakData? _cached;
  static const _cacheKey = 'forkai_streak';

  // ── Récupérer données streak ───────────────
  static Future<StreakData> getStreak() async {
    try {
      final data = await ApiService.get('/streak');
      _cached = StreakData.fromJson(data['streak']);
      return _cached!;
    } catch (_) {
      return _loadLocal();
    }
  }

  // ── Enregistrer une recette cuisinée ──────
  static Future<StreakResult> markCooked(String recipeId, String recipeTitle) async {
    try {
      final data = await ApiService.post('/streak/cook', {
        'recipeId': recipeId,
        'recipeTitle': recipeTitle,
      });
      _cached = StreakData.fromJson(data['streak']);
      _saveLocal(_cached!);
      return StreakResult.fromJson(data);
    } catch (e) {
      return StreakResult(success: false, message: 'Erreur : $e');
    }
  }

  // ── Générer une recette (XP) ───────────────
  static Future<void> markGenerated() async {
    try {
      await ApiService.post('/streak/generate', {});
    } catch (_) {}
  }

  // ── Cache local ────────────────────────────
  static Future<StreakData> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw != null) {
      try { return StreakData.fromJson(jsonDecode(raw)); } catch (_) {}
    }
    return StreakData.empty();
  }

  static Future<void> _saveLocal(StreakData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode({
      'currentStreak': data.currentStreak,
      'longestStreak': data.longestStreak,
      'totalDays': data.totalDays,
      'xp': data.xp,
      'level': data.level,
      'levelName': data.levelName,
      'cookedToday': data.cookedToday,
      'badges': data.badges.map((b) => {
        'id': b.id, 'name': b.name, 'emoji': b.emoji,
        'description': b.description,
        'unlockedAt': b.unlockedAt?.toIso8601String(),
      }).toList(),
    }));
  }

  // ── Niveaux ────────────────────────────────
  static String getLevelName(int level) {
    const levels = [
      'Novice', 'Apprenti', 'Cuisiner', 'Chef de Partie',
      'Sous-Chef', 'Chef', 'Chef Étoilé', 'Grand Chef',
    ];
    return level < levels.length ? levels[level] : 'Maître Chef';
  }

  static int xpForLevel(int level) => level * level * 100;
  static int levelFromXp(int xp) {
    int level = 1;
    while (xpForLevel(level + 1) <= xp) level++;
    return level;
  }
}

class StreakResult {
  final bool success;
  final String message;
  final int? xpGained;
  final List<Badge> newBadges;
  final bool streakIncreased;
  final int? newStreak;

  const StreakResult({
    required this.success,
    required this.message,
    this.xpGained,
    this.newBadges = const [],
    this.streakIncreased = false,
    this.newStreak,
  });

  factory StreakResult.fromJson(Map<String, dynamic> json) => StreakResult(
    success: true,
    message: json['message'] ?? 'Bravo !',
    xpGained: json['xpGained'],
    newBadges: (json['newBadges'] as List? ?? [])
        .map((b) => Badge.fromJson(b as Map<String, dynamic>)).toList(),
    streakIncreased: json['streakIncreased'] == true,
    newStreak: json['newStreak'],
  );
}