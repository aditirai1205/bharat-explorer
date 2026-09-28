import 'package:flutter/material.dart';
import 'services/game_save_service.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // One load call populates the whole game (progress, player profile, teacher
  // content) — all persistence lives in GameSaveService.
  await GameSaveService.instance.loadGame();
  runApp(const BharatExplorerApp());
}

/// Root widget. Also keeps an eye on the app lifecycle so that any pending
/// (debounced) auto-save is flushed to disk the instant the app is
/// backgrounded or closed — the explorer never loses the latest progress.
class BharatExplorerApp extends StatefulWidget {
  const BharatExplorerApp({super.key});

  @override
  State<BharatExplorerApp> createState() => _BharatExplorerAppState();
}

class _BharatExplorerAppState extends State<BharatExplorerApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When the app is backgrounded, loses focus or is being torn down, write
    // any queued changes immediately instead of waiting for the debounce.
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      GameSaveService.instance.flush();
    }
  }

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