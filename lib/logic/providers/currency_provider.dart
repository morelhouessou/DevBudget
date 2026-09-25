import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../money.dart';

/// Devise d'affichage choisie dans l'application (synchronisée depuis
/// `CurrencyScope` dans `main.dart`).
final displayCurrencyProvider = StateProvider<String>((ref) => defaultCurrency);

/// Taux de change (unités pour 1 EUR), mis en cache dans la box `settings`.
final ratesProvider =
    StateNotifierProvider<RatesNotifier, Map<String, double>>((ref) {
  return RatesNotifier();
});

class RatesNotifier extends StateNotifier<Map<String, double>> {
  RatesNotifier() : super(_load()) {
    refresh();
  }

  static Box<String>? get _settings =>
      Hive.isBoxOpen('settings') ? Hive.box<String>('settings') : null;

  static Map<String, double> _load() {
    final cached = _settings?.get('rates');
    final rates = <String, double>{};
    if (cached != null) {
      (jsonDecode(cached) as Map<String, dynamic>)
          .forEach((code, rate) => rates[code] = (rate as num).toDouble());
    }
    return {...rates, ...fixedPerEur};
  }

  /// Récupère les derniers taux (API Frankfurter, base EUR) au démarrage.
  /// Sans réseau ou en cas d'erreur, on garde le cache local.
  /// Sans box `settings` (tests), aucun appel réseau n'est fait.
  Future<void> refresh() async {
    final settings = _settings;
    if (settings == null) return;
    HttpClient? client;
    try {
      // Créé dans le try : indisponible sur le web (dart:io), où l'on garde le cache.
      client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
      final request = await client
          .getUrl(Uri.parse('https://api.frankfurter.dev/v2/rates?base=EUR'));
      final response = await request.close().timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return;
      final body = await response.transform(utf8.decoder).join();
      final fetched = <String, double>{};
      for (final item in jsonDecode(body) as List<dynamic>) {
        fetched[item['quote'] as String] = (item['rate'] as num).toDouble();
      }
      if (fetched.isEmpty) return;
      await settings.put('rates', jsonEncode(fetched));
      if (mounted) state = {...fetched, ...fixedPerEur};
    } catch (_) {
      // Hors-ligne : le cache reste utilisé.
    } finally {
      client?.close();
    }
  }
}
