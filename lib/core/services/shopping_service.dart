import 'api_service.dart';

// ═══════════════════════════════════════════
//  SHOPPING SERVICE — Listes multiples
// ═══════════════════════════════════════════

class ShoppingItem {
  final String id;
  String name;
  String quantity;
  String unit;
  String category;
  bool checked;

  ShoppingItem({
    required this.id,
    required this.name,
    this.quantity = '',
    this.unit = '',
    this.category = '🛒 Autre',
    this.checked = false,
  });

  factory ShoppingItem.fromJson(Map<String, dynamic> j) => ShoppingItem(
        id: j['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: j['name'] ?? '',
        quantity: j['quantity'] ?? '',
        unit: j['unit'] ?? '',
        category: j['category'] ?? '🛒 Autre',
        checked: j['checked'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'quantity': quantity,
        'unit': unit,
        'category': category,
        'checked': checked,
      };

  ShoppingItem copyWith({String? name, String? quantity, String? unit,
      String? category, bool? checked}) =>
      ShoppingItem(
        id: id,
        name: name ?? this.name,
        quantity: quantity ?? this.quantity,
        unit: unit ?? this.unit,
        category: category ?? this.category,
        checked: checked ?? this.checked,
      );
}

class ShoppingList {
  String? id;
  String name;
  List<ShoppingItem> items;
  DateTime? updatedAt;

  ShoppingList({this.id, this.name = 'Ma liste', List<ShoppingItem>? items, this.updatedAt})
      : items = items ?? [];

  factory ShoppingList.fromJson(Map<String, dynamic> j) => ShoppingList(
        id: j['id'],
        name: j['name'] ?? 'Ma liste',
        items: (j['items'] as List? ?? [])
            .map((i) => ShoppingItem.fromJson(Map<String, dynamic>.from(i)))
            .toList(),
        updatedAt: j['updated_at'] != null ? DateTime.tryParse(j['updated_at']) : null,
      );

  int get checkedCount => items.where((i) => i.checked).length;
  int get totalCount => items.length;
}

class ShoppingService {
  // ── Autocomplete — ingrédients courants ────
  static const List<String> allSuggestions = [
    'Ail', 'Aubergines', 'Avocats', 'Bananes', 'Basilic',
    'Beurre', 'Bœuf haché', 'Brocolis', 'Carottes', 'Céleri',
    'Champignons', 'Citrons', 'Coriandre', 'Courgettes', 'Crème fraîche',
    'Crevettes', 'Dinde', 'Épinards', 'Escalopes de poulet', 'Farine',
    'Fraises', 'Fromage râpé', 'Gnocchis', 'Gruyère', 'Guanciale',
    'Haricots verts', 'Huile d\'olive', 'Jambon', 'Lait', 'Lardons',
    'Lentilles', 'Levure chimique', 'Mozzarella', 'Moutarde', 'Œufs',
    'Oignons', 'Oranges', 'Parmesan', 'Pâtes', 'Pecorino',
    'Persil', 'Poireaux', 'Poivrons', 'Pommes', 'Pommes de terre',
    'Porc', 'Poulet entier', 'Quinoa', 'Riz', 'Romarin',
    'Salade', 'Saumon', 'Sel', 'Spaghetti', 'Sucre',
    'Thon en boîte', 'Thym', 'Tomates', 'Tomates cerises', 'Vinaigre',
    'Yaourts', 'Poivre', 'Bouillon de légumes', 'Bouillon de poulet',
  ];

  static List<String> searchSuggestions(String query) {
    if (query.trim().isEmpty) return [];
    final q = query.toLowerCase();
    return allSuggestions.where((s) => s.toLowerCase().contains(q)).take(6).toList();
  }

  // ── Catégorisation automatique ─────────────
  static String autoCategory(String name) {
    final lower = name.toLowerCase();
    if (RegExp(r'farine|sucre|sel|poivre|huile|beurre|levure|vinaigre|moutarde|bouillon|sauce|miel|ketchup|mayo|tabasco').hasMatch(lower))
      return '🧂 Épicerie';
    if (RegExp(r'lait|crème|fromage|yaourt|œuf|oeuf|mozzarella|parmesan|brie|gruyère|camembert|pecorino|mascarpone').hasMatch(lower))
      return '🥛 Frais';
    if (RegExp(r'tomate|oignon|ail|carotte|courgette|salade|poireau|champignon|brocoli|épinard|poivron|aubergine|céleri|pomme|citron|orange|banane|fraise|poire|raisin|herbe|basilic|persil|thym|coriandre|romarin|laurier|avocat|haricot|lentille').hasMatch(lower))
      return '🥦 Légumes & Fruits';
    if (RegExp(r'poulet|bœuf|porc|jambon|lardons|viande|saumon|thon|crevette|cabillaud|dinde|agneau|veau|guanciale|escalope').hasMatch(lower))
      return '🥩 Viandes & Poissons';
    if (RegExp(r'pain|pâtes|riz|fettuccine|spaghetti|tagliatelle|lentille|quinoa|gnocchi|blé|avoine|céréale|farro|boulgour|polenta').hasMatch(lower))
      return '🍞 Féculents';
    return '🛒 Autre';
  }

  // ── API calls ──────────────────────────────

  static Future<List<ShoppingList>> getLists() async {
    try {
      final data = await ApiService.get('/shopping');
      return (data['lists'] as List)
          .map((l) => ShoppingList.fromJson(Map<String, dynamic>.from(l)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<ShoppingList> createList(String name, {List<ShoppingItem>? items}) async {
    final data = await ApiService.post('/shopping', {
      'name': name,
      'items': (items ?? []).map((i) => i.toJson()).toList(),
    });
    return ShoppingList.fromJson(Map<String, dynamic>.from(data['list']));
  }

  static Future<ShoppingList?> updateList(ShoppingList list) async {
    if (list.id == null) return null;
    try {
      final data = await ApiService.put('/shopping/${list.id}', {
        'name': list.name,
        'items': list.items.map((i) => i.toJson()).toList(),
      });
      return ShoppingList.fromJson(Map<String, dynamic>.from(data['list']));
    } catch (_) {
      return null;
    }
  }

  static Future<void> deleteList(String id) async {
    await ApiService.delete('/shopping/$id');
  }

  // ── Convertir ingrédients recette → items ──
  static List<ShoppingItem> ingredientsToItems(List<String> ingredients) {
    return ingredients.asMap().entries.map((e) => ShoppingItem(
          id: '${DateTime.now().millisecondsSinceEpoch}_${e.key}',
          name: e.value,
          category: autoCategory(e.value),
        )).toList();
  }

  // ── Créer liste complète depuis recette ────
  static Future<ShoppingList> listFromRecipe(
      String recipeName, List<String> ingredients) async {
    final items = ingredientsToItems(ingredients);
    return createList('🍽️ $recipeName', items: items);
  }
}