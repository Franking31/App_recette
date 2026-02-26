import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

// ═══════════════════════════════════════════
//  LOGO FORKAI — Widget réutilisable
//  Usage: AppLogo(), AppLogo(size: 48), AppLogo.full()
// ═══════════════════════════════════════════

class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool dark;

  const AppLogo({
    super.key,
    this.size = 40,
    this.showText = false,
    this.dark = false,
  });

  /// Logo avec nom de l'app à côté
  const AppLogo.full({
    super.key,
    this.size = 40,
    this.dark = false,
  }) : showText = true;

  /// Logo pour splash / onboarding (grand)
  const AppLogo.hero({
    super.key,
    this.dark = false,
  })  : size = 80,
        showText = true;

  @override
  Widget build(BuildContext context) {
    final logoWidget = _LogoMark(size: size, dark: dark);

    if (!showText) return logoWidget;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        logoWidget,
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Fork',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: size * 0.55,
                fontWeight: FontWeight.w900,
                color: dark ? AppColors.darkTextDark : AppColors.textDark,
                height: 1.0,
              ),
            ),
            Text(
              'AI',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: size * 0.38,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                height: 1.0,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LogoMark extends StatelessWidget {
  final double size;
  final bool dark;

  const _LogoMark({required this.size, required this.dark});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _LogoPainter(dark: dark),
    );
  }
}

class _LogoPainter extends CustomPainter {
  final bool dark;
  const _LogoPainter({required this.dark});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── Fond rond avec gradient ──
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFD4522A), Color(0xFFF07A50)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, w, h),
        Radius.circular(w * 0.28),
      ),
      bgPaint,
    );

    // ── Ombre douce ──
    final shadowPaint = Paint()
      ..color = const Color(0x30000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.1, h * 0.85, w * 0.8, h * 0.12),
        Radius.circular(w * 0.1),
      ),
      shadowPaint,
    );

    final iconPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = w * 0.07;

    final iconFillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // ── Fourchette (gauche) ──
    final forkX = w * 0.32;
    final topY = h * 0.18;
    final bottomY = h * 0.82;
    final midY = h * 0.48;

    // Manche fourchette
    canvas.drawLine(
      Offset(forkX, midY),
      Offset(forkX, bottomY),
      iconPaint,
    );

    // Dents fourchette
    final toothSpacing = w * 0.07;
    for (int i = -1; i <= 1; i++) {
      canvas.drawLine(
        Offset(forkX + i * toothSpacing, topY),
        Offset(forkX + i * toothSpacing, midY - h * 0.04),
        iconPaint,
      );
    }
    // Connexion dents
    canvas.drawLine(
      Offset(forkX - toothSpacing, midY - h * 0.04),
      Offset(forkX + toothSpacing, midY - h * 0.04),
      iconPaint,
    );

    // ── Étoile IA (centre haut) ──
    final starX = w * 0.66;
    final starY = h * 0.30;
    final starR = w * 0.10;

    final starPath = Path();
    for (int i = 0; i < 4; i++) {
      final angle = i * 3.14159 / 2;
      final x1 = starX + starR * 1.0 * _cos(angle);
      final y1 = starY + starR * 1.0 * _sin(angle);
      final x2 = starX + starR * 0.3 * _cos(angle + 3.14159 / 4);
      final y2 = starY + starR * 0.3 * _sin(angle + 3.14159 / 4);
      if (i == 0) {
        starPath.moveTo(x1, y1);
      } else {
        starPath.lineTo(x2, y2);
        starPath.lineTo(x1, y1);
      }
      starPath.lineTo(x2, y2);
    }
    starPath.close();
    canvas.drawPath(starPath, iconFillPaint);

    // ── Petites étoiles autour ──
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.72, h * 0.52), w * 0.03, dotPaint);
    canvas.drawCircle(Offset(w * 0.58, h * 0.22), w * 0.025, dotPaint);

    // ── Couteau (droite) ──
    final knifeX = w * 0.68;
    final knifePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = w * 0.065;

    // Lame arrondie
    final bladePath = Path()
      ..moveTo(knifeX, bottomY)
      ..lineTo(knifeX, h * 0.42)
      ..quadraticBezierTo(
        knifeX + w * 0.09, h * 0.30,
        knifeX, topY + h * 0.04,
      );
    canvas.drawPath(bladePath, knifePaint);

    // Manche couteau
    canvas.drawLine(
      Offset(knifeX, h * 0.42),
      Offset(knifeX, bottomY),
      knifePaint,
    );
  }

  double _cos(double angle) => angle == 0 ? 1 : (angle == 3.14159 ? -1 : (angle == 1.5708 ? 0 : -0));
  double _sin(double angle) => angle == 1.5708 ? 1 : (angle == 4.7124 ? -1 : 0);

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}