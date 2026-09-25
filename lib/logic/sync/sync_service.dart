import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/budget_model.dart';
import '../../data/models/expense_model.dart';
import '../../data/models/member_model.dart';

/// Projet Supabase de DevBudget.
const supabaseUrl = 'https://hoammgduaffcsqrhbbpu.supabase.co';

/// Clé publique (« anon ») : elle est faite pour être embarquée dans l'app.
/// Les données restent protégées par les règles d'accès (RLS) du serveur.
/// Ne JAMAIS mettre ici la clé `service_role`.
const supabasePublishableKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhvYW1tZ2R1YWZmY3NxcmhiYnB1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTAyODI1NTUsImV4cCI6MjEwNTg1ODU1NX0.VbgrjLNj56vjXU1oC1ytrMNyUAcoGKmvo35dvINrLdg';

// ---------------------------------------------------------------------------
// Conversions modèle local <-> ligne Supabase
// ---------------------------------------------------------------------------

Map<String, dynamic> expenseToRow(ExpenseModel e, String userId) => {
      'owner_id': userId,
      'id': e.id,
      'title': e.title,
      'amount': e.amount,
      'category': e.category,
      'date': e.date.toUtc().toIso8601String(),
      'member_id': e.memberId,
      'budget_id': e.budgetId,
      'is_income': e.isIncome,
      'currency': e.currency,
      'deleted': false,
    };

ExpenseModel expenseFromRow(Map<String, dynamic> r) => ExpenseModel(
      id: r['id'] as String,
      title: r['title'] as String,
      amount: (r['amount'] as num).toDouble(),
      category: r['category'] as String,
      date: DateTime.parse(r['date'] as String).toLocal(),
      memberId: r['member_id'] as String,
      budgetId: r['budget_id'] as String?,
      isIncome: r['is_income'] as bool,
      currency: r['currency'] as String?,
    );

Map<String, dynamic> budgetToRow(BudgetModel b, String userId) => {
      'owner_id': userId,
      'id': b.id,
      'name': b.name,
      'total_amount': b.totalAmount,
      'start_date': b.startDate.toUtc().toIso8601String(),
      'end_date': b.endDate.toUtc().toIso8601String(),
      'category': b.category,
      'recurring': b.recurring,
      'currency': b.currency,
      'member_ids': b.memberIds,
      'is_shared': b.isShared,
      'deleted': false,
    };

BudgetModel budgetFromRow(Map<String, dynamic> r) => BudgetModel(
      id: r['id'] as String,
      name: r['name'] as String,
      totalAmount: (r['total_amount'] as num).toDouble(),
      startDate: DateTime.parse(r['start_date'] as String).toLocal(),
      endDate: DateTime.parse(r['end_date'] as String).toLocal(),
      ownerId: r['owner_id'] as String,
      memberIds: List<String>.from(r['member_ids'] as List),
      isShared: r['is_shared'] as bool,
      category: r['category'] as String?,
      recurring: r['recurring'] as bool,
      currency: r['currency'] as String?,
    );

Map<String, dynamic> memberToRow(MemberModel m, String userId) => {
      'owner_id': userId,
      'id': m.id,
      'name': m.name,
      'role': m.role.name,
      'deleted': false,
    };

MemberModel memberFromRow(Map<String, dynamic> r) => MemberModel(
      id: r['id'] as String,
      name: r['name'] as String,
      role: MemberRole.values.byName(r['role'] as String),
    );

// ---------------------------------------------------------------------------
// File d'attente des modifications locales (stockée dans la box `settings`)
// ---------------------------------------------------------------------------

/// Mémorise les enregistrements créés, modifiés ou supprimés localement et
/// pas encore envoyés. Sans box `settings` (tests), ne fait rien.
class SyncOutbox {
  static const _prefix = 'dirty|';

  static Box<String>? get _box =>
      Hive.isBoxOpen('settings') ? Hive.box<String>('settings') : null;

  static void markUpsert(String table, String id) => _mark(table, id, 'upsert');

  static void markDelete(String table, String id) => _mark(table, id, 'delete');

  static void _mark(String table, String id, String op) {
    final box = _box;
    if (box == null) return;
    box.put('$_prefix$table|$id', op);
    SyncService.instance.schedule();
  }

