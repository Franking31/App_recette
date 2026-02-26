import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFD4522A); // Terracotta profond
  static const Color primaryLigth = Color(0xFFD4522A); // Terracotta profond
  static const Color secondary = Color(0xFFFFF8F0); // Crème ivoire
  static const Color background = Color(0xFFF8F3EE); // Parchemin doux
  static const Color surface = Color(0xFFFFFFFF); // Blanc pur
   static const Color textDark    = Color(0xFF1A1208); // Brun très foncé
  static const Color textMedium  = Color(0xFF5C4A32); // Brun moyen
  static const Color textLight   = Color(0xFF9E8E7A); // Brun clair
  static const Color accent      = Color(0xFFE8B84B); // Or chaleureux
  static const Color accentGreen = Color(0xFF5A8A5E); // Vert herbe
  static const Color accentBlue  = Color(0xFF4A7FA5); // Bleu ardoise
  static const Color cardShadow  = Color(0x18000000);
  static const Color divider     = Color(0xFFEDE3D8);

  // ── Couleurs dark ─────────────────────────
  static const Color darkBackground = Color(0xFF1A1208);
  static const Color darkSurface    = Color(0xFF2A1F12);
  static const Color darkSurfaceAlt = Color(0xFF332616);
  static const Color darkTextDark   = Color(0xFFF8F0E3);
  static const Color darkTextLight  = Color(0xFF8A7A66);
  static const Color darkDivider    = Color(0xFF3A2D1E);

  static const LinearGradient primaryGradient = LinearGradient(
    colors:[Color(0xFFD4522A), Color(0xFFF07A50)], 
    begin: Alignment.topLeft,
    end: Alignment.bottomRight, 
    );

    static const LinearGradient goldGradient =  LinearGradient(
      colors: [Color(0xFFE8BB4B), Color(0xFFF5D07A)], 
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      ); 

      static const LinearGradient warmGradient = LinearGradient(
        colors: [Color(0xFFF8F3EE), Color(0xFFFDF6ED)], 
        begin: Alignment.topCenter,
        end: Alignment.bottomRight,
        ); 

      // ── Catégories couleurs ───────────────────
    static const Map<String, Color> categoryColors = {
      'Pâtes'     : Color(0xFFD4522A),
      'Dessert'   : Color(0xFFE8B84B),
      'Viande'    : Color(0xFF8B3A2A),
      'Soupe'     : Color(0xFF4A7FA5),
      'Petit-déj' : Color(0xFF5A8A5E),
      'Végé'      : Color(0xFF5A8A5E),
      'Poisson'   : Color(0xFF4A7FA5),
    };

    static Color categoryColor(String? category){
      if (category == null) return primary; 
      for (final entry in categoryColors.entries){
        if (category.contains(entry.key)) return entry.value;
      }
      return primary;
    }
        
}