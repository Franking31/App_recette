import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'core/services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.init();

  // Vérifie si c'est le 1er lancement
  final prefs = await SharedPreferences.getInstance();
  final showOnboarding = !(prefs.getBool('onboarding_done') ?? false);
  if (showOnboarding) await prefs.setBool('onboarding_done', true);

  runApp(App(showOnboarding: showOnboarding));
}