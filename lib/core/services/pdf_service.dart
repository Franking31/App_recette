// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;
import '../../../features/recipes/data/models/recipe.dart';

// ═══════════════════════════════════════════
//  PDF EXPORT SERVICE — ForkAI
//  Génère une page HTML stylée et ouvre
//  l'aperçu avant impression du navigateur.
//  Compatible Flutter Web uniquement.
// ═══════════════════════════════════════════

class PdfService {
  /// Ouvre l'aperçu avant impression avec la recette complète.
  /// [nutrition] : données nutritionnelles optionnelles (Map depuis NutritionData)
  /// [rating]    : note moyenne optionnelle
  static void printRecipe({
    required Recipe recipe,
    Map<String, dynamic>? nutrition,
    double? rating,
    int? ratingCount,
  }) {
    final htmlContent = _buildHtml(
      recipe: recipe,
      nutrition: nutrition,
      rating: rating,
      ratingCount: ratingCount,
    );

    // Ouvre une nouvelle fenêtre et y injecte le HTML via JS
    js.context.callMethod('eval', ['''
      (function() {
        var w = window.open('', '_blank');
        w.document.open();
        w.document.write(${_jsString(htmlContent)});
        w.document.close();
        setTimeout(function() { w.print(); }, 800);
      })();
    ''']);
  }

