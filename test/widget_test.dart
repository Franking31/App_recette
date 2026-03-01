import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frank_recette/app.dart';

void main() {
  group('Counter App Tests', () {
    testWidgets('Counter increments when tapping the button', (WidgetTester tester) async {
      await tester.pumpWidget(const App(showOnboarding: false));

      // Vérifiez que le compteur commence à 0
      expect(find.text('0'), findsOneWidget);
      expect(find.text('1'), findsNothing, reason: 'Le compteur ne doit pas commencer à 1');

      // Tap sur le bouton +
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      // Vérifiez que le compteur s'est incrémenté
      expect(find.text('0'), findsNothing);
      expect(find.text('1'), findsOneWidget, reason: 'Le compteur devrait être incrémenté à 1');
    });
  });
}