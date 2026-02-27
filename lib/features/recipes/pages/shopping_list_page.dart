import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/shopping_service.dart';

// ═══════════════════════════════════════════
//  SHOPPING LIST PAGE — Listes multiples
// ═══════════════════════════════════════════

class ShoppingListPage extends StatefulWidget {
  /// Si fourni, ouvre directement cette liste
  final ShoppingList? initialList;
  const ShoppingListPage({super.key, this.initialList});

  @override
  State<ShoppingListPage> createState() => _ShoppingListPageState();
}

class _ShoppingListPageState extends State<ShoppingListPage> {
  List<ShoppingList> _lists = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final lists = await ShoppingService.getLists();
    if (mounted) setState(() { _lists = lists; _loading = false; });
  }

  // ── Créer une nouvelle liste ───────────────
  Future<void> _createList() async {
    final nameCtrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _NameDialog(controller: nameCtrl, title: 'Nouvelle liste', hint: 'Ex: Semaine du 3 mars'),
    );
    if (name == null || name.trim().isEmpty) return;
    setState(() => _loading = true);
    final list = await ShoppingService.createList(name.trim());
    setState(() { _lists.insert(0, list); _loading = false; });
    if (mounted) _openList(list);
  }

  // ── Ouvrir une liste en détail ─────────────
  void _openList(ShoppingList list) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _ShoppingDetailPage(list: list)),
    );
    // Recharger après retour
    _load();
  }

  // ── Supprimer une liste ────────────────────
  Future<void> _deleteList(ShoppingList list) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Supprimer la liste ?'),
        content: Text('« ${list.name} » sera définitivement supprimée.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('Supprimer', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    if (list.id != null) await ShoppingService.deleteList(list.id!);
    setState(() => _lists.remove(list));
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
        child: Column(
          children: [
            // ── Header ─────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: surface, borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 8)],
                      ),
                      child: Icon(Icons.arrow_back_ios_new, size: 18, color: textDark),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('🛒 Mes listes', style: TextStyle(fontSize: 24,
                            fontWeight: FontWeight.w900, color: textDark)),
                        Text('${_lists.length} liste${_lists.length > 1 ? 's' : ''}',
                            style: TextStyle(fontSize: 13, color: textLight)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Contenu ─────────────────────────
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _lists.isEmpty
                      ? _emptyState(textLight)
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: AppColors.primary,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _lists.length,
                            itemBuilder: (ctx, i) => _ListCard(
                              list: _lists[i],
                              isDark: isDark,
                              onTap: () => _openList(_lists[i]),
                              onDelete: () => _deleteList(_lists[i]),
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),

      // ── FAB Nouvelle liste ──────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createList,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle liste', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _emptyState(Color textLight) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('🛒', style: const TextStyle(fontSize: 56)),
        const SizedBox(height: 16),
        Text('Aucune liste de courses', style: TextStyle(fontSize: 18,
            fontWeight: FontWeight.w700, color: textLight)),
        const SizedBox(height: 8),
        Text('Créez votre première liste !', style: TextStyle(color: textLight, fontSize: 14)),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _createList,
          icon: const Icon(Icons.add),
          label: const Text('Créer une liste'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────
//  Carte liste dans l'index
// ─────────────────────────────────────────────
class _ListCard extends StatelessWidget {
  final ShoppingList list;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _ListCard({required this.list, required this.isDark, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final textDark = isDark ? AppColors.darkTextDark : AppColors.textDark;
    final textLight = isDark ? AppColors.darkTextLight : AppColors.textLight;
    final progress = list.totalCount > 0 ? list.checkedCount / list.totalCount : 0.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(list.name, style: TextStyle(fontSize: 17,
                    fontWeight: FontWeight.w800, color: textDark))),
                GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (list.totalCount > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${list.checkedCount}/${list.totalCount} articles',
                      style: TextStyle(fontSize: 13, color: textLight)),
                  Text('${(progress * 100).toInt()}%',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                          color: progress == 1 ? Colors.green : AppColors.primary)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: AppColors.primary.withOpacity(0.15),
                  valueColor: AlwaysStoppedAnimation(
                    progress == 1 ? Colors.green : AppColors.primary),
                ),
              ),
            ] else
              Text('Vide — appuyez pour ajouter des articles',
                  style: TextStyle(fontSize: 13, color: textLight)),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.arrow_forward_ios, size: 12, color: textLight),
                const SizedBox(width: 4),
                Text('Ouvrir la liste', style: TextStyle(fontSize: 12,
                    color: AppColors.primary, fontWeight: FontWeight.w700)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Page détail d'une liste
// ─────────────────────────────────────────────
class _ShoppingDetailPage extends StatefulWidget {
  final ShoppingList list;
  const _ShoppingDetailPage({required this.list});

  @override
  State<_ShoppingDetailPage> createState() => _ShoppingDetailPageState();
}

class _ShoppingDetailPageState extends State<_ShoppingDetailPage> {
  late ShoppingList _list;
  final _inputCtrl = TextEditingController();
  final _inputFocus = FocusNode();
  List<String> _suggestions = [];
  bool _saving = false;

  static const List<String> _categories = [
    '🧂 Épicerie', '🥛 Frais', '🥦 Légumes & Fruits',
    '🥩 Viandes & Poissons', '🍞 Féculents', '🛒 Autre'
  ];
  String _selectedCategory = '🛒 Autre';

  @override
  void initState() {
    super.initState();
    _list = widget.list;
    _inputCtrl.addListener(_onInput);
  }

  @override
  void dispose() {
    _inputCtrl.removeListener(_onInput);
    _inputCtrl.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  void _onInput() {
    final q = _inputCtrl.text;
    final sug = ShoppingService.searchSuggestions(q);
    setState(() {
      _suggestions = sug;
      // Auto-catégoriser
      if (q.isNotEmpty) {
        _selectedCategory = ShoppingService.autoCategory(q);
      }
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    await ShoppingService.updateList(_list);
    if (mounted) setState(() => _saving = false);
  }

  void _addItem(String name) {
    if (name.trim().isEmpty) return;
    final item = ShoppingItem(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      category: _selectedCategory,
    );
    setState(() {
      _list.items.add(item);
      _inputCtrl.clear();
      _suggestions = [];
      _selectedCategory = '🛒 Autre';
    });
    _inputFocus.requestFocus();
    _save();
  }

  void _toggleItem(ShoppingItem item) {
    setState(() => item.checked = !item.checked);
    _save();
  }

  void _deleteItem(ShoppingItem item) {
    setState(() => _list.items.remove(item));
    _save();
  }

  void _clearChecked() {
    setState(() => _list.items.removeWhere((i) => i.checked));
    _save();
  }

  // Grouper par catégorie
  Map<String, List<ShoppingItem>> get _grouped {
    final Map<String, List<ShoppingItem>> map = {};
    for (final item in _list.items) {
      map.putIfAbsent(item.category, () => []).add(item);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.background;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final textDark = isDark ? AppColors.darkTextDark : AppColors.textDark;
    final textLight = isDark ? AppColors.darkTextLight : AppColors.textLight;
    final checkedCount = _list.checkedCount;
    final total = _list.totalCount;
    final progress = total > 0 ? checkedCount / total : 0.0;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ─────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 38, height: 38,
                          decoration: BoxDecoration(
                            color: surface, borderRadius: BorderRadius.circular(10),
                            boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 6)],
                          ),
                          child: Icon(Icons.arrow_back_ios_new, size: 16, color: textDark),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(_list.name, style: TextStyle(fontSize: 20,
                          fontWeight: FontWeight.w900, color: textDark),
                          maxLines: 1, overflow: TextOverflow.ellipsis)),
                      if (_saving)
                        const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                      else
                        Icon(Icons.cloud_done_outlined, color: Colors.green.shade400, size: 20),
                      if (checkedCount > 0) ...[
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: _clearChecked,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(children: [
                              const Icon(Icons.delete_sweep, color: Colors.red, size: 16),
                              const SizedBox(width: 4),
                              Text('Vider ($checkedCount)', style: const TextStyle(
                                  color: Colors.red, fontSize: 12, fontWeight: FontWeight.w700)),
                            ]),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (total > 0) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('$checkedCount/$total articles cochés',
                            style: TextStyle(fontSize: 13, color: textLight)),
                        Text('${(progress * 100).toInt()}%',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                                color: progress == 1.0 ? Colors.green : AppColors.primary)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress, minHeight: 8,
                        backgroundColor: AppColors.primary.withOpacity(0.12),
                        valueColor: AlwaysStoppedAnimation(
                            progress == 1.0 ? Colors.green : AppColors.primary),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Liste des articles ──────────────
            Expanded(
              child: total == 0
                  ? Center(child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('🛍️', style: const TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        Text('Liste vide', style: TextStyle(fontSize: 16, color: textLight)),
                        Text('Ajoutez des articles ci-dessous', style: TextStyle(fontSize: 13, color: textLight)),
                      ],
                    ))
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        ..._grouped.entries.map((entry) => _CategorySection(
                          category: entry.key,
                          items: entry.value,
                          isDark: isDark,
                          onToggle: _toggleItem,
                          onDelete: _deleteItem,
                        )),
                        const SizedBox(height: 80),
                      ],
                    ),
            ),

            // ── Zone de saisie ──────────────────
            _InputArea(
              controller: _inputCtrl,
              focusNode: _inputFocus,
              suggestions: _suggestions,
              selectedCategory: _selectedCategory,
              categories: _categories,
              isDark: isDark,
              onCategoryChanged: (c) => setState(() => _selectedCategory = c),
              onSuggestionTap: _addItem,
              onSubmit: () => _addItem(_inputCtrl.text),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Section catégorie
// ─────────────────────────────────────────────
class _CategorySection extends StatelessWidget {
  final String category;
  final List<ShoppingItem> items;
  final bool isDark;
  final void Function(ShoppingItem) onToggle;
  final void Function(ShoppingItem) onDelete;

  const _CategorySection({
    required this.category, required this.items,
    required this.isDark, required this.onToggle, required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final textDark = isDark ? AppColors.darkTextDark : AppColors.textDark;
    final textLight = isDark ? AppColors.darkTextLight : AppColors.textLight;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 6),
          child: Text(category, style: TextStyle(fontSize: 13,
              fontWeight: FontWeight.w800, color: textLight,
              letterSpacing: 0.5)),
        ),
        Container(
          decoration: BoxDecoration(
            color: surface, borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            children: items.asMap().entries.map((e) {
              final item = e.value;
              final isLast = e.key == items.length - 1;
              return Dismissible(
                key: Key(item.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.15),
                    borderRadius: isLast
                        ? const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16))
                        : BorderRadius.zero,
                  ),
                  child: const Icon(Icons.delete_outline, color: Colors.red),
                ),
                onDismissed: (_) => onDelete(item),
                child: GestureDetector(
                  onTap: () => onToggle(item),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                    decoration: BoxDecoration(
                      border: isLast ? null : Border(
                        bottom: BorderSide(color: AppColors.cardShadow.withOpacity(0.5))),
                    ),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 22, height: 22,
                          decoration: BoxDecoration(
                            color: item.checked ? Colors.green : Colors.transparent,
                            border: Border.all(
                              color: item.checked ? Colors.green : AppColors.textLight.withOpacity(0.5),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: item.checked
                              ? const Icon(Icons.check, color: Colors.white, size: 14)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(item.name, style: TextStyle(
                            fontSize: 14,
                            color: item.checked ? textLight : textDark,
                            decoration: item.checked ? TextDecoration.lineThrough : null,
                          )),
                        ),
                        const Icon(Icons.drag_handle, color: Colors.transparent, size: 18),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  Zone de saisie avec autocomplete
// ─────────────────────────────────────────────
class _InputArea extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final List<String> suggestions;
  final String selectedCategory;
  final List<String> categories;
  final bool isDark;
  final void Function(String) onCategoryChanged;
  final void Function(String) onSuggestionTap;
  final VoidCallback onSubmit;

  const _InputArea({
    required this.controller, required this.focusNode,
    required this.suggestions, required this.selectedCategory,
    required this.categories, required this.isDark,
    required this.onCategoryChanged, required this.onSuggestionTap,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final textDark = isDark ? AppColors.darkTextDark : AppColors.textDark;
    final textLight = isDark ? AppColors.darkTextLight : AppColors.textLight;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        boxShadow: [BoxShadow(color: AppColors.cardShadow.withOpacity(0.4),
            blurRadius: 20, offset: const Offset(0, -4))],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Suggestions
          if (suggestions.isNotEmpty)
            Container(
              height: 44,
              margin: const EdgeInsets.only(top: 12),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: suggestions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => onSuggestionTap(suggestions[i]),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: Text(suggestions[i], style: const TextStyle(
                        fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ),

          // Sélecteur de catégorie
          Container(
            height: 36,
            margin: const EdgeInsets.only(top: 8),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final cat = categories[i];
                final selected = cat == selectedCategory;
                return GestureDetector(
                  onTap: () => onCategoryChanged(cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(cat, style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : AppColors.primary,
                    )),
                  ),
                );
              },
            ),
          ),

          // Champ de saisie
          Padding(
            padding: EdgeInsets.fromLTRB(16, 10, 16, MediaQuery.of(context).viewInsets.bottom + 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBackground : AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      style: TextStyle(color: textDark, fontSize: 14),
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => onSubmit(),
                      decoration: InputDecoration(
                        hintText: 'Ajouter un article...',
                        hintStyle: TextStyle(color: textLight, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: onSubmit,
                  child: Container(
                    width: 46, height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4),
                          blurRadius: 8, offset: const Offset(0, 3))],
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 22),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Dialog renommage
// ─────────────────────────────────────────────
class _NameDialog extends StatelessWidget {
  final TextEditingController controller;
  final String title;
  final String hint;
  const _NameDialog({required this.controller, required this.title, required this.hint});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
        onSubmitted: (_) => Navigator.pop(context, controller.text),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, controller.text),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
          child: const Text('Créer'),
        ),
      ],
    );
  }
}