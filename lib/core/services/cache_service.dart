import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../features/recipes/data/models/recipe.dart';
import 'recipes_service.dart';
import 'favorites_service.dart';

// ═══════════════════════════════════════════
//  CACHE SERVICE — Mode hors-ligne ForkAI
//
//  Gère :
//  • Cache local de toutes les données clés
//  • Détection de connectivité (tentative API)
//  • Sync automatique au retour en ligne
//  • Indicateur visuel d'état connexion
// ═══════════════════════════════════════════

class CacheService {
  // ── Clés SharedPreferences ────────────────
  static const _keyRecipes       = 'cache_recipes';
  static const _keyFavorites     = 'cache_favorites';
  static const _keyShopping      = 'cache_shopping';
  static const _keyAiRecipes     = 'cache_ai_recipes';
  static const _keyLastSync      = 'cache_last_sync';
  static const _keyIsOnline      = 'cache_is_online';

  // ── État global ───────────────────────────
  static bool _isOnline = true;
  static bool _syncing = false;
  static Timer? _connectivityTimer;

  // Notifier pour l'UI (bannière hors-ligne)
  static final ValueNotifier<bool> onlineNotifier = ValueNotifier(true);
  static final ValueNotifier<bool> syncingNotifier = ValueNotifier(false);

  // ── Initialisation ────────────────────────
  static Future<void> init() async {
    await _checkConnectivity();
    // Vérifie la connectivité toutes les 10 secondes
    _connectivityTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _checkConnectivity(),
    );
  }

  static void dispose() {
    _connectivityTimer?.cancel();
  }

  // ── Connectivité (tentative réelle) ───────
  static Future<void> _checkConnectivity() async {
    try {
      // On tente un appel léger à l'API
      await RecipesService.getCategories()
          .timeout(const Duration(seconds: 5));
      final wasOffline = !_isOnline;
      _isOnline = true;
      onlineNotifier.value = true;

      // Retour en ligne → sync automatique
      if (wasOffline && !_syncing) {
        await _autoSync();
      }
    } catch (_) {
      _isOnline = false;
      onlineNotifier.value = false;
    }
  }

  static bool get isOnline => _isOnline;

  // ── Auto-sync au retour en ligne ──────────
  static Future<void> _autoSync() async {
    if (_syncing) return;
    _syncing = true;
    syncingNotifier.value = true;

    try {
      await Future.wait([
        _syncRecipes(),
        _syncFavorites(),
      ]);
      await _updateLastSync();
    } catch (_) {
      // Silencieux, on réessaiera au prochain check
    } finally {
      _syncing = false;
      syncingNotifier.value = false;
    }
  }

  static Future<void> forcSync() => _autoSync();

  // ── Sync recettes ─────────────────────────
  static Future<void> _syncRecipes() async {
    try {
      final recipes = await RecipesService.getMyRecipes();
      await cacheRecipes(recipes);
    } catch (_) {}
  }

  // ── Sync favoris ──────────────────────────
  static Future<void> _syncFavorites() async {
    try {
      final favs = await FavoritesService.getFavorites();
      await cacheFavorites(favs);
    } catch (_) {}
  }

  // ══════════════════════════════════════════
  //  ÉCRITURE CACHE
  // ══════════════════════════════════════════

  static Future<void> cacheRecipes(List<Recipe> recipes) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(recipes.map((r) => r.toJson()).toList());
    await prefs.setString(_keyRecipes, json);
  }

  static Future<void> cacheFavorites(List<Recipe> recipes) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(recipes.map((r) => r.toJson()).toList());
    await prefs.setString(_keyFavorites, json);
  }

  static Future<void> cacheShoppingLists(dynamic data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyShopping, jsonEncode(data));
  }

  static Future<void> cacheAiRecipes(List<Recipe> recipes) async {
    final prefs = await SharedPreferences.getInstance();
    // Garde seulement les 20 dernières
    final limited = recipes.take(20).toList();
    final json = jsonEncode(limited.map((r) => r.toJson()).toList());
    await prefs.setString(_keyAiRecipes, json);
  }

  static Future<void> _updateLastSync() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastSync, DateTime.now().toIso8601String());
  }

  // ══════════════════════════════════════════
  //  LECTURE CACHE
  // ══════════════════════════════════════════

  static Future<List<Recipe>> getCachedRecipes() async {
    return _loadRecipeList(_keyRecipes);
  }

  static Future<List<Recipe>> getCachedFavorites() async {
    return _loadRecipeList(_keyFavorites);
  }

  static Future<dynamic> getCachedShoppingLists() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyShopping);
    if (raw == null) return null;
    return jsonDecode(raw);
  }

  static Future<List<Recipe>> getCachedAiRecipes() async {
    return _loadRecipeList(_keyAiRecipes);
  }

  static Future<DateTime?> getLastSync() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyLastSync);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  static Future<List<Recipe>> _loadRecipeList(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null) return [];
      final list = jsonDecode(raw) as List;
      return list.map((j) => Recipe.fromJson(
          Map<String, dynamic>.from(j))).toList();
    } catch (_) {
      return [];
    }
  }

  // ══════════════════════════════════════════
  //  NETTOYAGE
  // ══════════════════════════════════════════

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyRecipes);
    await prefs.remove(_keyFavorites);
    await prefs.remove(_keyShopping);
    await prefs.remove(_keyAiRecipes);
    await prefs.remove(_keyLastSync);
  }

  // ── Taille du cache (approximative) ───────
  static Future<String> getCacheSize() async {
    final prefs = await SharedPreferences.getInstance();
    int total = 0;
    for (final key in [_keyRecipes, _keyFavorites, _keyShopping, _keyAiRecipes]) {
      total += prefs.getString(key)?.length ?? 0;
    }
    if (total < 1024) return '${total}o';
    if (total < 1024 * 1024) return '${(total / 1024).toStringAsFixed(1)}Ko';
    return '${(total / (1024 * 1024)).toStringAsFixed(1)}Mo';
  }
}