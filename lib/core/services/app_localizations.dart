import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ═══════════════════════════════════════════
//  LOCALISATION — ForkAI
//  Système i18n léger sans dépendance externe
//  Langues : FR 🇫🇷 / EN 🇬🇧 / ES 🇪🇸
// ═══════════════════════════════════════════

enum AppLanguage { fr, en, es }

class AppLocalizations {
  static AppLanguage _current = AppLanguage.fr;
  static final ValueNotifier<AppLanguage> languageNotifier =
      ValueNotifier(AppLanguage.fr);

  static const _prefKey = 'app_language';

  // ── Init depuis SharedPreferences ─────────
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);
    if (saved != null) {
      _current = AppLanguage.values.firstWhere(
        (l) => l.name == saved,
        orElse: () => AppLanguage.fr,
      );
      languageNotifier.value = _current;
    }
  }

  // ── Changer la langue ─────────────────────
  static Future<void> setLanguage(AppLanguage lang) async {
    _current = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, lang.name);
    // Notifie en dernier pour que la valeur soit déjà sauvegardée
    languageNotifier.value = lang;
  }

  static AppLanguage get current => _current;

  static String get languageLabel {
    switch (_current) {
      case AppLanguage.fr: return '🇫🇷 Français';
      case AppLanguage.en: return '🇬🇧 English';
      case AppLanguage.es: return '🇪🇸 Español';
    }
  }

  // ══════════════════════════════════════════
  //  TRADUCTIONS
  // ══════════════════════════════════════════
  static String t(String key) =>
      _translations[_current]?[key] ??
      _translations[AppLanguage.fr]?[key] ??
      key;

  static final Map<AppLanguage, Map<String, String>> _translations = {

    // ────────────────────────────────────────
    AppLanguage.fr: {
      // Général
      'app_name': 'ForkAI',
      'loading': 'Chargement...',
      'error': 'Erreur',
      'retry': 'Réessayer',
      'cancel': 'Annuler',
      'save': 'Sauvegarder',
      'delete': 'Supprimer',
      'confirm': 'Confirmer',
      'close': 'Fermer',
      'back': 'Retour',
      'next': 'Suivant',
      'done': 'Terminé',
      'skip': 'Passer',
      'yes': 'Oui',
      'no': 'Non',
      'search': 'Rechercher',
      'filter': 'Filtrer',
      'all': 'Tout',

      // Navigation
      'nav_recipes': 'Recettes',
      'nav_ai': 'IA',
      'nav_shopping': 'Courses',
      'nav_profile': 'Profil',

      // Recettes
      'recipes_title': '👨‍🍳 Mes Recettes',
      'recipes_count': 'recettes disponibles',
      'recipes_search_hint': 'Rechercher une recette...',
      'recipes_empty': 'Aucune recette trouvée',
      'recipes_ingredients': 'Ingrédients',
      'recipes_steps': 'Préparation',
      'recipes_duration': 'min',
      'recipes_servings': 'personnes',
      'recipes_save': 'Sauvegarder la recette',
      'recipes_saved': '✅ Recette sauvegardée !',
      'recipes_delete_confirm': 'Supprimer cette recette ?',
      'recipes_add_shopping': 'Ajouter à la liste de courses',

      // IA / Assistant
      'ai_title': 'Assistant IA',
      'ai_generate': 'Générer une recette',
      'ai_anti_waste': 'Anti-gaspi',
      'ai_meal_plan': 'Plan de repas',
      'ai_shopping': 'Liste de courses',
      'ai_analyze': 'Analyser',
      'ai_nutrition': 'Nutrition',
      'ai_creative': 'Créatif',
      'ai_chat': 'Assistant',
      'ai_photo': 'Photo',
      'ai_substitute': 'Substitution',
      'ai_tools': 'Outils',
      'ai_thinking': 'Réflexion en cours...',
      'ai_send': 'Envoyer',
      'ai_placeholder': 'Posez votre question...',

      // Photo recette
      'photo_title': 'Photo → Recette',
      'photo_pick': 'Cliquez pour sélectionner une photo',
      'photo_change': 'Changer',
      'photo_analyze': 'Analyser & Cuisiner',
      'photo_analyzing': 'Analyse en cours...',
      'photo_servings': 'Personnes',
      'photo_detected': 'Ingrédients détectés',
      'photo_recipes_found': 'recettes générées',
      'photo_error_no_food': 'Aucun ingrédient alimentaire détecté.',

      // Favoris
      'favorites_title': 'Favoris',
      'favorites_add': 'Ajouté aux favoris',
      'favorites_remove': 'Retiré des favoris',
      'favorites_empty': 'Aucun favori pour l\'instant',

      // Courses
      'shopping_title': 'Liste de courses',
      'shopping_add': 'Ajouter un article',
      'shopping_empty': 'Liste vide',
      'shopping_clear': 'Vider la liste',

      // Profil
      'profile_title': 'Profil',
      'profile_ai_recipes': 'recettes IA générées',
      'profile_favorites': 'Favoris',
      'profile_dark_mode': 'Mode sombre',
      'profile_light_mode': 'Mode clair',
      'profile_language': 'Langue',
      'profile_history': 'Historique conversations IA',
      'profile_logout': 'Se déconnecter',
      'profile_logout_confirm': 'Se déconnecter ?',
      'profile_version': 'ForkAI v1.0',

      // Auth
      'auth_login': 'Connexion',
      'auth_signup': 'Créer un compte',
      'auth_email': 'Email',
      'auth_password': 'Mot de passe',
      'auth_forgot': 'Mot de passe oublié ?',
      'auth_no_account': 'Pas encore de compte ?',
      'auth_already_account': 'Déjà un compte ?',
      'auth_welcome': 'Bon retour !',
      'auth_create': 'Créer votre compte',

      // Onboarding
      'onboarding_welcome': 'Bienvenue sur',
      'onboarding_subtitle': 'Votre chef personnel alimenté par l\'intelligence artificielle',
      'onboarding_photo_title': 'Photographiez\nvotre frigo',
      'onboarding_photo_sub': 'Gemini Vision analyse vos ingrédients et génère 5 recettes personnalisées',
      'onboarding_ai_title': 'Propulsé par\ndes IA de pointe',
      'onboarding_account_title': 'Prêt à cuisiner\ndifféremment ?',
      'onboarding_create_account': 'Créer un compte gratuit',
      'onboarding_already': 'J\'ai déjà un compte',

      // Erreurs
      'error_network': 'Erreur réseau. Vérifiez votre connexion.',
      'error_timeout': 'Délai dépassé. Réessayez.',
      'error_unknown': 'Une erreur est survenue.',
      'offline_banner': 'Mode hors-ligne — données en cache',
      'syncing_banner': 'Synchronisation en cours...',

      // Recherche
      'search_title': 'Recherche',
      'search_hint': 'Titre, ingrédient...',
      'search_results': 'résultat',
      'search_results_plural': 'résultats',
      'search_empty': 'Aucune recette trouvée',
      'search_recent': 'Recherches récentes',
      'search_clear': 'Effacer',
      'search_placeholder': 'Recherchez par titre\nou par ingrédient',
    },

    // ────────────────────────────────────────
    AppLanguage.en: {
      // General
      'app_name': 'ForkAI',
      'loading': 'Loading...',
      'error': 'Error',
      'retry': 'Retry',
      'cancel': 'Cancel',
      'save': 'Save',
      'delete': 'Delete',
      'confirm': 'Confirm',
      'close': 'Close',
      'back': 'Back',
      'next': 'Next',
      'done': 'Done',
      'skip': 'Skip',
      'yes': 'Yes',
      'no': 'No',
      'search': 'Search',
      'filter': 'Filter',
      'all': 'All',

      // Navigation
      'nav_recipes': 'Recipes',
      'nav_ai': 'AI',
      'nav_shopping': 'Shopping',
      'nav_profile': 'Profile',

      // Recipes
      'recipes_title': '👨‍🍳 My Recipes',
      'recipes_count': 'recipes available',
      'recipes_search_hint': 'Search a recipe...',
      'recipes_empty': 'No recipe found',
      'recipes_ingredients': 'Ingredients',
      'recipes_steps': 'Instructions',
      'recipes_duration': 'min',
      'recipes_servings': 'people',
      'recipes_save': 'Save recipe',
      'recipes_saved': '✅ Recipe saved!',
      'recipes_delete_confirm': 'Delete this recipe?',
      'recipes_add_shopping': 'Add to shopping list',

      // AI / Assistant
      'ai_title': 'AI Assistant',
      'ai_generate': 'Generate a recipe',
      'ai_anti_waste': 'Anti-waste',
      'ai_meal_plan': 'Meal plan',
      'ai_shopping': 'Shopping list',
      'ai_analyze': 'Analyze',
      'ai_nutrition': 'Nutrition',
      'ai_creative': 'Creative',
      'ai_chat': 'Assistant',
      'ai_photo': 'Photo',
      'ai_substitute': 'Substitute',
      'ai_tools': 'Tools',
      'ai_thinking': 'Thinking...',
      'ai_send': 'Send',
      'ai_placeholder': 'Ask your question...',

      // Photo recipe
      'photo_title': 'Photo → Recipe',
      'photo_pick': 'Click to select a photo',
      'photo_change': 'Change',
      'photo_analyze': 'Analyze & Cook',
      'photo_analyzing': 'Analyzing...',
      'photo_servings': 'Servings',
      'photo_detected': 'Detected ingredients',
      'photo_recipes_found': 'recipes generated',
      'photo_error_no_food': 'No food ingredients detected.',

      // Favorites
      'favorites_title': 'Favorites',
      'favorites_add': 'Added to favorites',
      'favorites_remove': 'Removed from favorites',
      'favorites_empty': 'No favorites yet',

      // Shopping
      'shopping_title': 'Shopping list',
      'shopping_add': 'Add an item',
      'shopping_empty': 'Empty list',
      'shopping_clear': 'Clear list',

      // Profile
      'profile_title': 'Profile',
      'profile_ai_recipes': 'AI recipes generated',
      'profile_favorites': 'Favorites',
      'profile_dark_mode': 'Dark mode',
      'profile_light_mode': 'Light mode',
      'profile_language': 'Language',
      'profile_history': 'AI conversation history',
      'profile_logout': 'Log out',
      'profile_logout_confirm': 'Log out?',
      'profile_version': 'ForkAI v1.0',

      // Auth
      'auth_login': 'Sign in',
      'auth_signup': 'Create account',
      'auth_email': 'Email',
      'auth_password': 'Password',
      'auth_forgot': 'Forgot password?',
      'auth_no_account': 'No account yet?',
      'auth_already_account': 'Already have an account?',
      'auth_welcome': 'Welcome back!',
      'auth_create': 'Create your account',

      // Onboarding
      'onboarding_welcome': 'Welcome to',
      'onboarding_subtitle': 'Your personal chef powered by artificial intelligence',
      'onboarding_photo_title': 'Photograph\nyour fridge',
      'onboarding_photo_sub': 'Gemini Vision analyzes your ingredients and generates 5 personalized recipes',
      'onboarding_ai_title': 'Powered by\ncutting-edge AI',
      'onboarding_account_title': 'Ready to cook\ndifferently?',
      'onboarding_create_account': 'Create a free account',
      'onboarding_already': 'I already have an account',

      // Errors
      'error_network': 'Network error. Check your connection.',
      'error_timeout': 'Timeout. Please retry.',
      'error_unknown': 'An error occurred.',
      'offline_banner': 'Offline mode — cached data',
      'syncing_banner': 'Syncing...',

      // Search
      'search_title': 'Search',
      'search_hint': 'Title, ingredient...',
      'search_results': 'result',
      'search_results_plural': 'results',
      'search_empty': 'No recipe found',
      'search_recent': 'Recent searches',
      'search_clear': 'Clear',
      'search_placeholder': 'Search by title\nor ingredient',
    },

    // ────────────────────────────────────────
    AppLanguage.es: {
      // General
      'app_name': 'ForkAI',
      'loading': 'Cargando...',
      'error': 'Error',
      'retry': 'Reintentar',
      'cancel': 'Cancelar',
      'save': 'Guardar',
      'delete': 'Eliminar',
      'confirm': 'Confirmar',
      'close': 'Cerrar',
      'back': 'Volver',
      'next': 'Siguiente',
      'done': 'Listo',
      'skip': 'Omitir',
      'yes': 'Sí',
      'no': 'No',
      'search': 'Buscar',
      'filter': 'Filtrar',
      'all': 'Todo',

      // Navigation
      'nav_recipes': 'Recetas',
      'nav_ai': 'IA',
      'nav_shopping': 'Compras',
      'nav_profile': 'Perfil',

      // Recipes
      'recipes_title': '👨‍🍳 Mis Recetas',
      'recipes_count': 'recetas disponibles',
      'recipes_search_hint': 'Buscar una receta...',
      'recipes_empty': 'No se encontraron recetas',
      'recipes_ingredients': 'Ingredientes',
      'recipes_steps': 'Preparación',
      'recipes_duration': 'min',
      'recipes_servings': 'personas',
      'recipes_save': 'Guardar receta',
      'recipes_saved': '✅ ¡Receta guardada!',
      'recipes_delete_confirm': '¿Eliminar esta receta?',
      'recipes_add_shopping': 'Añadir a la lista de compras',

      // AI / Assistant
      'ai_title': 'Asistente IA',
      'ai_generate': 'Generar una receta',
      'ai_anti_waste': 'Anti-desperdicio',
      'ai_meal_plan': 'Plan de comidas',
      'ai_shopping': 'Lista de compras',
      'ai_analyze': 'Analizar',
      'ai_nutrition': 'Nutrición',
      'ai_creative': 'Creativo',
      'ai_chat': 'Asistente',
      'ai_photo': 'Foto',
      'ai_substitute': 'Sustitución',
      'ai_tools': 'Herramientas',
      'ai_thinking': 'Pensando...',
      'ai_send': 'Enviar',
      'ai_placeholder': 'Haz tu pregunta...',

      // Photo recipe
      'photo_title': 'Foto → Receta',
      'photo_pick': 'Haz clic para seleccionar una foto',
      'photo_change': 'Cambiar',
      'photo_analyze': 'Analizar y Cocinar',
      'photo_analyzing': 'Analizando...',
      'photo_servings': 'Personas',
      'photo_detected': 'Ingredientes detectados',
      'photo_recipes_found': 'recetas generadas',
      'photo_error_no_food': 'No se detectaron ingredientes alimentarios.',

      // Favorites
      'favorites_title': 'Favoritos',
      'favorites_add': 'Añadido a favoritos',
      'favorites_remove': 'Eliminado de favoritos',
      'favorites_empty': 'Sin favoritos por ahora',

      // Shopping
      'shopping_title': 'Lista de compras',
      'shopping_add': 'Añadir un artículo',
      'shopping_empty': 'Lista vacía',
      'shopping_clear': 'Vaciar lista',

      // Profile
      'profile_title': 'Perfil',
      'profile_ai_recipes': 'recetas IA generadas',
      'profile_favorites': 'Favoritos',
      'profile_dark_mode': 'Modo oscuro',
      'profile_light_mode': 'Modo claro',
      'profile_language': 'Idioma',
      'profile_history': 'Historial de conversaciones IA',
      'profile_logout': 'Cerrar sesión',
      'profile_logout_confirm': '¿Cerrar sesión?',
      'profile_version': 'ForkAI v1.0',

      // Auth
      'auth_login': 'Iniciar sesión',
      'auth_signup': 'Crear cuenta',
      'auth_email': 'Correo electrónico',
      'auth_password': 'Contraseña',
      'auth_forgot': '¿Olvidaste tu contraseña?',
      'auth_no_account': '¿Aún no tienes cuenta?',
      'auth_already_account': '¿Ya tienes cuenta?',
      'auth_welcome': '¡Bienvenido de nuevo!',
      'auth_create': 'Crea tu cuenta',

      // Onboarding
      'onboarding_welcome': 'Bienvenido a',
      'onboarding_subtitle': 'Tu chef personal impulsado por inteligencia artificial',
      'onboarding_photo_title': 'Fotografía\ntu nevera',
      'onboarding_photo_sub': 'Gemini Vision analiza tus ingredientes y genera 5 recetas personalizadas',
      'onboarding_ai_title': 'Impulsado por\nIA de vanguardia',
      'onboarding_account_title': '¿Listo para cocinar\nde otra manera?',
      'onboarding_create_account': 'Crear una cuenta gratuita',
      'onboarding_already': 'Ya tengo una cuenta',

      // Errors
      'error_network': 'Error de red. Verifica tu conexión.',
      'error_timeout': 'Tiempo de espera agotado. Inténtalo de nuevo.',
      'error_unknown': 'Se produjo un error.',
      'offline_banner': 'Modo sin conexión — datos en caché',
      'syncing_banner': 'Sincronizando...',

      // Search
      'search_title': 'Búsqueda',
      'search_hint': 'Título, ingrediente...',
      'search_results': 'resultado',
      'search_results_plural': 'resultados',
      'search_empty': 'No se encontraron recetas',
      'search_recent': 'Búsquedas recientes',
      'search_clear': 'Borrar',
      'search_placeholder': 'Busca por título\no ingrediente',
    },
  };
}

// ── Extension pratique ────────────────────
// Utilisation : context.tr('key') ou tr('key')
extension TrString on String {
  String get tr => AppLocalizations.t(this);
}


// ── Widget réactif aux changements de langue ──
// Utilisation : TrText('ma_cle', style: TextStyle(...))
// Se rebuild automatiquement quand la langue change
class TrText extends StatelessWidget {
  final String key_;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const TrText(
    this.key_, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: AppLocalizations.languageNotifier,
      builder: (_, __, ___) => Text(
        AppLocalizations.t(key_),
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      ),
    );
  }
}