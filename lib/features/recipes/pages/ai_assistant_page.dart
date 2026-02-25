import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../core/constants/app_colors.dart';
import '../data/models/recipe.dart';

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
        return 'Ex: Colle ta recette ici, je l\'analyse et te propose des améliorations…';
      case AiMode.nutrition:
        return 'Ex: Calcule les calories et macros pour ma recette de lasagnes…';
      case AiMode.creative:
        return 'Ex: Je regarde Stranger Things et j\'ai envie d\'un plat américain années 80…';
      case AiMode.chat:
        return 'Ex: Mes pâtes ont trop cuit, comment rattraper ça ? Comment faire une béchamel ?';
    }
  }

  String get systemPrompt {
    const base = '''Tu es un chef cuisinier expert et nutritionniste passionné. 
Tu réponds toujours en français avec enthousiasme et bienveillance. 
Tes réponses sont structurées, pratiques et adaptées au niveau de l\'utilisateur.
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
Évalue: l\'index glycémique approximatif, les vitamines/minéraux clés, l\'équilibre nutritionnel.
Donne des conseils pour améliorer le profil nutritionnel si nécessaire.
Format: tableau clair + analyse qualitative.''';

      case AiMode.creative:
        return '''$base
MODE: Recettes créatives et fun.
Laisse libre cours à ta créativité ! Fusionne des cuisines, inspire-toi de films/séries/humeurs.
Raconte l\'histoire derrière la recette pour la rendre mémorable.
Propose des présentations originales et des anecdotes culturelles.''';

      case AiMode.chat:
        return '''$base
MODE: Assistant conversationnel en cuisine.
Tu es comme un chef ami disponible à tout moment.
Aide à: rattraper des erreurs, expliquer des techniques, suggérer des substitutions.
Sois rassurant, pratique et donne des solutions immédiates.
Si une étape est en cours, guide pas à pas avec des timings précis.''';
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

  const AiAssistantPage({super.key, this.recipeToAnalyze});

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
          'Analyse cette recette:\n\n${widget.recipeToAnalyze!.title}\n\nIngrédients: ${widget.recipeToAnalyze!.ingredients.join(", ")}\n\nÉtapes: ${widget.recipeToAnalyze!.steps.join(" | ")}';
    }

    _addWelcomeMessage();
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
    // Construire l'historique de conversation (max 10 derniers messages)
    final recentMessages = _messages
        .where((m) => m.isUser || _messages.indexOf(m) > 0)
        .toList();
    final history = recentMessages
        .skip(recentMessages.length > 10 ? recentMessages.length - 10 : 0)
        .map((m) => {
              'role': m.isUser ? 'user' : 'model',
              'parts': [{'text': m.content}],
            })
        .toList();

    // Ajouter le contexte de personnalisation au message
    String enrichedMessage = userMessage;
    if (_selectedDiets.isNotEmpty || _servings != 2) {
      enrichedMessage +=
          '\n\n[Contexte: ${_servings} personnes, régimes: ${_selectedDiets.isEmpty ? "aucun" : _selectedDiets.join(", ")}, difficulté souhaitée: $_difficulty]';
    }

    history.add({'role': 'user', 'parts': [{'text': enrichedMessage}]});

    final body = jsonEncode({
      'system_instruction': {
        'parts': [{'text': _selectedMode.systemPrompt}]
      },
      'contents': history,
      'generationConfig': {'maxOutputTokens': 2048},
    });

    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (apiKey.isEmpty) throw Exception('Clé API manquante dans .env');

    final response = await http.post(
      Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey',
      ),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['candidates'][0]['content']['parts'][0]['text'] as String;
    } else {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildModeSelector(),
            _buildPersonalizationBar(),
            Expanded(child: _buildChatArea()),
            _buildQuickPrompts(),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  // ── HEADER ─────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new,
                color: AppColors.textDark, size: 20),
          ),
          const SizedBox(width: 4),
          ScaleTransition(
            scale: _pulseAnim,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _selectedMode.color,
                    _selectedMode.color.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: _selectedMode.color.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Text('🤖', style: TextStyle(fontSize: 20)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Assistant IA',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  _selectedMode.label,
                  style: TextStyle(
                    fontSize: 12,
                    color: _selectedMode.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // Bouton effacer conversation
          IconButton(
            onPressed: () {
              setState(() {
                _messages.clear();
                _addWelcomeMessage();
              });
            },
            icon: const Icon(Icons.refresh_rounded,
                color: AppColors.textLight, size: 22),
            tooltip: 'Nouvelle conversation',
          ),
        ],
      ),
    );
  }

  // ── SÉLECTEUR DE MODE ──────────────────────
  Widget _buildModeSelector() {
    return SizedBox(
      height: 68,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
        scrollDirection: Axis.horizontal,
        itemCount: AiMode.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final mode = AiMode.values[i];
          final isSelected = _selectedMode == mode;
          return GestureDetector(
            onTap: () => setState(() => _selectedMode = mode),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? mode.color : AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? mode.color.withValues(alpha: 0.35)
                        : AppColors.cardShadow,
                    blurRadius: isSelected ? 12 : 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(mode.emoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(
                    mode.label.split(' ').first,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── BARRE DE PERSONNALISATION ───────────────
  Widget _buildPersonalizationBar() {
    if (_selectedMode != AiMode.generate &&
        _selectedMode != AiMode.mealPlan) {
      return const SizedBox.shrink();
    }

    final diets = ['🥗 Végé', '🌱 Vegan', '🚫🌾 Sans gluten', '🥛 Sans lactose', '⚡ Keto'];

    return Container(
      height: 40,
      padding: const EdgeInsets.only(left: 20),
      child: Row(
        children: [
          // Nb de personnes
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(color: AppColors.cardShadow, blurRadius: 4)
              ],
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () =>
                      setState(() => _servings = (_servings - 1).clamp(1, 20)),
                  child: const Icon(Icons.remove,
                      size: 14, color: AppColors.primary),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '$_servings 👥',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
                GestureDetector(
                  onTap: () =>
                      setState(() => _servings = (_servings + 1).clamp(1, 20)),
                  child: const Icon(Icons.add,
                      size: 14, color: AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Filtres régimes
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: diets.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, i) {
                final diet = diets[i];
                final isActive = _selectedDiets.contains(diet);
                return GestureDetector(
                  onTap: () => setState(() {
                    isActive
                        ? _selectedDiets.remove(diet)
                        : _selectedDiets.add(diet);
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive
                          ? _selectedMode.color.withValues(alpha: 0.15)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isActive
                            ? _selectedMode.color
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      diet,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isActive
                            ? _selectedMode.color
                            : AppColors.textDark,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── ZONE DE CHAT ────────────────────────────
  Widget _buildChatArea() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, i) {
        if (i == _messages.length) return _buildTypingIndicator();
        return _buildMessageBubble(_messages[i]);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isUser = msg.isUser;
    return Padding(
      padding: EdgeInsets.only(
        bottom: 12,
        left: isUser ? 48 : 0,
        right: isUser ? 0 : 48,
      ),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: _selectedMode.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(_selectedMode.emoji,
                    style: const TextStyle(fontSize: 16)),
              ),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? _selectedMode.color : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isUser
                        ? _selectedMode.color.withValues(alpha: 0.3)
                        : AppColors.cardShadow,
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: SelectableText(
                msg.content,
                style: TextStyle(
                  fontSize: 14,
                  color: isUser ? Colors.white : AppColors.textDark,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 48),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: _selectedMode.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child:
                  Text(_selectedMode.emoji, style: const TextStyle(fontSize: 16)),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                    color: AppColors.cardShadow, blurRadius: 8, offset: const Offset(0, 3))
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, _) {
                    final delay = i * 0.3;
                    final t = (_pulseController.value + delay) % 1.0;
                    final scale = 0.6 + 0.4 * (t < 0.5 ? t * 2 : (1 - t) * 2);
                    return Container(
                      margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                      width: 8 * scale,
                      height: 8 * scale,
                      decoration: BoxDecoration(
                        color: _selectedMode.color.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ── SUGGESTIONS RAPIDES ─────────────────────
  Widget _buildQuickPrompts() {
    final prompts = _getQuickPrompts();
    if (prompts.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 36,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: prompts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) => GestureDetector(
          onTap: () => _sendQuickPrompt(prompts[i]),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _selectedMode.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _selectedMode.color.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              prompts[i],
              style: TextStyle(
                fontSize: 12,
                color: _selectedMode.color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<String> _getQuickPrompts() {
    switch (_selectedMode) {
      case AiMode.generate:
        return [
          '🍕 Recette italienne rapide',
          '🥗 Salade repas complète',
          '🍜 Plat asiatique facile',
          '🍰 Dessert sans cuisson',
        ];
      case AiMode.antiWaste:
        return [
          '🥕 Carottes + riz',
          '🍞 Pain rassis',
          '🍌 Bananes mûres',
          '🧀 Restes de fromages',
        ];
      case AiMode.mealPlan:
        return [
          '📅 Semaine végétarienne',
          '💪 Menu sportif',
          '👨‍👩‍👧 Famille 4 pers.',
          '💶 Budget 50€/sem',
        ];
      case AiMode.nutrition:
        return [
          '🍝 Carbonara 2 pers.',
          '🥗 Salade niçoise',
          '🍗 Poulet rôti',
          '🍰 Tarte aux pommes',
        ];
      case AiMode.creative:
        return [
          '🎬 Inspiration film',
          '🌍 Fusion monde',
          '🌈 Arc-en-ciel',
          '🎃 Halloween',
        ];
      case AiMode.chat:
        return [
          '🆘 Sauce trop salée',
          '⏱️ Pâtes trop cuites',
          '🔥 Faire un roux',
          '🥚 Tempérer chocolat',
        ];
      default:
        return [];
    }
  }

  // ── BARRE DE SAISIE ─────────────────────────
  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _inputController,
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: _selectedMode.hint,
                  hintStyle: const TextStyle(
                      color: AppColors.textLight, fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _sendMessage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _selectedMode.color,
                    _selectedMode.color.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _selectedMode.color.withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _isLoading
                  ? const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  : const Icon(Icons.send_rounded,
                      color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}