  /// Modifications en attente pour [table] : identifiant -> `upsert`/`delete`.
  static Map<String, String> pending(String table) {
    final box = _box;
    if (box == null) return {};
    final start = '$_prefix$table|';
    return {
      for (final key in box.keys.whereType<String>())
        if (key.startsWith(start)) key.substring(start.length): box.get(key)!,
    };
  }

  static bool isDirty(String table, String id) =>
      _box?.containsKey('$_prefix$table|$id') ?? false;

  static Future<void> clear(String table, Iterable<String> ids) async {
    await _box?.deleteAll(ids.map((id) => '$_prefix$table|$id'));
  }
}

/// Une table synchronisée. Les types sont `dynamic` pour pouvoir traiter les
/// trois tables dans les mêmes boucles.
class _Table {
  final String name;
  final Box Function() box;
  final Map<String, dynamic> Function(dynamic, String) toRow;
  final dynamic Function(Map<String, dynamic>) fromRow;

  /// Le serveur refuse les montants <= 0 : on n'envoie pas les données
  /// invalides héritées d'anciennes versions.
  final bool Function(dynamic) isValid;

  const _Table(this.name, this.box, this.toRow, this.fromRow, this.isValid);
}

/// Synchronisation des données de l'utilisateur connecté entre ses appareils.
///
/// 1. envoie les modifications locales en attente ;
/// 2. récupère les changements du serveur depuis la dernière synchronisation.
///
/// Résolution des conflits : la dernière écriture gagne (l'heure est celle du
/// serveur). Une ligne modifiée localement et en attente d'envoi n'est pas
/// écrasée par la version distante.
// ponytail: le compte connecté peut changer sur un même appareil : les données
// locales sont alors envoyées vers le nouveau compte ; à isoler par compte si
// des appareils sont partagés.
class SyncService {
  static final instance = SyncService._();
  SyncService._();

  static const _pageSize = 1000;
  static const _cursorMargin = Duration(minutes: 2);

  final syncing = ValueNotifier<bool>(false);
  final message = ValueNotifier<String>('');

  /// Appelé quand des données distantes ont été écrites en local (pour
  /// rafraîchir l'interface).
  VoidCallback? onRemoteChanges;

  var _ready = false;
  var _again = false;
  Future<void>? _current;
  Timer? _timer;

  late final List<_Table> _tables = [
    _Table(
      'expenses',
      () => Hive.box<ExpenseModel>('expenses'),
      (e, userId) => expenseToRow(e as ExpenseModel, userId),
      expenseFromRow,
      (e) => (e as ExpenseModel).amount > 0,
    ),
    _Table(
      'budgets',
      () => Hive.box<BudgetModel>('budgets'),
      (b, userId) => budgetToRow(b as BudgetModel, userId),
      budgetFromRow,
      (b) => (b as BudgetModel).totalAmount > 0,
    ),
    _Table(
      'members',
      () => Hive.box<MemberModel>('members'),
      (m, userId) => memberToRow(m as MemberModel, userId),
      memberFromRow,
      (_) => true,
    ),
  ];

  Box<String> get _settings => Hive.box<String>('settings');

  /// Client injecté par les tests d'intégration (sans plugin Flutter).
  @visibleForTesting
  SupabaseClient? testClient;

  /// `true` si le client Supabase est initialisé.
  bool get available => _ready || testClient != null;

  SupabaseClient get _client => testClient ?? Supabase.instance.client;

  User? get user => available ? _client.auth.currentUser : null;

  bool get signedIn => user != null;

  String? get lastSync => _settings.get('last_sync');

