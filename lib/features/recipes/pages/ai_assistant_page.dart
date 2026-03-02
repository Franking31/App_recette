import 'package:flutter/material.dart';
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:js' as js;
import '../../../core/constants/app_colors.dart';
import '../../../core/services/app_localizations.dart';
import '../../../core/services/user_prefs_service.dart';
import '../data/models/recipe.dart';
import '../pages/recipe_detail_page.dart';
import '../../../core/services/gemini_service.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/auth_service.dart';
import 'conversations_history_page.dart';
import 'photo_recipe_page.dart';
import 'substitute_page.dart';
import 'meal_plan_page.dart';
import 'nutrition_page.dart';

// ─────────────────────────────────────────────
//  MODES IA
// ─────────────────────────────────────────────
enum AiMode {
  generate,
  antiWaste,
  mealPlan,
  shoppingList,
  analyzeRecipe,
  nutrition,
  creative,
  chat,
  photoRecipe,
  substitute,
  budget,
  objectif,
  vocal,
  pedagogique,
}

extension AiModeInfo on AiMode {
  String get label {
    switch (this) {
      case AiMode.generate:     return 'Générer une recette';
      case AiMode.antiWaste:    return 'Anti-gaspi';
      case AiMode.mealPlan:     return 'Plan de repas';
      case AiMode.shoppingList: return 'Liste de courses';
      case AiMode.analyzeRecipe:return 'Analyser une recette';
      case AiMode.nutrition:    return 'Nutrition & Macros';
      case AiMode.creative:     return 'Mode créatif';
      case AiMode.chat:         return 'Assistant cuisine';
      case AiMode.photoRecipe:  return 'Photo → Recette';
      case AiMode.substitute:   return 'Substitution';
      case AiMode.budget:       return 'Mode Budget';
      case AiMode.objectif:     return 'Mon Objectif';
      case AiMode.vocal:        return 'Mode Vocal';
      case AiMode.pedagogique:  return 'Chef Pédago';
    }
  }

  String get emoji {
    switch (this) {
      case AiMode.generate:     return '✨';
      case AiMode.antiWaste:    return '♻️';
      case AiMode.mealPlan:     return '📅';
      case AiMode.shoppingList: return '🛒';
      case AiMode.analyzeRecipe:return '🔍';
      case AiMode.nutrition:    return '📊';
      case AiMode.creative:     return '🎨';
      case AiMode.chat:         return '👨‍🍳';
      case AiMode.photoRecipe:  return '📸';
      case AiMode.substitute:   return '🔄';
      case AiMode.budget:       return '💰';
      case AiMode.objectif:     return '🎯';
      case AiMode.vocal:        return '🎤';
      case AiMode.pedagogique:  return '👨‍🏫';
    }
  }

  String get hint {
    switch (this) {
      case AiMode.generate:
        return 'Ex: Recette végétarienne rapide pour 4 personnes, sans gluten…';
      case AiMode.antiWaste:
        return 'Ex: J\'ai des carottes, du riz et du fromage blanc qui vont périmer…';
      case AiMode.mealPlan:
        return 'Ex: Plan pour 7 jours, 2 personnes, régime méditerranéen, budget 60€…';
      case AiMode.shoppingList:
        return 'Ex: Génère la liste de courses pour mes repas de la semaine…';
      case AiMode.analyzeRecipe:
        return 'Ex: Colle ta recette ici, je lanalyse et te propose des améliorations…';
      case AiMode.nutrition:
        return 'Ex: Calcule les calories et macros pour ma recette de lasagnes…';
      case AiMode.creative:
        return 'Ex: Je regarde Stranger Things et j\'ai envie d\'un plat américain années 80…';
      case AiMode.chat:
        return 'Ex: Mes pâtes ont trop cuit, comment rattraper ça ? Comment faire une béchamel ?';
      case AiMode.photoRecipe:
        return 'Photographiez votre frigo ou vos ingrédients...';
      case AiMode.substitute:
        return 'Ex: Je n ai pas de creme fraiche, par quoi remplacer ?';
      case AiMode.budget:
        return 'Ex: Budget 5€ pour 2 personnes, dîner complet... Qu\'est-ce que je peux faire ?';
      case AiMode.objectif:
        return 'Ex: Je veux perdre du poids, propose-moi un repas sain et rassasiant...';
      case AiMode.vocal:
        return 'Appuyez sur le micro et parlez...';
      case AiMode.pedagogique:
        return 'Ex: Apprends-moi à faire une vraie béchamel, explique chaque étape...';
    }
  }

