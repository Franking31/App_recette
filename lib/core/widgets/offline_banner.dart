import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/cache_service.dart';

// ═══════════════════════════════════════════
//  OFFLINE BANNER — Indicateur connexion
//  S'affiche automatiquement quand hors-ligne
//  Disparaît avec animation au retour en ligne
// ═══════════════════════════════════════════

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: CacheService.onlineNotifier,
      builder: (context, isOnline, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: CacheService.syncingNotifier,
          builder: (context, isSyncing, _) {
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, anim) => SizeTransition(
                sizeFactor: anim,
                child: child,
              ),
              child: !isOnline
                  ? _OfflineBar(key: const ValueKey('offline'))
                  : isSyncing
                      ? _SyncBar(key: const ValueKey('syncing'))
                      : const SizedBox.shrink(key: ValueKey('none')),
            );
          },
        );
      },
    );
  }
}

// ── Barre hors-ligne ──────────────────────
class _OfflineBar extends StatelessWidget {
  const _OfflineBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: const Color(0xFF5C4A32),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.white70, size: 14),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Mode hors-ligne — données en cache',
              style: TextStyle(color: Colors.white,
                  fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          GestureDetector(
            onTap: () => CacheService.forcSync(),
            child: const Icon(Icons.refresh_rounded,
                color: Colors.white70, size: 16),
          ),
        ],
      ),
    );
  }
}

// ── Barre synchronisation ─────────────────
class _SyncBar extends StatelessWidget {
  const _SyncBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: AppColors.accentGreen.withOpacity(0.85),
      child: const Row(
        children: [
          SizedBox(
            width: 12, height: 12,
            child: CircularProgressIndicator(
                color: Colors.white, strokeWidth: 2),
          ),
          SizedBox(width: 10),
          Text('Synchronisation en cours...',
              style: TextStyle(color: Colors.white,
                  fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}