import 'package:flutter/material.dart';

import '../../logic/notifications.dart';
import '../../logic/security.dart';
import '../screens/account_screen.dart';
import '../screens/pin_screens.dart';

/// Réglages de sécurité : code PIN, empreinte digitale, alertes de budget.
Future<void> showSecuritySheet(BuildContext context) {
  Future<void> setupPin(BuildContext context) => Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const PinSetupScreen()),
      );

  return showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setState) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Sécurité',
                    style: Theme.of(context).textTheme.titleLarge),
              ),
              ListTile(
                leading: const Icon(Icons.cloud_sync_outlined),
                title: const Text('Compte et synchronisation'),
                subtitle: const Text('Sauvegarde et multi-appareils'),
                onTap: () => Navigator.push<void>(
                  context,
                  MaterialPageRoute(builder: (_) => const AccountScreen()),
                ),
              ),
              if (!Security.pinEnabled)
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: const Text('Créer un code PIN'),
                  subtitle: const Text('Verrouille l’application au lancement'),
                  onTap: () async {
                    await setupPin(context);
                    setState(() {});
                  },
                )
              else ...[
                FutureBuilder<bool>(
                  future: Security.biometricAvailable(),
                  builder: (context, snapshot) => snapshot.data == true
                      ? SwitchListTile(
                          secondary: const Icon(Icons.fingerprint),
                          title: const Text('Empreinte digitale'),
                          value: Security.biometricEnabled,
                          onChanged: (on) async {
                            final ok = on &&
                                await Security.authenticateBiometric(
                                    'Confirmez votre empreinte pour l’activer');
                            await Security.setBiometric(ok);
                            setState(() {});
                          },
                        )
                      : const SizedBox.shrink(),
                ),
                ListTile(
                  leading: const Icon(Icons.password),
                  title: const Text('Changer le code PIN'),
                  onTap: () async {
                    if (!await confirmPin(context) || !context.mounted) return;
                    await setupPin(context);
                    setState(() {});
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.lock_open_outlined),
                  title: const Text('Désactiver le verrouillage'),
                  onTap: () async {
                    if (!await confirmPin(context)) return;
                    await Security.removePin();
                    setState(() {});
                  },
                ),
              ],
              SwitchListTile(
                secondary: const Icon(Icons.notifications_active_outlined),
                title: const Text('Alertes de budget'),
                subtitle: const Text('Notification à 80 % et au dépassement'),
                value: notificationsEnabled,
                onChanged: (on) async {
                  if (on) {
                    await requestNotificationPermission();
                  } else {
                    await setNotificationsEnabled(false);
                  }
                  setState(() {});
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    ),
  );
}
