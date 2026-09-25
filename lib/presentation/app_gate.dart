import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../logic/security.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/pin_screens.dart';

/// Choisit l'écran de démarrage : présentation (premier lancement), écran de
/// verrouillage (PIN actif) ou accueil. Reverrouille l'application après
/// un moment en arrière-plan. Sans box `settings` (tests), va direct à l'accueil.
class AppGate extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;

  const AppGate({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<AppGate> with WidgetsBindingObserver {
  static const _relockAfter = Duration(seconds: 30);

  Box<String>? get _settings =>
      Hive.isBoxOpen('settings') ? Hive.box<String>('settings') : null;

  late bool _onboarded;
  late bool _locked;
  DateTime? _pausedAt;

  @override
  void initState() {
    super.initState();
    _onboarded = _settings == null || _settings!.get('onboarded') == '1';
    _locked = Security.pinEnabled;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) _pausedAt = DateTime.now();
    if (state == AppLifecycleState.resumed) {
      final away = _pausedAt == null
          ? Duration.zero
          : DateTime.now().difference(_pausedAt!);
      _pausedAt = null;
      if (Security.pinEnabled && away > _relockAfter) {
        setState(() => _locked = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_onboarded) {
      return OnboardingScreen(onFinished: () {
        _settings?.put('onboarded', '1');
        setState(() => _onboarded = true);
      });
    }
    if (_locked && Security.pinEnabled) {
      return LockScreen(onUnlocked: () => setState(() => _locked = false));
    }
    return HomeScreen(
      isDarkMode: widget.isDarkMode,
      onThemeChanged: widget.onThemeChanged,
    );
  }
}
