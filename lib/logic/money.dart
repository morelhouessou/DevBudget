import 'package:intl/intl.dart';

/// Devise des données créées avant la gestion multi-devises.
const defaultCurrency = 'XAF';

/// Parités fixes, en unités pour 1 EUR. La BCE ne publie pas le franc CFA
/// (XAF/XOF), mais il est arrimé à l'euro.
const fixedPerEur = <String, double>{
  'EUR': 1.0,
  'XAF': 655.957,
  'XOF': 655.957,
};

// ponytail: liste des devises sans décimales codée en dur, à compléter si besoin.
const _zeroDecimals = {
  'XAF', 'XOF', 'XPF', 'JPY', 'KRW', 'VND', 'UGX', 'RWF', 'GNF', 'KMF',
  'DJF', 'CLP', 'PYG',
};

/// Convertit [amount] de [from] vers [to]. [perEur] donne, pour chaque
/// devise, le nombre d'unités pour 1 EUR. Taux inconnu : montant inchangé.
double convertAmount(
  double amount,
  String from,
  String to,
  Map<String, double> perEur,
) {
  if (from == to) return amount;
  final fromRate = perEur[from];
  final toRate = perEur[to];
  if (fromRate == null || toRate == null) return amount;
  return amount / fromRate * toRate;
}

/// Formate un montant à la française : « 1 200,50 EUR », « 2 400 XAF ».
String formatMoney(double amount, String code) {
  final digits = _zeroDecimals.contains(code) ? 0 : 2;
  final number = NumberFormat.decimalPatternDigits(
    locale: 'fr_FR',
    decimalDigits: digits,
  ).format(amount);
  return '$number $code';
}
