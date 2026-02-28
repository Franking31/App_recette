import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import 'ai_assistant_page.dart';

// ═══════════════════════════════════════════
//  HISTORIQUE DES CONVERSATIONS IA
// ═══════════════════════════════════════════
class ConversationsHistoryPage extends StatefulWidget {
  const ConversationsHistoryPage({super.key});

  @override
  State<ConversationsHistoryPage> createState() => _ConversationsHistoryPageState();
}

class _ConversationsHistoryPageState extends State<ConversationsHistoryPage> {
  List<Map<String, dynamic>> _conversations = [];
  bool _loading = true;

  // Icônes par mode IA
  static const Map<String, String> _modeIcons = {
    'generate': '✨',
    'chat': '💬',
    'antiWaste': '♻️',
    'nutrition': '🥗',
    'wine': '🍷',
    'seasonal': '🌿',
    'budget': '💰',
    'world': '🌍',
    'healthy': '💪',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.get('/conversations');
      if (mounted) {
        setState(() {
          _conversations = (data['conversations'] as List)
              .map((c) => Map<String, dynamic>.from(c))
              .toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete(String id) async {
    await ApiService.delete('/conversations/$id');
    setState(() => _conversations.removeWhere((c) => c['id'] == id));
  }

  Future<void> _deleteAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Tout supprimer ?',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('Toutes vos conversations seront supprimées.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Supprimer tout'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    for (final c in _conversations) {
      await ApiService.delete('/conversations/${c['id']}');
    }
    setState(() => _conversations = []);
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    if (diff.inDays == 1) return 'Hier';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays} jours';
    return '${dt.day}/${dt.month}/${dt.year}';
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
            // ── HEADER ────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: surface, borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 6)],
                      ),
                      child: Icon(Icons.arrow_back_ios_new, size: 18, color: textDark),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('🤖 Historique IA',
                            style: TextStyle(fontSize: 22,
                                fontWeight: FontWeight.w900, color: textDark)),
                        Text('${_conversations.length} conversation(s)',
                            style: TextStyle(fontSize: 12, color: textLight)),
                      ],
                    ),
                  ),
                  if (_conversations.isNotEmpty)
                    GestureDetector(
                      onTap: _deleteAll,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('Tout effacer',
                            style: TextStyle(color: Colors.red,
                                fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                    ),
                ],
              ),
            ),

            // ── LISTE ─────────────────────────
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _conversations.isEmpty
                      ? _emptyState(textLight)
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: AppColors.primary,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _conversations.length,
                            itemBuilder: (_, i) {
                              final c = _conversations[i];
                              final mode = c['mode'] ?? 'chat';
                              final icon = _modeIcons[mode] ?? '💬';
                              return Dismissible(
                                key: Key(c['id']),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(Icons.delete_outline, color: Colors.red),
                                ),
                                onDismissed: (_) => _delete(c['id']),
                                child: GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const AiAssistantPage(),
                                    ),
                                  ).then((_) => _load()),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: surface,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [BoxShadow(
                                          color: AppColors.cardShadow,
                                          blurRadius: 8,
                                          offset: const Offset(0, 3))],
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 44, height: 44,
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Center(child: Text(icon,
                                              style: const TextStyle(fontSize: 22))),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                c['title'] ?? 'Conversation',
                                                style: TextStyle(fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    color: textDark),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 3),
                                              Text(_formatDate(c['updated_at']),
                                                  style: TextStyle(
                                                      fontSize: 12, color: textLight)),
                                            ],
                                          ),
                                        ),
                                        Icon(Icons.arrow_forward_ios,
                                            size: 13, color: textLight),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),

      // ── FAB Nouvelle conversation ───────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AiAssistantPage()),
        ).then((_) => _load()),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _emptyState(Color textLight) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('🤖', style: TextStyle(fontSize: 56)),
        const SizedBox(height: 16),
        Text('Aucune conversation', style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w700, color: textLight)),
        const SizedBox(height: 8),
        Text("Commencez à discuter avec l'IA !",
            style: TextStyle(color: textLight, fontSize: 14)),
      ],
    ),
  );
}