import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../logic/sync/sync_service.dart';
import '../brand.dart';

/// Connexion au compte DevBudget (Supabase) et synchronisation manuelle.
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _sync = SyncService.instance;
  final _email = TextEditingController();
  final _password = TextEditingController();
  StreamSubscription<AuthState>? _authSub;
  var _busy = false;
  String? _error;
  String? _info;

  @override
  void initState() {
    super.initState();
    if (_sync.available) {
      _authSub = Supabase.instance.client.auth.onAuthStateChange
          .listen((_) => mounted ? setState(() {}) : null, onError: (_) {});
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  bool get _validInput =>
      _email.text.contains('@') && _password.text.length >= 8;

  Future<void> _submit({required bool create}) async {
    if (!_validInput) {
      setState(() {
        _error = 'Saisissez un e-mail valide et un mot de passe d’au moins 8 caractères.';
        _info = null;
      });
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    String? error;
    String? info;
    if (create) {
      (error, info) = await _sync.signUp(_email.text, _password.text);
    } else {
      error = await _sync.signIn(_email.text, _password.text);
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error;
      _info = info;
      if (error == null) _password.clear();
    });
  }

  String _lastSyncLabel() {
    final iso = _sync.lastSync;
    if (iso == null) return 'Jamais';
    return DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(iso));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Compte et synchronisation')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (!_sync.available)
              const Card(
                child: ListTile(
                  leading: Icon(Icons.cloud_off_outlined),
                  title: Text('Service indisponible'),
                  subtitle: Text(
                      'La connexion au serveur n’a pas pu être initialisée. '
                      'L’application fonctionne en local.'),
                ),
              )
            else if (_sync.signedIn)
              _signedIn(context)
            else
              _signedOut(context),
          ],
        ),
      );

  Widget _signedOut(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Retrouvez vos données sur tous vos appareils.',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          const Text('Créez un compte ou connectez-vous : vos budgets, '
              'dépenses et membres sont sauvegardés et synchronisés.'),
          const SizedBox(height: 20),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(
              labelText: 'E-mail',
              prefixIcon: Icon(Icons.mail_outline),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: true,
            autofillHints: const [AutofillHints.password],
            decoration: const InputDecoration(
              labelText: 'Mot de passe (8 caractères minimum)',
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          if (_info != null) ...[
            const SizedBox(height: 12),
            Text(_info!),
          ],
          const SizedBox(height: 20),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: brandBlue,
              foregroundColor: Colors.white,
            ),
            onPressed: _busy ? null : () => _submit(create: false),
            child: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Se connecter'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52)),
            onPressed: _busy ? null : () => _submit(create: true),
            child: const Text('Créer un compte'),
          ),
        ],
      );

  Widget _signedIn(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person_outline)),
              title: Text(_sync.user?.email ?? 'Connecté'),
              subtitle: ValueListenableBuilder<bool>(
                valueListenable: _sync.syncing,
                builder: (_, syncing, __) => Text(syncing
                    ? 'Synchronisation en cours…'
                    : 'Dernière synchronisation : ${_lastSyncLabel()}'),
              ),
            ),
          ),
          ValueListenableBuilder<String>(
            valueListenable: _sync.message,
            builder: (_, message, __) => message.isEmpty
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(message),
                  ),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: brandBlue,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await _sync.sync();
              if (mounted) setState(() {});
            },
            icon: const Icon(Icons.sync),
            label: const Text('Synchroniser maintenant'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52)),
            onPressed: () async {
              await _sync.signOut();
              if (mounted) setState(() {});
            },
            icon: const Icon(Icons.logout),
            label: const Text('Se déconnecter'),
          ),
          const SizedBox(height: 16),
          Text(
            'Se déconnecter n’efface pas les données de cet appareil.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      );
}
