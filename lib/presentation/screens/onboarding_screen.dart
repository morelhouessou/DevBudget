import 'package:flutter/material.dart';

import '../../logic/notifications.dart';
import '../brand.dart';
import 'pin_screens.dart';

/// Présentation au premier lancement : 4 pages, dont les autorisations
/// (page 3) puis la mise en place de la sécurité (page 4, la dernière).
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinished;

  const OnboardingScreen({super.key, required this.onFinished});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _pageCount = 4;
  final _controller = PageController();
  var _page = 0;
  bool? _notificationsGranted;

  void _goTo(int page) => _controller.animateToPage(page,
      duration: const Duration(milliseconds: 300), curve: Curves.easeOut);

  Future<void> _askNotifications() async {
    final granted = await requestNotificationPermission();
    if (mounted) setState(() => _notificationsGranted = granted);
  }

  Future<void> _createPin() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const PinSetupScreen()),
    );
    if (created == true) widget.onFinished();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final last = _page == _pageCount - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: last ? widget.onFinished : () => _goTo(_pageCount - 1),
                child: Text(last ? '' : 'Passer'),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (page) => setState(() => _page = page),
                children: [
                  const _Page(
                    icon: Icons.account_balance_wallet_rounded,
                    title: 'Votre argent, magnifiquement sous contrôle.',
                    text: 'Suivez vos dépenses, vos revenus et vos budgets '
                        'au même endroit, en toute simplicité.',
                    chips: ['Budgets intelligents', 'Multi-devises', 'Équipe'],
                  ),
                  const _Page(
                    icon: Icons.pie_chart_rounded,
                    title: 'Des budgets qui vous préviennent.',
                    text: 'Fixez une limite par catégorie ou par mois. '
                        'DevBudget vous alerte à 80 % et quand elle est dépassée.',
                    chips: ['Par catégorie', 'Mensuels', 'Alerte à 80 %'],
                  ),
                  _PermissionsPage(
                    notificationsGranted: _notificationsGranted,
                    onAskNotifications: _askNotifications,
                  ),
                  _SecurityPage(
                    onCreatePin: _createPin,
                    onLater: widget.onFinished,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < _pageCount; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: i == _page ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _page
                                ? brandBlue
                                : Theme.of(context).colorScheme.outlineVariant,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                    ],
                  ),
                  if (!last) ...[
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(54),
                          backgroundColor: brandBlue,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _goTo(_page + 1),
                        child: Text(_page == 0 ? 'Commencer' : 'Suivant'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bloc illustration : carte dégradée avec une grande icône.
class _Hero extends StatelessWidget {
  final IconData icon;

  const _Hero(this.icon);

  @override
  Widget build(BuildContext context) => Container(
        height: 190,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: heroGradient,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: brandBlue.withValues(alpha: 0.35),
              blurRadius: 30,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Icon(icon, size: 84, color: Colors.white),
      );
}

class _Page extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  final List<String> chips;

  const _Page({
    required this.icon,
    required this.title,
    required this.text,
    required this.chips,
  });

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Hero(icon),
            const SizedBox(height: 32),
            Text(title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                      height: 1.15,
                    )),
            const SizedBox(height: 12),
            Text(text, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final c in chips) Chip(label: Text(c))],
            ),
          ],
        ),
      );
}

/// Ce que l'application utilise réellement, sans rien demander d'autre.
class _PermissionsPage extends StatelessWidget {
  final bool? notificationsGranted;
  final VoidCallback onAskNotifications;

  const _PermissionsPage({
    required this.notificationsGranted,
    required this.onAskNotifications,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Hero(Icons.verified_user_rounded),
          const SizedBox(height: 28),
          Text('Vos autorisations',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                  )),
          const SizedBox(height: 8),
          const Text('DevBudget n’utilise que ce qui suit. Rien d’autre : '
              'ni contacts, ni position, ni photos.'),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications_active_outlined),
                  title: const Text('Notifications'),
                  subtitle: const Text(
                      'Alertes quand un budget atteint 80 % ou est dépassé.'),
                  trailing: notificationsGranted == true
                      ? Icon(Icons.check_circle, color: Colors.green.shade600)
                      : FilledButton.tonal(
                          onPressed: onAskNotifications,
                          child: const Text('Autoriser'),
                        ),
                ),
                if (notificationsGranted == false)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Text(
                      'Non accordées : vous pourrez les activer plus tard '
                      'dans la section Sécurité.',
                      style: TextStyle(color: scheme.error),
                    ),
                  ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.wifi_rounded),
                  title: Text('Internet'),
                  subtitle: Text('Taux de change à jour. Aucune demande.'),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.fingerprint),
                  title: Text('Empreinte digitale'),
                  subtitle: Text('Proposée à l’étape suivante pour verrouiller.'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityPage extends StatelessWidget {
  final VoidCallback onCreatePin;
  final VoidCallback onLater;

  const _SecurityPage({required this.onCreatePin, required this.onLater});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Hero(Icons.fingerprint),
            const SizedBox(height: 28),
            Text('Protégez vos finances.',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                    )),
            const SizedBox(height: 12),
            const Text('Créez un code PIN à 6 chiffres, puis activez '
                'l’empreinte digitale pour déverrouiller d’un toucher.'),
            const SizedBox(height: 28),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                backgroundColor: brandBlue,
                foregroundColor: Colors.white,
              ),
              onPressed: onCreatePin,
              icon: const Icon(Icons.lock_outline),
              label: const Text('Créer mon code PIN'),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: onLater,
                child: const Text('Plus tard'),
              ),
            ),
          ],
        ),
      );
}