  String get systemPrompt {
    const base = '''Tu es un chef cuisinier expert et nutritionniste passionné. 
Tu réponds toujours en français avec enthousiasme et bienveillance. 
Tes réponses sont structurées, pratiques et adaptées au niveau de l'utilisateur.
Utilise des emojis avec modération pour rendre les réponses agréables.''';

    switch (this) {
      case AiMode.generate:
        return '''$base
MODE: Génération de recette personnalisée.
Format ta réponse ainsi:
🍽️ **Titre de la recette**
📝 Description courte et appétissante
⏱️ Temps: X min | 👥 Portions: X | 💪 Difficulté: Facile/Moyen/Expert

**Ingrédients:**
• liste des ingrédients avec quantités précises

**Étapes:**
1. étape détaillée
2. ...

💡 **Astuce du chef:** conseil personnalisé''';

      case AiMode.antiWaste:
        return '''$base
MODE: Anti-gaspi - transformer les restes et ingrédients qui vont périmer.
Propose 2-3 recettes créatives avec exactement les ingrédients donnés.
Mets en avant comment éviter le gaspillage et ce qui peut se congeler.
Format: recettes avec ingrédients et étapes concises.''';

      case AiMode.mealPlan:
        return '''$base
MODE: Planificateur de repas intelligent.
Crée un planning équilibré (petit-déj, déjeuner, dîner + collations si demandé).
Tiens compte: des besoins nutritionnels, de la variété, des saisons, du budget.
Format: tableau hebdomadaire clair avec noms des plats.
Ajoute un récap nutritionnel approximatif en fin de planning.''';

      case AiMode.shoppingList:
        return '''$base
MODE: Liste de courses optimisée.
Regroupe les ingrédients par rayons (Fruits & légumes, Viandes, Produits laitiers, etc.).
Indique les quantités totales nécessaires.
Signale ce qui est généralement déjà en placard.
Estime le budget approximatif si possible.''';

      case AiMode.analyzeRecipe:
        return '''$base
MODE: Analyse et amélioration de recette.
Analyse la recette fournie selon: technique, équilibre des saveurs, nutrition, timing.
Propose: 3 améliorations concrètes, des substitutions possibles, des variantes.
Identifie les erreurs courantes à éviter.''';

      case AiMode.nutrition:
        return '''$base
MODE: Nutrition & tracking.
Calcule pour la recette: calories totales et par portion, protéines, glucides, lipides, fibres.
Évalue: l'index glycémique approximatif, les vitamines/minéraux clés, l\'équilibre nutritionnel.
Donne des conseils pour améliorer le profil nutritionnel si nécessaire.
Format: tableau clair + analyse qualitative.''';

      case AiMode.creative:
        return '''$base
MODE: Recettes créatives et fun.
Laisse libre cours à ta créativité ! Fusionne des cuisines, inspire-toi de films/séries/humeurs.
Raconte l'histoire derrière la recette pour la rendre mémorable.
Propose des présentations originales et des anecdotes culturelles.''';

      case AiMode.chat:
        return '''$base
MODE: Assistant conversationnel en cuisine.
Tu es comme un chef ami disponible à tout moment.
Aide à: rattraper des erreurs, expliquer des techniques, suggérer des substitutions.
Sois rassurant, pratique et donne des solutions immédiates.
Si une étape est en cours, guide pas à pas avec des timings précis.''';
      case AiMode.photoRecipe:
        return '''$base
MODE: Photo → Recette. L'utilisateur a pris une photo de ses ingrédients.
Tu reçois une liste d'ingrédients détectés et dois proposer des recettes créatives.
Sois enthousiaste et créatif dans tes suggestions.''';
      case AiMode.substitute:
        return '''$base
MODE: Substitution d'ingrédients.
Propose des alternatives détaillées avec ratios et impacts sur le résultat.
Format: pour chaque substitut indique le ratio, l'impact gustatif et le meilleur usage.''';

      case AiMode.budget:
        return '''$base
MODE: RECETTES BUDGET — Cuisine économique et savoureuse.
L'objectif est de créer des plats délicieux avec un budget très limité.

Règles absolues:
- Toujours indiquer le coût estimé total et par portion en €
- Prioriser: œufs, légumineuses, légumes de saison, pâtes, riz, produits basiques
- Éviter: viandes chères, produits exotiques, fromages premium
- Proposer des astuces pour réduire encore le coût (acheter en vrac, surgelés, etc.)
- Mentionner les restes possibles et comment les utiliser

Format: 
💰 **Recette + coût total/portion**
📝 Description rapide
⏱️ Temps | 👥 Portions
**Ingrédients** avec prix indicatifs
**Étapes** concises
💡 **Astuce budget** : comment économiser encore
♻️ **Que faire des restes ?**''';

      case AiMode.objectif:
        return '''$base
MODE: RECETTES OBJECTIF PERSONNEL — Cuisine adaptée à tes buts.
Avant tout, identifie l'objectif de l'utilisateur dans sa demande.

Objectifs possibles:
- 🏋️ PRISE DE MASSE: riche en protéines (30g+/portion), calories suffisantes, glucides complexes
- 🔥 PERTE DE POIDS: moins de 500 kcal/portion, très rassasiant, peu de glucides simples
- ⚡ ÉNERGIE: glucides complexes, faible IG, riche en vitamines B et fer
- 🚀 PERFORMANCE SPORTIVE: récupération musculaire, anti-inflammatoire, hydratation
- 🧘 BIEN-ÊTRE: anti-oxydants, oméga-3, probiotiques si possible

Format:
🎯 **Adapté pour : [objectif détecté]**
🍽️ **Nom de la recette**
📊 Macros: Protéines Xg | Glucides Xg | Lipides Xg | Calories Xkcal
**Ingrédients** avec quantités précises
**Étapes** de préparation
💡 **Pourquoi c'est parfait pour votre objectif ?**''';

      case AiMode.vocal:
        return '''$base
MODE: ASSISTANT VOCAL — L'utilisateur parle à voix haute.
Ses messages sont transcrits et peuvent être approximatifs.
Sois très compréhensif avec les fautes de transcription.
Réponds de façon conversationnelle, courte, comme si tu parlais.
Pose une seule question à la fois si tu as besoin de clarifications.
Adapte la longueur de tes réponses : courtes pour les questions simples, détaillées pour les recettes.''';

      case AiMode.pedagogique:
        return '''$base
MODE: CHEF PÉDAGOGIQUE — Tu enseignes vraiment la cuisine.
Pour chaque étape, explique :
1. LE POURQUOI : la raison scientifique ou culinaire de cette étape
2. LA TECHNIQUE : comment reconnaître que c'est bien fait (couleur, texture, son, odeur)
3. L'ERREUR CLASSIQUE : ce qui arrive si on rater cette étape
4. L'ASTUCE PRO : ce que font les vrais chefs

Format:
📚 **[Nom de la technique/recette]**
🎓 Niveau : Débutant/Intermédiaire/Avancé

Pour chaque étape :
→ **Étape X** : [action]
  🔬 Pourquoi : [explication scientifique simple]
  👁️ Comment savoir : [indices sensoriels]
  ⚠️ Erreur courante : [ce qui peut mal tourner]
  ✨ Astuce pro : [secret de chef]

Sois pédagogue mais accessible, jamais condescendant.''';

    }
  }

