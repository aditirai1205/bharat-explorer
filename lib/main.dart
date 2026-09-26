import 'package:flutter/material.dart';
import 'data/player_profile.dart';
import 'data/progress_store.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ProgressStore.load();
  await PlayerProfile.load();
  runApp(const BharatExplorerApp());
}

class BharatExplorerApp extends StatelessWidget {
  const BharatExplorerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bharat Explorer',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF071A30),
        fontFamilyFallback: const ['Segoe UI', 'Roboto'],
      ),
      home: const SplashScreen(),
    );
  }
}