  // Échappe le HTML pour l'injecter dans une chaîne JS
  static String _jsString(String html) {
    return '"${html
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '')
        .replaceAll("'", "\\'")}"';
  }

  // ── Génération HTML ──────────────────────
  static String _buildHtml({
    required Recipe recipe,
    Map<String, dynamic>? nutrition,
    double? rating,
    int? ratingCount,
  }) {
    final hasImage = recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty;
    final hasNutrition = nutrition != null;
    final hasRating = rating != null && rating > 0;

    // Étoiles rating
    String starsHtml = '';
    if (hasRating) {
      final fullStars = rating.floor();
      final hasHalf = (rating - fullStars) >= 0.5;
      starsHtml = List.generate(5, (i) {
        if (i < fullStars) return '★';
        if (i == fullStars && hasHalf) return '½';
        return '☆';
      }).join('');
    }

    // Ingrédients HTML
    final ingredientsHtml = recipe.ingredients
        .map((ing) => '<li>$ing</li>')
        .join('\n');

    // Étapes HTML
    final stepsHtml = recipe.steps
        .asMap()
        .entries
        .map((e) => '''
          <div class="step">
            <div class="step-num">${e.key + 1}</div>
            <div class="step-text">${e.value}</div>
          </div>''')
        .join('\n');

    // Nutrition HTML
    String nutritionHtml = '';
    if (hasNutrition) {
      final per = nutrition['perPortion'] ?? nutrition['perRecipe'] ?? {};
      final score = nutrition['score'];
      final scoreLabel = nutrition['scoreLabel'] ?? '';
      final scoreColor = _nutritionScoreColor(nutrition['scoreColor']);
      final strengths = (nutrition['strengths'] as List?)?.cast<String>() ?? [];
      final improvements = (nutrition['improvements'] as List?)?.cast<String>() ?? [];

      nutritionHtml = '''
        <div class="section nutrition-section">
          <h2>📊 Informations Nutritionnelles</h2>
          <div class="nutrition-grid">
            ${_nutriCell('Calories', '${per['calories'] ?? '-'}', 'kcal')}
            ${_nutriCell('Protéines', '${per['proteins'] ?? '-'}', 'g')}
            ${_nutriCell('Glucides', '${per['carbs'] ?? '-'}', 'g')}
            ${_nutriCell('Lipides', '${per['fats'] ?? '-'}', 'g')}
            ${_nutriCell('Fibres', '${per['fiber'] ?? '-'}', 'g')}
            ${_nutriCell('Sucres', '${per['sugar'] ?? '-'}', 'g')}
          </div>
          ${score != null ? '''
          <div class="score-badge" style="border-color: $scoreColor; color: $scoreColor;">
            Score nutritionnel : $score/10 — $scoreLabel
          </div>''' : ''}
          ${strengths.isNotEmpty ? '''
          <div class="nutri-list">
            <strong>✅ Points forts :</strong> ${strengths.join(' · ')}
          </div>''' : ''}
          ${improvements.isNotEmpty ? '''
          <div class="nutri-list">
            <strong>💡 À améliorer :</strong> ${improvements.join(' · ')}
          </div>''' : ''}
        </div>''';
    }

    // Rating HTML
    String ratingHtml = '';
    if (hasRating) {
      ratingHtml = '''
        <div class="rating-block">
          <span class="stars">$starsHtml</span>
          <span class="rating-val">${rating.toStringAsFixed(1)}/5</span>
          ${ratingCount != null ? '<span class="rating-count">($ratingCount avis)</span>' : ''}
        </div>''';
    }

    return '''<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${recipe.title} — ForkAI</title>
  <style>
    @import url('https://fonts.googleapis.com/css2?family=Nunito:wght@400;600;700;800;900&display=swap');

    * { box-sizing: border-box; margin: 0; padding: 0; }

    body {
      font-family: 'Nunito', sans-serif;
      background: #fff;
      color: #1A1208;
      max-width: 800px;
      margin: 0 auto;
      padding: 0;
    }

    /* ── Header ── */
    .header {
      background: linear-gradient(135deg, #D4522A, #F07A50);
      color: white;
      padding: 32px 40px 28px;
      position: relative;
      overflow: hidden;
    }
    .header::after {
      content: '';
      position: absolute;
      bottom: -30px; right: -30px;
      width: 160px; height: 160px;
      background: rgba(255,255,255,0.08);
      border-radius: 50%;
    }
    .brand {
      font-size: 13px;
      font-weight: 700;
      letter-spacing: 2px;
      opacity: 0.8;
      text-transform: uppercase;
      margin-bottom: 6px;
    }
    .recipe-title {
      font-size: 32px;
      font-weight: 900;
      line-height: 1.1;
      margin-bottom: 10px;
    }
    .category-badge {
      display: inline-block;
      background: rgba(255,255,255,0.2);
      padding: 4px 12px;
      border-radius: 20px;
      font-size: 12px;
      font-weight: 700;
      margin-bottom: 12px;
    }
    .description {
      font-size: 14px;
      opacity: 0.85;
      line-height: 1.5;
      max-width: 500px;
    }

    /* ── Infos rapides ── */
    .quick-info {
      display: flex;
      gap: 16px;
      padding: 20px 40px;
      background: #FFF8F0;
      border-bottom: 1px solid #EDE3D8;
    }
    .info-chip {
      display: flex;
      align-items: center;
      gap: 6px;
      background: white;
      border: 1px solid #EDE3D8;
      border-radius: 10px;
      padding: 8px 14px;
      font-size: 13px;
      font-weight: 700;
      color: #1A1208;
    }
    .info-chip .icon { font-size: 16px; }

    /* ── Rating ── */
    .rating-block {
      display: flex;
      align-items: center;
      gap: 8px;
      padding: 12px 40px;
      background: #FDF6ED;
      border-bottom: 1px solid #EDE3D8;
    }
    .stars { color: #E8B84B; font-size: 20px; letter-spacing: 2px; }
    .rating-val { font-weight: 800; font-size: 15px; color: #1A1208; }
    .rating-count { font-size: 13px; color: #9E8E7A; }

    /* ── Image ── */
    .recipe-image {
      width: 100%;
      height: 280px;
      object-fit: cover;
      display: block;
    }

    /* ── Sections ── */
    .section {
      padding: 28px 40px;
      border-bottom: 1px solid #EDE3D8;
    }
    .section:last-child { border-bottom: none; }
    .section h2 {
      font-size: 18px;
      font-weight: 900;
      color: #1A1208;
      margin-bottom: 16px;
    }

    /* ── Ingrédients ── */
    .ingredients-list {
      list-style: none;
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 8px;
    }
    .ingredients-list li {
      display: flex;
      align-items: flex-start;
      gap: 8px;
      font-size: 14px;
      color: #1A1208;
      line-height: 1.4;
    }
    .ingredients-list li::before {
      content: '';
      flex-shrink: 0;
      width: 8px; height: 8px;
      border-radius: 50%;
      background: #D4522A;
      margin-top: 5px;
    }

    /* ── Étapes ── */
    .step {
      display: flex;
      gap: 14px;
      margin-bottom: 14px;
      align-items: flex-start;
    }
    .step-num {
      flex-shrink: 0;
      width: 28px; height: 28px;
      background: #D4522A;
      color: white;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 12px;
      font-weight: 800;
    }
    .step-text {
      font-size: 14px;
      color: #1A1208;
      line-height: 1.6;
      padding-top: 4px;
    }

    /* ── Nutrition ── */
    .nutrition-section { background: #FAFAFA; }
    .nutrition-grid {
      display: grid;
      grid-template-columns: repeat(3, 1fr);
      gap: 10px;
      margin-bottom: 16px;
    }
    .nutri-cell {
      background: white;
      border: 1px solid #EDE3D8;
      border-radius: 10px;
      padding: 12px;
      text-align: center;
    }
    .nutri-cell .val {
      font-size: 20px;
      font-weight: 900;
      color: #D4522A;
    }
    .nutri-cell .unit {
      font-size: 11px;
      color: #9E8E7A;
      margin-left: 2px;
    }
    .nutri-cell .label {
      font-size: 11px;
      color: #5C4A32;
      font-weight: 700;
      margin-top: 2px;
    }
    .score-badge {
      display: inline-block;
      border: 2px solid;
      border-radius: 8px;
      padding: 6px 14px;
      font-weight: 800;
      font-size: 13px;
      margin-bottom: 12px;
    }
    .nutri-list {
      font-size: 13px;
      color: #5C4A32;
      line-height: 1.6;
      margin-top: 8px;
    }

    /* ── Footer ── */
    .footer {
      text-align: center;
      padding: 20px;
      font-size: 12px;
      color: #9E8E7A;
      background: #F8F3EE;
    }
    .footer strong { color: #D4522A; }

    /* ── Print styles ── */
    @media print {
      body { max-width: 100%; }
      .header { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
      .step-num { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
      .ingredients-list li::before { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
      .nutri-cell .val { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
      @page { margin: 0; size: A4; }
    }
  </style>
</head>
<body>

  <!-- Header -->
  <div class="header">
    <div class="brand">🍴 ForkAI — Recette</div>
    <div class="recipe-title">${recipe.title}</div>
    ${recipe.category != null ? '<div class="category-badge">${recipe.category}</div>' : ''}
    <div class="description">${recipe.description}</div>
  </div>

  <!-- Infos rapides -->
  <div class="quick-info">
    <div class="info-chip"><span class="icon">⏱️</span> ${recipe.durationMinutes} min</div>
    <div class="info-chip"><span class="icon">👥</span> ${recipe.servings} personnes</div>
    <div class="info-chip"><span class="icon">📋</span> ${recipe.ingredients.length} ingrédients</div>
    <div class="info-chip"><span class="icon">👨‍🍳</span> ${recipe.steps.length} étapes</div>
  </div>

  <!-- Rating -->
  $ratingHtml

  <!-- Image -->
  ${hasImage ? '<img class="recipe-image" src="${recipe.imageUrl}" alt="${recipe.title}" crossorigin="anonymous">' : ''}

  <!-- Ingrédients -->
  <div class="section">
    <h2>🛒 Ingrédients</h2>
    <ul class="ingredients-list">
      $ingredientsHtml
    </ul>
  </div>

  <!-- Étapes -->
  <div class="section">
    <h2>👨‍🍳 Préparation</h2>
    $stepsHtml
  </div>

  <!-- Nutrition -->
  $nutritionHtml

  <!-- Footer -->
  <div class="footer">
    Recette générée par <strong>ForkAI</strong> · Propulsé par Gemini & Groq ·
    Imprimé le ${_frenchDate()}
  </div>

</body>
</html>''';
  }

  static String _nutriCell(String label, String val, String unit) => '''
    <div class="nutri-cell">
      <div><span class="val">$val</span><span class="unit">$unit</span></div>
      <div class="label">$label</div>
    </div>''';

  static String _nutritionScoreColor(String? color) {
    switch (color) {
      case 'green': return '#5A8A5E';
      case 'orange': return '#E8B84B';
      case 'red': return '#D4522A';
      default: return '#5A8A5E';
    }
  }

  static String _frenchDate() {
    final now = DateTime.now();
    const months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }
}