  Color get color {
    switch (this) {
      case AiMode.generate:     return const Color(0xFFE8604A);
      case AiMode.antiWaste:    return const Color(0xFF4CAF50);
      case AiMode.mealPlan:     return const Color(0xFF5B8DEF);
      case AiMode.shoppingList: return const Color(0xFFFF9800);
      case AiMode.analyzeRecipe:return const Color(0xFF9C27B0);
      case AiMode.nutrition:    return const Color(0xFF00BCD4);
      case AiMode.creative:     return const Color(0xFFE91E63);
      case AiMode.chat:         return const Color(0xFF795548);
      case AiMode.photoRecipe:  return const Color(0xFF6C63FF);
      case AiMode.substitute:   return const Color(0xFF26A69A);
      case AiMode.budget:       return const Color(0xFF66BB6A);
      case AiMode.objectif:     return const Color(0xFFFF7043);
      case AiMode.vocal:        return const Color(0xFF7C4DFF);
      case AiMode.pedagogique:  return const Color(0xFF8D6E63);
    }
  }
}

// ─────────────────────────────────────────────
//  MODÈLE MESSAGE
// ─────────────────────────────────────────────
class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.content,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

// ─────────────────────────────────────────────
//  PAGE PRINCIPALE IA
// ─────────────────────────────────────────────
class AiAssistantPage extends StatefulWidget {
  final Recipe? recipeToAnalyze;
  final String? conversationId;
  final String? initialMode;

  const AiAssistantPage({
    super.key,
    this.recipeToAnalyze,
    this.conversationId,
    this.initialMode,
  });

  @override
  State<AiAssistantPage> createState() => _AiAssistantPageState();
}

