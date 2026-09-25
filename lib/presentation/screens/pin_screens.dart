import 'package:flutter/material.dart';

import '../../logic/security.dart';
import '../brand.dart';

/// Pavé numérique avec pastilles de saisie.
///
/// [onCompleted] reçoit le code complet et renvoie un message d'erreur à
/// afficher (le pavé se vide), ou `null` si tout va bien.
class PinPad extends StatefulWidget {
  final String title;
  final String? subtitle;
  final Future<String?> Function(String pin) onCompleted;
  final bool enabled;

  /// Touche en bas à gauche (ex. bouton d'empreinte digitale).
  final Widget? leading;

  const PinPad({
    super.key,
    required this.title,
    required this.onCompleted,
    this.subtitle,
    this.enabled = true,
    this.leading,
  });

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> {
  String _pin = '';
  String? _error;
  bool _busy = false;

  Future<void> _digit(String digit) async {
    if (!widget.enabled || _busy || _pin.length >= Security.pinLength) return;
    setState(() {
      _pin += digit;
      _error = null;
    });
    if (_pin.length < Security.pinLength) return;
    _busy = true;
    final error = await widget.onCompleted(_pin);
    if (!mounted) return;
    setState(() {
      _pin = '';
      _error = error;
      _busy = false;
    });
  }

  void _delete() {
    if (_pin.isEmpty || _busy) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Widget _key(Widget child, VoidCallback? onTap, String label) => Semantics(
        button: true,
        label: label,
        child: SizedBox(
          width: 72,
          height: 72,
          child: Material(
            color: onTap == null ? Colors.transparent : brandCard,
            shape: const CircleBorder(
              side: BorderSide(color: brandCardBorder),
            ),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: Center(child: child),
            ),
          ),
        ),
      );

  Widget _digitKey(String d) => _key(
        Text(d,
            style: const TextStyle(
                fontSize: 26, fontWeight: FontWeight.w600, color: Colors.white)),
        () => _digit(d),
        d,
      );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(widget.title,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800)),
        if (widget.subtitle != null) ...[
          const SizedBox(height: 6),
          Text(widget.subtitle!, textAlign: TextAlign.center),
        ],
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < Security.pinLength; i++)
              Container(
                width: 14,
                height: 14,
                margin: const EdgeInsets.symmetric(horizontal: 7),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < _pin.length ? brandBlue : Colors.transparent,
                  border: Border.all(
                      color: i < _pin.length ? brandBlue : scheme.outline,
                      width: 2),
                ),
              ),
          ],
        ),
        SizedBox(
          height: 32,
          child: Center(
            child: Text(_error ?? '',
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.error)),
          ),
        ),
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final d in row)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: _digitKey(d),
                  ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: SizedBox(
                    width: 72, height: 72, child: Center(child: widget.leading)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _digitKey('0'),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _key(
                  const Icon(Icons.backspace_outlined, color: Colors.white),
                  _delete,
                  'Effacer',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Écran affiché au lancement (et après un moment en arrière-plan) quand un
/// code PIN est actif.
class LockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;

  const LockScreen({super.key, required this.onUnlocked});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  static const _maxFailures = 5;
  static const _penalty = Duration(seconds: 30);

  // ponytail: le compteur d'échecs est en mémoire, il repart de zéro au
  // redémarrage de l'application ; à persister si on veut bloquer plus fort.
  var _failures = 0;
  DateTime? _lockedUntil;

  @override
  void initState() {
    super.initState();
    if (Security.biometricEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _biometric());
    }
  }

  Future<void> _biometric() async {
    final ok =
        await Security.authenticateBiometric('Déverrouillez DevBudget');
    if (ok && mounted) widget.onUnlocked();
  }

  Future<String?> _verify(String pin) async {
    final until = _lockedUntil;
    if (until != null && DateTime.now().isBefore(until)) {
      return 'Trop d’essais. Réessayez dans quelques secondes.';
    }
    if (await Security.verifyPin(pin)) {
      widget.onUnlocked();
      return null;
    }
    _failures++;
    if (_failures >= _maxFailures) {
      _failures = 0;
      _lockedUntil = DateTime.now().add(_penalty);
      return 'Trop d’essais. Réessayez dans 30 secondes.';
    }
    return 'Code incorrect (${_maxFailures - _failures} essai(s) restant(s))';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: PinPad(
                title: 'Entrez votre code',
                subtitle: 'DevBudget est verrouillé',
                onCompleted: _verify,
                leading: Security.biometricEnabled
                    ? IconButton(
                        tooltip: 'Empreinte digitale',
                        iconSize: 34,
                        color: brandBlue,
                        onPressed: _biometric,
                        icon: const Icon(Icons.fingerprint),
                      )
                    : null,
              ),
            ),
          ),
        ),
      );
}

/// Création d'un code PIN (saisie + confirmation), puis proposition
/// d'activer l'empreinte digitale. Se ferme avec `true` si le PIN est créé.
class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  String? _first;

  Future<String?> _onPin(String pin) async {
    if (_first == null) {
      setState(() => _first = pin);
      return null;
    }
    if (pin != _first) {
      setState(() => _first = null);
      return 'Les codes ne correspondent pas. Recommencez.';
    }
    await Security.setPin(pin);
    if (!mounted) return null;
    await _offerBiometric();
    if (mounted) Navigator.pop(context, true);
    return null;
  }

  Future<void> _offerBiometric() async {
    if (!await Security.biometricAvailable() || !mounted) return;
    final wanted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.fingerprint, size: 40, color: brandBlue),
        title: const Text('Activer l’empreinte digitale ?'),
        content: const Text(
            'Déverrouillez DevBudget d’un simple toucher. Le code PIN reste '
            'utilisable à tout moment.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Plus tard'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Activer'),
          ),
        ],
      ),
    );
    if (wanted != true) return;
    final ok = await Security.authenticateBiometric(
        'Confirmez votre empreinte pour l’activer');
    await Security.setBiometric(ok);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: PinPad(
                title: _first == null
                    ? 'Créez votre code PIN'
                    : 'Confirmez votre code',
                subtitle: '${Security.pinLength} chiffres',
                onCompleted: _onPin,
              ),
            ),
          ),
        ),
      );
}

/// Demande le code PIN actuel avant une action sensible. `true` si correct.
Future<bool> confirmPin(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => Dialog(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: PinPad(
            title: 'Code actuel',
            onCompleted: (pin) async {
              if (await Security.verifyPin(pin)) {
                if (dialogContext.mounted) Navigator.pop(dialogContext, true);
                return null;
              }
              return 'Code incorrect';
            },
          ),
        ),
      ),
    ),
  );
  return ok ?? false;
}