  Future<void> init() async {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        publishableKey: supabasePublishableKey,
      );
      _ready = true;
    } catch (e) {
      // Hors-ligne au démarrage ou plateforme non prise en charge :
      // l'application reste utilisable en local.
      debugPrint('Supabase indisponible : $e');
    }
  }

  /// Programme une synchronisation dans quelques secondes (regroupe les
  /// modifications rapprochées).
  void schedule() {
    if (!signedIn) return;
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 3), sync);
  }

  /// Retourne un message d'erreur, ou `null` si la connexion a réussi.
  Future<String?> signIn(String email, String password) async {
    try {
      await _client.auth
          .signInWithPassword(email: email.trim(), password: password);
      unawaited(sync());
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (_) {
      return 'Connexion impossible. Vérifiez votre réseau.';
    }
  }

  /// Retourne `(erreur, information)` : un des deux est `null`.
  Future<(String?, String?)> signUp(String email, String password) async {
    try {
      final response =
          await _client.auth.signUp(email: email.trim(), password: password);
      if (response.session == null) {
        return (
          null,
          'Compte créé. Ouvrez le lien reçu par e-mail pour le confirmer, '
              'puis connectez-vous.'
        );
      }
      unawaited(sync());
      return (null, 'Compte créé et connecté.');
    } on AuthException catch (e) {
      return (e.message, null);
    } catch (_) {
      return ('Inscription impossible. Vérifiez votre réseau.', null);
    }
  }

  Future<void> signOut() async {
    _timer?.cancel();
    await _client.auth.signOut();
    message.value = '';
  }

  /// Synchronise maintenant. Un appel pendant une synchronisation en cours
  /// attend qu'elle se termine, puis une passe de plus rattrape les
  /// modifications survenues entre-temps.
  Future<void> sync() {
    if (!signedIn) return Future.value();
    if (_current != null) {
      _again = true;
      return _current!;
    }
    return _current = _run().whenComplete(() => _current = null);
  }

  Future<void> _run() async {
    do {
      _again = false;
      await _syncOnce();
    } while (_again && signedIn);
  }

  Future<void> _syncOnce() async {
    syncing.value = true;
    try {
      final userId = user!.id;
      if (_settings.get('sync_user') != userId) {
        // Première synchronisation de ce compte sur cet appareil : on envoie
        // tout ce qui existe déjà en local et on relit tout depuis le serveur.
        await _settings.put('sync_user', userId);
        await _settings.delete('sync_cursor');
        for (final t in _tables) {
          for (final key in t.box().keys) {
            SyncOutbox.markUpsert(t.name, key as String);
          }
        }
      }
      await _push(userId);
      final changed = await _pull();
      await _settings.put('last_sync', DateTime.now().toIso8601String());
      message.value = 'Synchronisé';
      if (changed) onRemoteChanges?.call();
    } catch (e) {
      message.value = 'Échec de la synchronisation : $e';
    } finally {
      syncing.value = false;
    }
  }

  Future<void> _push(String userId) async {
    for (final t in _tables) {
      final pending = SyncOutbox.pending(t.name);
      if (pending.isEmpty) continue;
      final box = t.box();
      final rows = <Map<String, dynamic>>[];
      final deletes = <String>[];
      for (final entry in pending.entries) {
        final record = entry.value == 'delete' ? null : box.get(entry.key);
        if (record == null) {
          deletes.add(entry.key);
        } else if (t.isValid(record)) {
          rows.add(t.toRow(record, userId));
        }
      }
      if (rows.isNotEmpty) {
        await _client.from(t.name).upsert(rows, onConflict: 'owner_id,id');
      }
      if (deletes.isNotEmpty) {
        await _client
            .from(t.name)
            .update({'deleted': true}).inFilter('id', deletes);
      }
      // ponytail: une modification faite pendant l'envoi peut perdre sa
      // marque ; elle repartira à la prochaine modification de la ligne.
      await SyncOutbox.clear(t.name, pending.keys);
    }
  }

  Future<bool> _pull() async {
    var changed = false;
    final stored = _settings.get('sync_cursor');
    final since = stored == null
        ? null
        : DateTime.parse(stored).subtract(_cursorMargin).toIso8601String();
    DateTime? newest = stored == null ? null : DateTime.parse(stored);

    for (final t in _tables) {
      final box = t.box();
      var from = 0;
      while (true) {
        final query = _client.from(t.name).select();
        final rows = await (since == null ? query : query.gte('updated_at', since))
            .order('updated_at')
            .order('id')
            .range(from, from + _pageSize - 1);
        for (final row in rows) {
          final id = row['id'] as String;
          final updated = DateTime.parse(row['updated_at'] as String);
          if (newest == null || updated.isAfter(newest)) newest = updated;
          // Une modification locale en attente l'emporte (elle sera envoyée).
          if (SyncOutbox.isDirty(t.name, id)) continue;
          if (row['deleted'] == true) {
            if (box.containsKey(id)) {
              await box.delete(id);
              changed = true;
            }
          } else {
            await box.put(id, t.fromRow(row));
            changed = true;
          }
        }
        if (rows.length < _pageSize) break;
        from += _pageSize;
      }
    }
    if (newest != null) {
      await _settings.put('sync_cursor', newest.toUtc().toIso8601String());
    }
    return changed;
  }
}
