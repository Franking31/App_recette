import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth_service.dart';

// ═══════════════════════════════════════════
//  PAGE LIAISON COMPTE
//  Upgrade anonyme → email ou Google
//  Accessible depuis le profil
// ═══════════════════════════════════════════

class LinkAccountPage extends StatefulWidget {
  const LinkAccountPage({super.key});

  @override
  State<LinkAccountPage> createState() => _LinkAccountPageState();
}

class _LinkAccountPageState extends State<LinkAccountPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;
  bool _success = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _linkEmail() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    final confirm = _confirmCtrl.text;

    if (email.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Remplissez tous les champs');
      return;
    }
    if (!email.contains('@')) {
      setState(() => _error = 'Email invalide');
      return;
    }
    if (pass.length < 6) {
      setState(() => _error = 'Mot de passe trop court (6 caractères min)');
      return;
    }
    if (pass != confirm) {
      setState(() => _error = 'Les mots de passe ne correspondent pas');
      return;
    }

    setState(() { _loading = true; _error = null; });
    try {
      await AuthService.linkToEmail(email, pass);
      if (mounted) setState(() { _success = true; _loading = false; });
    } catch (e) {
      if (mounted) setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
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
        child: Column(children: [
          // Header gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withOpacity(0.75)],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(12, 14, 20, 14),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new, size: 16, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Sécuriser mon compte', style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                Text('Lier un email pour ne pas perdre vos données',
                    style: TextStyle(fontSize: 11, color: Colors.white70)),
              ]),
            ]),
          ),

          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _success ? _buildSuccess(textDark, textLight) : _buildForm(
                surface, bg, textDark, textLight, isDark),
          )),
        ]),
      ),
    );
  }

  Widget _buildSuccess(Color textDark, Color textLight) => Column(
    children: [
      const SizedBox(height: 40),
      Container(
        width: 80, height: 80,
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 48),
      ),
      const SizedBox(height: 24),
      Text('Compte sécurisé ! 🎉', style: TextStyle(
          fontSize: 22, fontWeight: FontWeight.w900, color: textDark)),
      const SizedBox(height: 8),
      Text('Toutes vos recettes, préférences et historique\nsont maintenant liés à votre compte.',
          style: TextStyle(fontSize: 14, color: textLight, height: 1.5),
          textAlign: TextAlign.center),
      const SizedBox(height: 32),
      GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Center(child: Text('Retour au profil',
              style: TextStyle(color: Colors.white,
                  fontWeight: FontWeight.w800, fontSize: 15))),
        ),
      ),
    ],
  );

  Widget _buildForm(Color surface, Color bg, Color textDark, Color textLight, bool isDark) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Banner anonyme
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Row(children: [
          const Text('⚠️', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Compte temporaire', style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w800, color: Colors.orange.shade700)),
            const SizedBox(height: 4),
            Text('Vous utilisez un compte anonyme. Vos données pourraient être perdues. Liez un email pour les sécuriser.',
                style: TextStyle(fontSize: 12, color: Colors.orange.shade600, height: 1.4)),
          ])),
        ]),
      ),
      const SizedBox(height: 24),

      // Avantages
      Text('Ce que vous conservez :', style: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w800, color: textDark)),
      const SizedBox(height: 12),
      ...['⭐ Vos recettes favorites', '📅 Votre historique IA',
          '🛒 Vos listes de courses', '🧠 Vos préférences apprises',
          '🔥 Votre streak de cuisine'].map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Text(item.split(' ').first, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Text(item.substring(item.indexOf(' ') + 1),
              style: TextStyle(fontSize: 13, color: textDark, fontWeight: FontWeight.w600)),
        ]),
      )),
      const SizedBox(height: 24),

      // Formulaire email
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 10)],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Créer mon compte', style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w900, color: textDark)),
          const SizedBox(height: 16),

          _Field(label: 'Email', controller: _emailCtrl,
              hint: 'votre@email.com', icon: Icons.email_rounded,
              surface: bg, textDark: textDark, textLight: textLight),
          const SizedBox(height: 12),

          _Field(label: 'Mot de passe', controller: _passCtrl,
              hint: '6 caractères minimum', icon: Icons.lock_rounded,
              obscure: _obscure, surface: bg, textDark: textDark, textLight: textLight,
              suffix: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility,
                    size: 18, color: textLight),
                onPressed: () => setState(() => _obscure = !_obscure),
              )),
          const SizedBox(height: 12),

          _Field(label: 'Confirmer', controller: _confirmCtrl,
              hint: 'Répétez le mot de passe', icon: Icons.lock_outline_rounded,
              obscure: true, surface: bg, textDark: textDark, textLight: textLight),
          const SizedBox(height: 16),

          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(_error!, style: const TextStyle(
                    color: Colors.red, fontSize: 12))),
              ]),
            ),
            const SizedBox(height: 12),
          ],

          GestureDetector(
            onTap: _loading ? null : _linkEmail,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(
                    color: AppColors.primary.withOpacity(0.35),
                    blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (_loading)
                  const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                else
                  const Icon(Icons.link_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(_loading ? 'Liaison en cours...' : 'Sécuriser mon compte',
                    style: const TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w800, fontSize: 15)),
              ]),
            ),
          ),
        ]),
      ),

      const SizedBox(height: 16),

      // Option "plus tard"
      Center(child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Text('Plus tard', style: TextStyle(
            fontSize: 13, color: textLight, decoration: TextDecoration.underline)),
      )),
    ]);
  }
}

class _Field extends StatelessWidget {
  final String label, hint;
  final TextEditingController controller;
  final IconData icon;
  final bool obscure;
  final Color surface, textDark, textLight;
  final Widget? suffix;

  const _Field({required this.label, required this.hint,
      required this.controller, required this.icon,
      this.obscure = false, required this.surface,
      required this.textDark, required this.textLight, this.suffix});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(fontSize: 12,
          fontWeight: FontWeight.w700, color: textDark)),
      const SizedBox(height: 6),
      TextField(
        controller: controller,
        obscureText: obscure,
        style: TextStyle(color: textDark, fontSize: 14),
        keyboardType: label == 'Email'
            ? TextInputType.emailAddress : TextInputType.text,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: textLight, fontSize: 13),
          filled: true, fillColor: surface,
          prefixIcon: Icon(icon, size: 18, color: textLight),
          suffixIcon: suffix,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2)),
        ),
      ),
    ],
  );
}