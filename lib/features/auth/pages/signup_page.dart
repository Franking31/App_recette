import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/services/auth_service.dart';
import '../../recipes/pages/recipes_list_page.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      setState(() => _error = 'Remplissez tous les champs');
      return;
    }
    if (_passCtrl.text != _confirmCtrl.text) {
      setState(() => _error = 'Les mots de passe ne correspondent pas');
      return;
    }
    if (_passCtrl.text.length < 6) {
      setState(() => _error = 'Mot de passe trop court (min 6 caractères)');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await AuthService.signup(_emailCtrl.text.trim(), _passCtrl.text);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const RecipesListPage()),
        (_) => false,
      );
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // ── Retour ────────────────────
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [BoxShadow(
                        color: AppColors.cardShadow, blurRadius: 6)],
                  ),
                  child: Icon(Icons.arrow_back_ios_new,
                      color: textDark, size: 18),
                ),
              ),

              const SizedBox(height: 32),

              Center(child: AppLogo(size: 56, dark: isDark)),
              const SizedBox(height: 32),

              Text('Créer un compte 🍴',
                  style: TextStyle(
                    fontSize: 28, fontWeight: FontWeight.w900, color: textDark,
                  )),
              const SizedBox(height: 6),
              Text('Rejoignez ForkAI et sauvegardez vos recettes',
                  style: TextStyle(fontSize: 14, color: textLight)),

              const SizedBox(height: 32),

              _label('Email', textLight),
              const SizedBox(height: 8),
              _field(
                controller: _emailCtrl,
                hint: 'votre@email.com',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                surface: surface, textDark: textDark, textLight: textLight,
              ),

              const SizedBox(height: 16),

              _label('Mot de passe', textLight),
              const SizedBox(height: 8),
              _field(
                controller: _passCtrl,
                hint: '••••••••',
                icon: Icons.lock_outline,
                obscure: _obscure,
                surface: surface, textDark: textDark, textLight: textLight,
                suffix: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility,
                      color: textLight, size: 20),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),

              const SizedBox(height: 16),

              _label('Confirmer le mot de passe', textLight),
              const SizedBox(height: 8),
              _field(
                controller: _confirmCtrl,
                hint: '••••••••',
                icon: Icons.lock_outline,
                obscure: _obscure,
                surface: surface, textDark: textDark, textLight: textLight,
              ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!,
                        style: const TextStyle(color: Colors.red, fontSize: 13))),
                  ]),
                ),
              ],

              const SizedBox(height: 32),

              GestureDetector(
                onTap: _loading ? null : _signup,
                child: Container(
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: _loading ? null : AppColors.primaryGradient,
                    color: _loading ? textLight : null,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: _loading ? [] : [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 14, offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _loading
                        ? const SizedBox(width: 22, height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                        : const Text('Créer mon compte',
                            style: TextStyle(color: Colors.white,
                                fontSize: 16, fontWeight: FontWeight.w800)),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: RichText(
                    text: TextSpan(
                      text: 'Déjà un compte ? ',
                      style: TextStyle(color: textLight, fontSize: 14),
                      children: [
                        TextSpan(
                          text: 'Se connecter',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800, fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text, Color color) => Text(text,
      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color));

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color surface,
    required Color textDark,
    required Color textLight,
    bool obscure = false,
    TextInputType? keyboardType,
    Widget? suffix,
  }) =>
      Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [BoxShadow(
              color: AppColors.cardShadow, blurRadius: 8, offset: Offset(0, 3))],
        ),
        child: TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          style: TextStyle(color: textDark, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: textLight, fontSize: 14),
            prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
            suffixIcon: suffix,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 16),
          ),
        ),
      );
}