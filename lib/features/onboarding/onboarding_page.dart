import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../auth/pages/login_page.dart';
import '../auth/pages/signup_page.dart';


// ═══════════════════════════════════════════
//  ONBOARDING — ForkAI
//  4 écrans animés : Bienvenue, Photo→Recette,
//  IA, Compte — avec PageView + animations
// ═══════════════════════════════════════════

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _floatController;
  late AnimationController _pulseController;
  late AnimationController _rotateController;

  @override
  void initState() {
    super.initState();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _floatController.dispose();
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _goToLogin() => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );

  void _goToSignup() => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SignupPage()),
      );

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // ── Pages ─────────────────────────────────
          PageView(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentPage = i),
            children: [
              _buildPage0(size), // Bienvenue
              _buildPage1(size), // Photo → Recette
              _buildPage2(size), // IA
              _buildPage3(size), // Compte
            ],
          ),

          // ── Indicateurs de page ───────────────────
          Positioned(
            bottom: 160,
            left: 0, right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == i ? 28 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == i
                      ? Colors.white
                      : Colors.white.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
              )),
            ),
          ),

          // ── Boutons navigation ────────────────────
          Positioned(
            bottom: 50,
            left: 24, right: 24,
            child: _currentPage < 3
                ? _buildNextButton()
                : _buildFinalButtons(),
          ),

          // ── Skip (pages 0-2) ──────────────────────
          if (_currentPage < 3)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 20,
              child: GestureDetector(
                onTap: _goToLogin,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Passer',
                      style: TextStyle(color: Colors.white,
                          fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  //  PAGE 0 — Bienvenue
  // ──────────────────────────────────────────
  Widget _buildPage0(Size size) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFD4522A), Color(0xFFF07A50), Color(0xFFFFB347)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Cercles décoratifs
          _decorativeCircle(-60, -60, 220, Colors.white.withOpacity(0.08)),
          _decorativeCircle(size.width - 80, size.height - 180, 200,
              Colors.white.withOpacity(0.06)),
          _decorativeCircle(size.width - 40, 80, 120,
              Colors.white.withOpacity(0.1)),

          // Contenu
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Logo animé
                AnimatedBuilder(
                  animation: _floatController,
                  builder: (_, __) => Transform.translate(
                    offset: Offset(0,
                        -12 * _floatController.value),
                    child: Container(
                      width: 140, height: 140,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 30,
                            offset: Offset(0,
                                10 + 6 * _floatController.value),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text('🍴',
                            style: TextStyle(fontSize: 70)),
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 1),

                // Texte
                const Text('Bienvenue sur',
                    style: TextStyle(color: Colors.white70,
                        fontSize: 18, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                const Text('ForkAI',
                    style: TextStyle(color: Colors.white,
                        fontSize: 52, fontWeight: FontWeight.w900,
                        letterSpacing: -1)),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Votre chef personnel alimenté par l\'intelligence artificielle',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withOpacity(0.85),
                        fontSize: 16, height: 1.5),
                  ),
                ),

                // Badges features
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _featureBadge('📸', 'Photo'),
                    const SizedBox(width: 12),
                    _featureBadge('🤖', 'IA'),
                    const SizedBox(width: 12),
                    _featureBadge('🍽️', 'Recettes'),
                  ],
                ),

                const Spacer(flex: 3),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  //  PAGE 1 — Photo → Recette
  // ──────────────────────────────────────────
  Widget _buildPage1(Size size) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A1208), Color(0xFF2A1F12), Color(0xFF3D2B14)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          _decorativeCircle(-40, size.height * 0.3, 180,
              AppColors.primary.withOpacity(0.15)),
          _decorativeCircle(size.width - 60, size.height * 0.1, 150,
              AppColors.accent.withOpacity(0.1)),

          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 1),

                // Animation flux photo → recette
                SizedBox(
                  height: 280,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Téléphone avec photo
                      AnimatedBuilder(
                        animation: _floatController,
                        builder: (_, __) => Transform.translate(
                          offset: Offset(0, -8 * _floatController.value),
                          child: _phoneWidget(),
                        ),
                      ),

                      // Flèche animée
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (_, __) => Positioned(
                          bottom: 60,
                          child: Opacity(
                            opacity: 0.6 + 0.4 * _pulseController.value,
                            child: const Icon(Icons.arrow_downward,
                                color: AppColors.primary, size: 32),
                          ),
                        ),
                      ),

                      // Carte recette
                      Positioned(
                        bottom: 0,
                        child: _recipePreviewCard(),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 1),

                // Texte
                const Text('📸 Photo → Recette',
                    style: TextStyle(color: AppColors.primary,
                        fontSize: 13, fontWeight: FontWeight.w700,
                        letterSpacing: 1.5)),
                const SizedBox(height: 12),
                const Text('Photographiez\nvotre frigo',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white,
                        fontSize: 34, fontWeight: FontWeight.w900,
                        height: 1.1)),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Gemini Vision analyse vos ingrédients et génère 5 recettes personnalisées en quelques secondes',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withOpacity(0.6),
                        fontSize: 14, height: 1.6),
                  ),
                ),

                const Spacer(flex: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  //  PAGE 2 — IA
  // ──────────────────────────────────────────
  Widget _buildPage2(Size size) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A2A3A), Color(0xFF0D1B2A), Color(0xFF162032)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Étoiles de fond
          ...List.generate(12, (i) => _starDot(size, i)),

          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 1),

                // Orbites animées
                SizedBox(
                  height: 260,
                  width: double.infinity,
                  child: AnimatedBuilder(
                    animation: _rotateController,
                    builder: (_, __) => Stack(
                      alignment: Alignment.center,
                      children: [
                        // Cercle externe
                        Transform.rotate(
                          angle: _rotateController.value * 2 * math.pi,
                          child: Container(
                            width: 220, height: 220,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.08),
                                  width: 1),
                            ),
                            child: Stack(children: [
                              Positioned(top: 0, left: 95,
                                  child: _orbitDot('🍅', 28)),
                            ]),
                          ),
                        ),
                        // Cercle moyen
                        Transform.rotate(
                          angle: -_rotateController.value * 2 * math.pi * 0.7,
                          child: Container(
                            width: 150, height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.12),
                                  width: 1),
                            ),
                            child: Stack(children: [
                              Positioned(bottom: 0, left: 57,
                                  child: _orbitDot('🥕', 24)),
                            ]),
                          ),
                        ),
                        // Centre IA
                        Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            gradient: RadialGradient(colors: [
                              AppColors.accent.withOpacity(0.8),
                              AppColors.primary.withOpacity(0.6),
                            ]),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accent.withOpacity(0.4),
                                blurRadius: 20, spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text('🤖',
                                style: TextStyle(fontSize: 36)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(flex: 1),

                const Text('🤖 Intelligence Artificielle',
                    style: TextStyle(color: AppColors.accent,
                        fontSize: 12, fontWeight: FontWeight.w700,
                        letterSpacing: 1.5)),
                const SizedBox(height: 12),
                const Text('Propulsé par\ndes IA de pointe',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white,
                        fontSize: 34, fontWeight: FontWeight.w900,
                        height: 1.1)),
                const SizedBox(height: 20),

                // Chips IA
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _aiChip('✨ Gemini Vision'),
                    const SizedBox(width: 10),
                    _aiChip('⚡ Groq LLaMA'),
                  ],
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Analyse visuelle, génération de recettes, calcul nutritionnel et substitutions intelligentes',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withOpacity(0.55),
                        fontSize: 14, height: 1.6),
                  ),
                ),

                const Spacer(flex: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  //  PAGE 3 — Compte
  // ──────────────────────────────────────────
  Widget _buildPage3(Size size) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2D5A27), Color(0xFF1A3A16), Color(0xFF0F2A0C)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          _decorativeCircle(-50, size.height * 0.2, 200,
              Colors.white.withOpacity(0.04)),
          _decorativeCircle(size.width - 40, size.height * 0.6, 180,
              AppColors.accentGreen.withOpacity(0.15)),

          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 1),

                // Illustration compte
                AnimatedBuilder(
                  animation: _floatController,
                  builder: (_, __) => Transform.translate(
                    offset: Offset(0, -10 * _floatController.value),
                    child: Container(
                      width: 160, height: 160,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withOpacity(0.2), width: 2),
                      ),
                      child: const Center(
                        child: Text('👨‍🍳',
                            style: TextStyle(fontSize: 80)),
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 1),

                const Text('👤 Votre compte',
                    style: TextStyle(color: Color(0xFF7BC67A),
                        fontSize: 13, fontWeight: FontWeight.w700,
                        letterSpacing: 1.5)),
                const SizedBox(height: 12),
                const Text('Prêt à cuisiner\ndifféremment ?',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white,
                        fontSize: 34, fontWeight: FontWeight.w900,
                        height: 1.1)),
                const SizedBox(height: 16),

                // Avantages compte
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      _benefitRow('💾', 'Sauvegardez vos recettes favorites'),
                      const SizedBox(height: 10),
                      _benefitRow('🛒', 'Générez vos listes de courses'),
                      const SizedBox(height: 10),
                      _benefitRow('📊', 'Suivez vos infos nutritionnelles'),
                    ],
                  ),
                ),

                const Spacer(flex: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  //  BOUTONS
  // ──────────────────────────────────────────
  Widget _buildNextButton() {
    return GestureDetector(
      onTap: _nextPage,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 16, offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Continuer',
                style: TextStyle(
                    color: _pageColors[_currentPage],
                    fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_rounded,
                color: _pageColors[_currentPage]),
          ],
        ),
      ),
    );
  }

  Widget _buildFinalButtons() {
    return Column(
      children: [
        // Créer un compte
        GestureDetector(
          onTap: _goToSignup,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 16, offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Center(
              child: Text('Créer un compte gratuit',
                  style: TextStyle(color: Color(0xFF2D5A27),
                      fontWeight: FontWeight.w800, fontSize: 16)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Déjà un compte
        GestureDetector(
          onTap: _goToLogin,
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: const Center(
              child: Text('J\'ai déjà un compte',
                  style: TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w600, fontSize: 15)),
            ),
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────
  //  WIDGETS UTILITAIRES
  // ──────────────────────────────────────────
  static const List<Color> _pageColors = [
    Color(0xFFD4522A),
    Color(0xFFD4522A),
    Color(0xFFE8B84B),
    Color(0xFF2D5A27),
  ];

  Widget _decorativeCircle(double x, double y, double size, Color color) =>
      Positioned(
        left: x, top: y,
        child: Container(
          width: size, height: size,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      );

  Widget _featureBadge(String emoji, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w700, fontSize: 13)),
          ],
        ),
      );

  Widget _phoneWidget() => Container(
        width: 130, height: 180,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1208),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.15), width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 20, offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Column(
            children: [
              Container(
                height: 8,
                color: Colors.black,
                child: Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  color: const Color(0xFF2A1F12),
                  child: const Center(
                    child: Text('📷\n🧀🥦🍗', textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 22, height: 1.6)),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _recipePreviewCard() => Container(
        width: 200,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF2A1F12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppColors.primary.withOpacity(0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 16, offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(child: Text('🍝', style: TextStyle(fontSize: 20))),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Gratin fromage', style: TextStyle(
                      color: Colors.white, fontSize: 12,
                      fontWeight: FontWeight.w700)),
                  Text('30 min · 4 pers.', style: TextStyle(
                      color: Colors.white54, fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _orbitDot(String emoji, double size) => Container(
        width: size, height: size,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        child: Center(child: Text(emoji,
            style: TextStyle(fontSize: size * 0.55))),
      );

  Widget _aiChip(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: Text(label,
            style: const TextStyle(color: Colors.white,
                fontSize: 12, fontWeight: FontWeight.w700)),
      );

  Widget _starDot(Size size, int i) {
    final rng = math.Random(i * 42);
    return Positioned(
      left: rng.nextDouble() * size.width,
      top: rng.nextDouble() * size.height * 0.5,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (_, __) => Opacity(
          opacity: (0.3 + 0.4 * ((i % 3) / 3.0)) *
              (0.7 + 0.3 * _pulseController.value),
          child: Container(
            width: 3 + (i % 3).toDouble(),
            height: 3 + (i % 3).toDouble(),
            decoration: const BoxDecoration(
              color: Colors.white, shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  Widget _benefitRow(String emoji, String text) => Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: TextStyle(color: Colors.white.withOpacity(0.8),
                    fontSize: 14, fontWeight: FontWeight.w500)),
          ),
          const Icon(Icons.check_circle, color: Color(0xFF7BC67A), size: 18),
        ],
      );
}