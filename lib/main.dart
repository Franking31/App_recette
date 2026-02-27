import 'package:flutter/material.dart';
import 'app.dart';
import 'core/services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.init(); // Charge la session sauvegardée
  runApp(const App());
}