class _AiAssistantPageState extends State<AiAssistantPage>
    with TickerProviderStateMixin {
  AiMode _selectedMode = AiMode.chat;
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _loadingHistory = false;

  // Persistance conversation
  String? _currentConversationId;
  bool _saving = false;

  // Filtres personnalisation
  final List<String> _selectedDiets = [];
  int _servings = 2;
  String _difficulty = 'Tous';

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.recipeToAnalyze != null) {
      _selectedMode = AiMode.analyzeRecipe;
      _inputController.text =
          'Analyse cette recette:\n\n\${widget.recipeToAnalyze!.title}\n\nIngrédients: \${widget.recipeToAnalyze!.ingredients.join(", ")}\n\nÉtapes: \${widget.recipeToAnalyze!.steps.join(" | ")}';
    }

    // Charger mode initial si passé depuis l'historique
    if (widget.initialMode != null) {
      try {
        _selectedMode = AiMode.values.firstWhere(
          (m) => m.name == widget.initialMode,
          orElse: () => AiMode.chat,
        );
      } catch (_) {}
    }

    // Charger la conversation existante depuis l'historique
    if (widget.conversationId != null) {
      _currentConversationId = widget.conversationId;
      _loadConversation(widget.conversationId!);
    } else {
      _addWelcomeMessage();
    }
  }

  // ── Charger une conversation depuis Supabase ──
  Future<void> _loadConversation(String id) async {
    setState(() => _loadingHistory = true);
    try {
      final data = await ApiService.get('/conversations/$id');
      final conv = data['conversation'];
      final msgs = (conv['messages'] as List? ?? []);
      // Restaurer le mode
      if (conv['mode'] != null) {
        try {
          _selectedMode = AiMode.values.firstWhere(
            (m) => m.name == conv['mode'], orElse: () => AiMode.chat);
        } catch (_) {}
      }
      if (mounted) {
        setState(() {
          _messages.clear();
          for (final m in msgs) {
            _messages.add(ChatMessage(
              content: m['content'] ?? '',
              isUser: m['isUser'] == true,
            ));
          }
          _loadingHistory = false;
        });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingHistory = false);
        _addWelcomeMessage();
      }
    }
  }

  // ── Sauvegarder la conversation ───────────────
  Future<void> _saveConversation() async {
    if (!AuthService.isLoggedIn || _saving) return;
    _saving = true;
    try {
      final msgs = _messages
          .where((m) => m.content.isNotEmpty)
          .map((m) => {'content': m.content, 'isUser': m.isUser})
          .toList();
      final title = _messages.isNotEmpty
          ? _messages.first.content.split('\n').first.substring(
              0, _messages.first.content.split('\n').first.length.clamp(0, 50))
          : 'Conversation';

      final body = {
        'mode': _selectedMode.name,
        'title': title,
        'messages': msgs,
        if (_currentConversationId != null) 'id': _currentConversationId,
      };
      final data = await ApiService.post('/conversations', body);
      _currentConversationId = data['conversation']['id'];
    } catch (_) {}
    _saving = false;
  }

  void _addWelcomeMessage() {
    _messages.add(ChatMessage(
      content:
          '👋 Bonjour ! Je suis votre assistant cuisine IA.\n\nChoisissez un mode ci-dessus et posez-moi vos questions. Je peux :\n\n✨ Créer des recettes sur mesure\n♻️ Cuisiner avec vos restes\n📅 Planifier vos repas\n🛒 Générer vos listes de courses\n📊 Analyser la nutrition\n🎨 Inventer des plats créatifs\n\nAllez-y, je suis à votre service !',
      isUser: false,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(ChatMessage(content: text, isUser: true));
      _isLoading = true;
      _inputController.clear();
    });

    _scrollToBottom();

    try {
      final response = await _callClaudeApi(text);
      setState(() {
        _messages.add(ChatMessage(content: response, isUser: false));
        _isLoading = false;
      });
      // Sauvegarder automatiquement la conversation
      _saveConversation();
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          content:
              '❌ Erreur de connexion. Vérifiez votre clé API et votre connexion internet.\n\nDétail: $e',
          isUser: false,
        ));
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  Future<String> _callClaudeApi(String userMessage) async {
    // Historique (max 10 messages)
    final recent = _messages
        .skip(_messages.length > 10 ? _messages.length - 10 : 0)
        .toList();

    // Enrichir avec le contexte de personnalisation
    String enrichedMessage = userMessage;
    if (_selectedDiets.isNotEmpty || _servings != 2) {
      enrichedMessage +=
          '\n\n[Contexte: $_servings personnes, régimes: ${_selectedDiets.isEmpty ? "aucun" : _selectedDiets.join(", ")}, difficulté: $_difficulty]';
    }

    final messages = [
      ...recent.map((m) => {'content': m.content, 'isUser': m.isUser}),
      {'content': enrichedMessage, 'isUser': true},
    ];

    return await GeminiService.chat(
      systemPrompt: _selectedMode.systemPrompt,
      messages: messages,
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendQuickPrompt(String prompt) {
    _inputController.text = prompt;
    _sendMessage();
  }

  // ══════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark),
            _buildModeSelector(isDark),
            Expanded(
              child: isWide
                  ? _buildWideLayout(isDark)
                  : _buildMobileLayout(isDark),
            ),
            _buildInputBar(isDark),
          ],
        ),
      ),
    );
  }

  // ── Layout mobile ─────────────────────────
  Widget _buildMobileLayout(bool isDark) => Column(
    children: [
      _buildSurpriseButton(isDark),
      _buildPersonalizationBar(isDark),
      Expanded(child: _buildChatArea(isDark)),
      _buildQuickPrompts(isDark),
    ],
  );

  // ── Layout PC : sidebar modes + chat ──────
  Widget _buildWideLayout(bool isDark) {
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final textDark = isDark ? AppColors.darkTextDark : AppColors.textDark;
    final textLight = isDark ? AppColors.darkTextLight : AppColors.textLight;

    return Row(
      children: [
        // Sidebar modes
        Container(
          width: 180,
          decoration: BoxDecoration(
            color: surface,
            boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 8)],
          ),
          child: Column(
            children: [
              // Surprise button compact
              Padding(
                padding: const EdgeInsets.all(12),
                child: GestureDetector(
                  onTap: _loadingSurprise ? null : _getSurprise,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B35), Color(0xFFFF9A5C)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF6B35).withValues(alpha: 0.35),
                          blurRadius: 8, offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(children: [
                      _loadingSurprise
                          ? const SizedBox(width: 16, height: 16,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('🎲', style: TextStyle(fontSize: 18)),
                      const SizedBox(height: 3),
                      const Text('Surprends-moi',
                          style: TextStyle(color: Colors.white,
                              fontSize: 10, fontWeight: FontWeight.w800)),
                    ]),
                  ),
                ),
              ),
              const Divider(height: 1),
              // Liste modes
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: AiMode.values.map((mode) {
                    final sel = _selectedMode == mode;
                    return GestureDetector(
                      onTap: () => _handleModeTab(mode),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: sel ? mode.color.withValues(alpha: 0.12) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: sel ? mode.color.withValues(alpha: 0.4) : Colors.transparent,
                          ),
                        ),
                        child: Row(children: [
                          Text(mode.emoji, style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(mode.label,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: sel ? FontWeight.w800 : FontWeight.w600,
                                  color: sel ? mode.color : textLight,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                          ),
                        ]),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        // Zone chat
        Expanded(
          child: Column(
            children: [
              _buildPersonalizationBar(isDark),
              Expanded(child: _buildChatArea(isDark)),
              _buildQuickPrompts(isDark),
            ],
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════
  //  HEADER GRADIENT
  // ══════════════════════════════════════════
  Widget _buildHeader(bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_selectedMode.color, _selectedMode.color.withValues(alpha: 0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _selectedMode.color.withValues(alpha: 0.3),
            blurRadius: 12, offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
            ),
          ),
          const SizedBox(width: 12),
          ScaleTransition(
            scale: _pulseAnim,
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Text(_selectedMode.emoji,
                  style: const TextStyle(fontSize: 20))),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ForkAI Assistant',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900,
                        color: Colors.white)),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(_selectedMode.label,
                      key: ValueKey(_selectedMode),
                      style: TextStyle(fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          if (AuthService.isLoggedIn)
            _HeaderBtn(icon: Icons.history_rounded, onTap: () =>
                Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const ConversationsHistoryPage()))),
          const SizedBox(width: 6),
          _HeaderBtn(icon: Icons.add_rounded, onTap: () => setState(() {
            _messages.clear();
            _currentConversationId = null;
            _addWelcomeMessage();
          })),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  //  SÉLECTEUR MODES — Pills scrollables
  // ══════════════════════════════════════════
  Widget _buildModeSelector(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 800) return const SizedBox.shrink();
        return _buildMobileModeSelector(isDark);
      },
    );
  }

  Widget _buildMobileModeSelector(bool isDark) {
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    return Container(
      color: surface,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        children: [
          // Ligne 1 : Photo + Substitution + Outils
          Row(
            children: [
              _modeChip(AiMode.photoRecipe, isDark),
              const SizedBox(width: 8),
              _modeChip(AiMode.substitute, isDark),
              const SizedBox(width: 8),
              // Bouton Outils
              GestureDetector(
                onTap: () => _showToolsBottomSheet(isDark),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: _isToolMode()
                        ? _selectedMode.color.withValues(alpha: 0.12)
                        : (isDark ? AppColors.darkBackground : AppColors.background),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _isToolMode()
                          ? _selectedMode.color.withValues(alpha: 0.4)
                          : AppColors.textLight.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.grid_view_rounded, size: 14,
                        color: _isToolMode() ? _selectedMode.color : AppColors.textLight),
                    const SizedBox(width: 5),
                    Text(AppLocalizations.t('ai_tools'),
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                            color: _isToolMode() ? _selectedMode.color : AppColors.textLight)),
                    const SizedBox(width: 2),
                    Icon(Icons.keyboard_arrow_down_rounded, size: 14,
                        color: _isToolMode() ? _selectedMode.color : AppColors.textLight),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _isToolMode() => ![AiMode.photoRecipe, AiMode.substitute].contains(_selectedMode);

  Widget _modeChip(AiMode mode, bool isDark) {
    final sel = _selectedMode == mode;
    return GestureDetector(
      onTap: () => _handleModeTab(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: sel ? mode.color.withValues(alpha: 0.12)
              : (isDark ? AppColors.darkBackground : AppColors.background),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: sel ? mode.color.withValues(alpha: 0.4)
                : AppColors.textLight.withValues(alpha: 0.25),
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(mode.emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 5),
          Text(mode.label.split(' ').first,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                  color: sel ? mode.color : AppColors.textLight)),
        ]),
      ),
    );
  }

  void _handleModeTab(AiMode mode) {
    if (mode == AiMode.photoRecipe) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const PhotoRecipePage()));
      return;
    }
    if (mode == AiMode.substitute) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const SubstitutePage()));
      return;
    }
    if (mode == AiMode.mealPlan) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const MealPlanPage()));
      return;
    }
    if (mode == AiMode.nutrition) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const NutritionPage()));
      return;
    }
    if (mode == AiMode.vocal) {
      setState(() { _selectedMode = mode; });
      _showVocalMode();
      return;
    }
    setState(() {
      _selectedMode = mode;
      _addWelcomeMessage();
    });
  }

  void _showToolsBottomSheet(bool isDark) {
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final textDark = isDark ? AppColors.darkTextDark : AppColors.textDark;
    final otherModes = AiMode.values
        .where((m) => m != AiMode.photoRecipe && m != AiMode.substitute)
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: AppColors.textLight.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            )),
            const SizedBox(height: 16),
            Text('Outils IA', style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w900, color: textDark)),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 8,
              childAspectRatio: 0.9,
              children: otherModes.map((mode) {
                final sel = _selectedMode == mode;
                return GestureDetector(
                  onTap: () { Navigator.pop(context); _handleModeTab(mode); },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      color: sel ? mode.color.withValues(alpha: 0.12) : surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: sel ? mode.color : AppColors.cardShadow,
                        width: sel ? 1.5 : 1,
                      ),
                      boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 4)],
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(mode.emoji, style: const TextStyle(fontSize: 22)),
                      const SizedBox(height: 4),
                      Text(mode.label,
                          style: TextStyle(fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: sel ? mode.color : textDark),
                          textAlign: TextAlign.center,
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                    ]),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  //  BOUTON SURPRISE — compact et élégant
  // ══════════════════════════════════════════
  bool _loadingSurprise = false;
  bool _isListening = false;
  String _vocalTranscript = '';

  Widget _buildSurpriseButton(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: GestureDetector(
        onTap: _loadingSurprise ? null : _getSurprise,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 20),
          decoration: BoxDecoration(
            gradient: _loadingSurprise
                ? null
                : const LinearGradient(
                    colors: [Color(0xFFFF6B35), Color(0xFFFF9A5C)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
            color: _loadingSurprise ? AppColors.textLight : null,
            borderRadius: BorderRadius.circular(16),
            boxShadow: _loadingSurprise ? [] : [
              BoxShadow(
                color: const Color(0xFFFF6B35).withValues(alpha: 0.35),
                blurRadius: 10, offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_loadingSurprise)
                const SizedBox(width: 14, height: 14,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              else
                const Text('🎲', style: TextStyle(fontSize: 15)),
              const SizedBox(width: 8),
              Text(
                _loadingSurprise ? 'Génération...' : '✨ Surprends-moi !',
                style: const TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _getSurprise() async {
    setState(() => _loadingSurprise = true);
    try {
      final data = await UserPrefsService.getSurpriseRecipe();
      final recipe = Recipe.fromJson({
        'id': data['id'] ?? 'surprise',
        'title': data['title'] ?? 'Recette surprise',
        'category': data['category'],
        'imageUrl': data['imageUrl'],
        'durationMinutes': data['durationMinutes'] ?? 30,
        'servings': data['servings'] ?? 2,
        'description': data['description'] ?? '',
        'ingredients': List<String>.from(data['ingredients'] ?? []),
        'steps': List<String>.from(data['steps'] ?? []),
      });
      final surpriseFact = data['surpriseFact'] as String?;
      if (mounted) {
        if (surpriseFact != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('💡 $surpriseFact'),
            duration: const Duration(seconds: 4),
            backgroundColor: const Color(0xFFFF6B35),
          ));
        }
        Navigator.push(context, MaterialPageRoute(
            builder: (_) => RecipeDetailPage(recipe: recipe)));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')));
    } finally {
      if (mounted) setState(() => _loadingSurprise = false);
    }
  }

  // ══════════════════════════════════════════
  //  MODE VOCAL
  // ══════════════════════════════════════════
  void _showVocalMode() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _VocalSheet(
        onText: (text) {
          _inputController.text = text;
          _sendMessage();
        },
      ),
    );
  }

  // ══════════════════════════════════════════
  //  BARRE PERSONNALISATION
  // ══════════════════════════════════════════
  Widget _buildPersonalizationBar(bool isDark) {
    if (_selectedMode != AiMode.generate && _selectedMode != AiMode.mealPlan) {
      return const SizedBox.shrink();
    }
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final textLight = isDark ? AppColors.darkTextLight : AppColors.textLight;
    final diets = ['🥗 Végé', '🌱 Vegan', '🚫🌾 Sans gluten', '🥛 Sans lactose', '⚡ Keto'];

    return Container(
      height: 40,
      padding: const EdgeInsets.only(left: 16),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: surface, borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 4)],
          ),
          child: Row(children: [
            GestureDetector(
              onTap: () => setState(() => _servings = (_servings - 1).clamp(1, 20)),
              child: Icon(Icons.remove, size: 14, color: _selectedMode.color),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('$_servings 👥', style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700)),
            ),
            GestureDetector(
              onTap: () => setState(() => _servings = (_servings + 1).clamp(1, 20)),
              child: Icon(Icons.add, size: 14, color: _selectedMode.color),
            ),
          ]),
        ),
        const SizedBox(width: 8),
        Expanded(child: ListView.separated(
          scrollDirection: Axis.horizontal,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemCount: diets.length,
          itemBuilder: (_, i) {
            final sel = _selectedDiets.contains(diets[i]);
            return GestureDetector(
              onTap: () => setState(() =>
                  sel ? _selectedDiets.remove(diets[i]) : _selectedDiets.add(diets[i])),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: sel ? _selectedMode.color.withValues(alpha: 0.12) : surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: sel ? _selectedMode.color.withValues(alpha: 0.4) : Colors.transparent,
                  ),
                ),
                child: Text(diets[i], style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600,
                    color: sel ? _selectedMode.color : textLight)),
              ),
            );
          },
        )),
      ]),
    );
  }

  // ══════════════════════════════════════════
  //  ZONE CHAT
  // ══════════════════════════════════════════
  Widget _buildChatArea(bool isDark) {
    if (_loadingHistory) return const Center(
        child: CircularProgressIndicator(color: AppColors.primary));
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      itemCount: _messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, i) {
        if (i == _messages.length) return _buildTypingIndicator();
        return _buildMessageBubble(_messages[i], isDark);
      },
    );
  }

  // ══════════════════════════════════════════
  //  BULLES MESSAGES — design amélioré
  // ══════════════════════════════════════════
  Widget _buildMessageBubble(ChatMessage msg, bool isDark) {
    final isUser = msg.isUser;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final textDark = isDark ? AppColors.darkTextDark : AppColors.textDark;

    return Padding(
      padding: EdgeInsets.only(
        bottom: 16,
        left: isUser ? 60 : 0,
        right: isUser ? 0 : 60,
      ),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar IA
          if (!isUser) ...[
            Container(
              width: 34, height: 34,
              margin: const EdgeInsets.only(right: 8, bottom: 2),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_selectedMode.color, _selectedMode.color.withValues(alpha: 0.6)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: _selectedMode.color.withValues(alpha: 0.3),
                      blurRadius: 6, offset: const Offset(0, 2)),
                ],
              ),
              child: Center(child: Text(_selectedMode.emoji,
                  style: const TextStyle(fontSize: 16))),
            ),
          ],
          // Bulle
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isUser
                    ? LinearGradient(
                        colors: [_selectedMode.color, _selectedMode.color.withValues(alpha: 0.8)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      )
                    : null,
                color: isUser ? null : surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isUser
                        ? _selectedMode.color.withValues(alpha: 0.25)
                        : AppColors.cardShadow,
                    blurRadius: 10, offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    msg.content,
                    style: TextStyle(
                      fontSize: 14,
                      color: isUser ? Colors.white : textDark,
                      height: 1.6,
                    ),
                  ),
                  // Timestamp
                  const SizedBox(height: 4),
                  Text(
                    '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 10,
                      color: isUser
                          ? Colors.white.withValues(alpha: 0.6)
                          : AppColors.textLight.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Avatar user
          if (isUser) ...[
            Container(
              width: 34, height: 34,
              margin: const EdgeInsets.only(left: 8, bottom: 2),
              decoration: BoxDecoration(
                color: _selectedMode.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(child: Text('🧑', style: TextStyle(fontSize: 16))),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, right: 60),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 34, height: 34,
            margin: const EdgeInsets.only(right: 8, bottom: 2),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_selectedMode.color, _selectedMode.color.withValues(alpha: 0.6)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text(_selectedMode.emoji,
                style: const TextStyle(fontSize: 16))),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkSurface : AppColors.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18), topRight: Radius.circular(18),
                bottomRight: Radius.circular(18), bottomLeft: Radius.circular(4),
              ),
              boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 8,
                  offset: const Offset(0, 3))],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) => AnimatedBuilder(
                animation: _pulseController,
                builder: (_, __) {
                  final t = (_pulseController.value + i * 0.3) % 1.0;
                  final scale = 0.6 + 0.4 * (t < 0.5 ? t * 2 : (1 - t) * 2);
                  return Container(
                    margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                    width: 8 * scale, height: 8 * scale,
                    decoration: BoxDecoration(
                      color: _selectedMode.color.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                    ),
                  );
                },
              )),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  //  SUGGESTIONS RAPIDES — redesign
  // ══════════════════════════════════════════
  Widget _buildQuickPrompts(bool isDark) {
    final prompts = _getQuickPrompts();
    if (prompts.isEmpty) return const SizedBox.shrink();
    return Container(
      height: 40,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: prompts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => GestureDetector(
          onTap: () => _sendQuickPrompt(prompts[i]),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _selectedMode.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _selectedMode.color.withValues(alpha: 0.2)),
            ),
            child: Text(prompts[i], style: TextStyle(
                fontSize: 12, color: _selectedMode.color, fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }

  List<String> _getQuickPrompts() {
    switch (_selectedMode) {
      case AiMode.generate:
        return ['🍕 Italienne rapide', '🥗 Salade complète', '🍜 Plat asiatique', '🍰 Dessert facile'];
      case AiMode.antiWaste:
        return ['🥕 Carottes + riz', '🍞 Pain rassis', '🍌 Bananes mûres', '🧀 Restes fromage'];
      case AiMode.mealPlan:
        return ['📅 Semaine végé', '💪 Menu sportif', '👨‍👩‍👧 Famille 4p', '💶 Budget 50€'];
      case AiMode.nutrition:
        return ['🍝 Carbonara 2p', '🥗 Salade niçoise', '🍗 Poulet rôti', '🍰 Tarte pommes'];
      case AiMode.creative:
        return ['🎬 Inspiration film', '🌍 Fusion monde', '🌈 Coloré', '🎃 Thème fête'];
      case AiMode.chat:
        return ['🆘 Sauce trop salée', '⏱️ Pâtes trop cuites', '🔥 Faire un roux', '🥚 Tempérer chocolat'];
      case AiMode.budget:
        return ['🥚 Dîner pour 3€', '🫘 Recette légumineuses', '🥕 Légumes du marché', '🍚 Riz complet'];
      case AiMode.objectif:
        return ['🏋️ Prise de masse', '🔥 Perte de poids', '⚡ Boost énergie', '🧘 Bien-être'];
      case AiMode.vocal:
        return [];
      case AiMode.pedagogique:
        return ['🥚 Maîtriser les œufs', '🔪 Technique de coupe', '🍳 Les cuissons', '🫕 Faire un fond'];
      default: return [];
    }
  }

  // ══════════════════════════════════════════
  //  BARRE SAISIE — redesign
  // ══════════════════════════════════════════
  // ── Barre de saisie avec micro intégré (pattern WhatsApp) ──
  Widget _buildInputBar(bool isDark) {
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final bg = isDark ? AppColors.darkBackground : AppColors.background;
    final textDark = isDark ? AppColors.darkTextDark : AppColors.textDark;
    final hasText = _inputController.text.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: surface,
        boxShadow: [BoxShadow(color: AppColors.cardShadow,
            blurRadius: 12, offset: const Offset(0, -4))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // ── Zone de texte avec micro intégré dedans ──
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _isListening
                      ? Colors.redAccent.withValues(alpha: 0.5)
                      : _selectedMode.color.withValues(alpha: 0.2),
                  width: _isListening ? 1.5 : 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      maxLines: 4, minLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                      style: TextStyle(color: textDark, fontSize: 14),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: _isListening
                            ? 'Parlez maintenant...'
                            : _selectedMode.hint,
                        hintStyle: TextStyle(
                          color: _isListening
                              ? Colors.redAccent.withValues(alpha: 0.7)
                              : AppColors.textLight,
                          fontSize: 13,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  // ── Micro intégré à droite du champ ──
                  Padding(
                    padding: const EdgeInsets.only(right: 6, bottom: 6),
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (_, __) {
                        final scale = _isListening
                            ? 1.0 + 0.12 * _pulseController.value : 1.0;
                        return GestureDetector(
                          onTap: _toggleInlineMic,
                          child: Transform.scale(
                            scale: scale,
                            child: Container(
                              width: 34, height: 34,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isListening
                                    ? Colors.redAccent
                                    : _selectedMode.color.withValues(alpha: 0.12),
                                boxShadow: _isListening ? [
                                  BoxShadow(
                                    color: Colors.redAccent.withValues(alpha: 0.4),
                                    blurRadius: 10, spreadRadius: 2,
                                  ),
                                ] : [],
                              ),
                              child: Icon(
                                _isListening
                                    ? Icons.stop_rounded
                                    : Icons.mic_rounded,
                                size: 18,
                                color: _isListening
                                    ? Colors.white
                                    : _selectedMode.color,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // ── Bouton envoyer ──
          GestureDetector(
            onTap: hasText && !_isLoading ? _sendMessage : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48, height: 48,
              decoration: BoxDecoration(
                gradient: hasText && !_isLoading
                    ? LinearGradient(
                        colors: [_selectedMode.color,
                            _selectedMode.color.withValues(alpha: 0.75)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      )
                    : null,
                color: hasText && !_isLoading
                    ? null : AppColors.textLight.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                boxShadow: hasText && !_isLoading ? [
                  BoxShadow(color: _selectedMode.color.withValues(alpha: 0.4),
                      blurRadius: 10, offset: const Offset(0, 4)),
                ] : [],
              ),
              child: _isLoading
                  ? const Center(child: SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2)))
                  : Icon(Icons.send_rounded,
                      color: hasText ? Colors.white : AppColors.textLight,
                      size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // ── Toggle micro inline ──────────────────────
  void _toggleInlineMic() {
    if (_isListening) {
      setState(() { _isListening = false; });
      _pulseController.stop();
      return;
    }
    setState(() { _isListening = true; _inputController.clear(); });
    _pulseController.repeat(reverse: true);
    _startInlineSpeechRecognition();
  }

  void _startInlineSpeechRecognition() {
    // ignore: avoid_web_libraries_in_flutter
    try {
      js.context.callMethod('eval', ['''
          (function() {
            window._vocalTranscript = "";
            window._vocalDone = false;
            var SR = window.SpeechRecognition || window.webkitSpeechRecognition;
            if (!SR) { window._vocalDone = true; window._vocalError = "Non supporté"; return; }
            var r = new SR();
            r.lang = "fr-FR";
            r.continuous = true;
            r.interimResults = true;
            r.onresult = function(e) {
              var t = "";
              for (var i = 0; i < e.results.length; i++) {
                t += e.results[i][0].transcript;
              }
              window._vocalTranscript = t;
            };
            r.onend = function() { window._vocalDone = true; };
            r.onerror = function(e) { window._vocalDone = true; };
            r.start();
            window._recognition = r;
          })();
        '''
        ]);

        // Polling toutes les 300ms pour mettre à jour le champ
        void poll() {
          if (!mounted) return;
          Future.delayed(const Duration(milliseconds: 300), () {
            if (!mounted) return;
            try {
              final text = js.context['_vocalTranscript'] as String? ?? '';
              final done = js.context['_vocalDone'] == true;
              if (text.isNotEmpty) {
                _inputController.text = text;
                _inputController.selection = TextSelection.fromPosition(
                  TextPosition(offset: text.length));
              }
              if (done) {
                if (mounted) setState(() => _isListening = false);
                _pulseController.stop();
              } else if (_isListening) {
                poll();
              }
            } catch (_) {}
          });
        }
        poll();
    } catch (_) {
      if (mounted) setState(() {
        _isListening = false;
        _inputController.text = 'Mode vocal non disponible';
      });
      _pulseController.stop();
    }
  }
}

// ══════════════════════════════════════════
//  MODE VOCAL — bottom sheet
// ══════════════════════════════════════════
class _VocalSheet extends StatefulWidget {
  final ValueChanged<String> onText;
  const _VocalSheet({required this.onText});

  @override
  State<_VocalSheet> createState() => _VocalSheetState();
}

class _VocalSheetState extends State<_VocalSheet>
    with SingleTickerProviderStateMixin {
  bool _listening = false;
  String _transcript = 'Appuyez sur le micro et parlez...';
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() { _pulseCtrl.dispose(); super.dispose(); }

  void _toggleListen() {
    setState(() => _listening = !_listening);
    if (_listening) {
      _pulseCtrl.repeat(reverse: true);
      // Web Speech API via JS
      _startSpeechRecognition();
    } else {
      _pulseCtrl.stop();
      _pulseCtrl.reset();
    }
  }

  void _startSpeechRecognition() {
    // Utilise Web Speech API (JavaScript)
    try {
      // ignore: avoid_web_libraries_in_flutter
      {
        js.context.callMethod('eval', ['''
          (function() {
            if (!window.SpeechRecognition && !window.webkitSpeechRecognition) {
              window._vocalError = "Reconnaissance vocale non supportée";
              return;
            }
            var SR = window.SpeechRecognition || window.webkitSpeechRecognition;
            var recognition = new SR();
            recognition.lang = "fr-FR";
            recognition.continuous = false;
            recognition.interimResults = true;
            recognition.onresult = function(event) {
              var t = event.results[event.results.length-1][0].transcript;
              window._vocalTranscript = t;
            };
            recognition.onend = function() {
              window._vocalDone = true;
            };
            recognition.start();
            window._recognition = recognition;
          })();
        '''
        ]);

        // Poll for result
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            final result = js.context['_vocalTranscript'] as String? ?? '';
            if (result.isNotEmpty) {
              setState(() { _transcript = result; _listening = false; });
              _pulseCtrl.stop();
            }
          }
        });
      }
    } catch (_) {
      setState(() {
        _transcript = 'Mode vocal non disponible sur cette plateforme';
        _listening = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle
        Container(width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            )),
        const SizedBox(height: 24),

        const Text('Mode Vocal 🎤', style: TextStyle(
            fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
        const SizedBox(height: 8),
        Text(_listening ? 'À l\'écoute...' : 'Parlez à ForkAI',
            style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.6))),
        const SizedBox(height: 28),

        // Bouton micro animé
        GestureDetector(
          onTap: _toggleListen,
          child: AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) {
              final scale = _listening ? 1.0 + 0.1 * _pulseCtrl.value : 1.0;
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 90, height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: _listening
                          ? [const Color(0xFFFF4444), const Color(0xFFFF7777)]
                          : [const Color(0xFF7C4DFF), const Color(0xFF9B74FF)],
                    ),
                    boxShadow: [BoxShadow(
                      color: (_listening
                          ? const Color(0xFFFF4444)
                          : const Color(0xFF7C4DFF)).withValues(alpha: 0.5),
                      blurRadius: _listening ? 24 : 16,
                    )],
                  ),
                  child: Icon(
                    _listening ? Icons.stop_rounded : Icons.mic_rounded,
                    color: Colors.white, size: 40,
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 24),

        // Transcription
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(_transcript,
              style: const TextStyle(fontSize: 15, color: Colors.white, height: 1.4),
              textAlign: TextAlign.center),
        ),

        const SizedBox(height: 20),

        // Boutons
        Row(children: [
          Expanded(child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(child: Text('Annuler',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
            ),
          )),
          const SizedBox(width: 12),
          Expanded(child: GestureDetector(
            onTap: _transcript.isNotEmpty && _transcript != 'Appuyez sur le micro et parlez...'
                ? () { Navigator.pop(context); widget.onText(_transcript); }
                : null,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF7C4DFF), Color(0xFF9B74FF)]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(child: Text('Envoyer 🚀',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
            ),
          )),
        ]),
        const SizedBox(height: 8),
      ]),
    );
  }
}

// ══════════════════════════════════════════
//  WIDGET HELPER — bouton header
// ══════════════════════════════════════════
class _HeaderBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    ),
  );
}