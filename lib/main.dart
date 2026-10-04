import 'package:flutter/material.dart';
import 'data/statistics_store.dart';
import 'services/game_save_service.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load only the device-wide state (Teacher Mode content + quiz source) at
  // startup. No player's progress is loaded yet — the login gate decides which
  // profile to open and loads it (GameSaveService.login).
  await GameSaveService.instance.loadDeviceData();
  // The app is now in the foreground; start the play-time session clock.
  StatisticsStore.instance.startSession();
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
    // When the app returns to the foreground, resume the play-time clock.
    if (state == AppLifecycleState.resumed) {
      StatisticsStore.instance.startSession();
    }
    // When the app is backgrounded, loses focus or is being torn down, stop
    // the play-time clock and write any queued changes immediately instead of
    // waiting for the debounce — the explorer never loses the latest progress.
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      StatisticsStore.instance.endSession();
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