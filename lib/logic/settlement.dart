import '../data/models/expense_model.dart';

/// Remboursement à effectuer : [fromId] doit [amount] à [toId].
class Transfer {
  final String fromId;
  final String toId;
  final double amount;

  const Transfer(this.fromId, this.toId, this.amount);
}

/// Calcule qui doit combien à qui pour que chacun ait payé la même part.
///
/// Seules les dépenses payées par un des [memberIds] comptent, partagées à
/// parts égales entre tous les membres.
// ponytail: partage égal entre tous les membres ; pour des parts ou des
// participants par dépense, ajouter une liste de participants à ExpenseModel.
List<Transfer> computeSettlements(
  List<String> memberIds,
  List<ExpenseModel> spending,
) {
  if (memberIds.length < 2) return const [];
  final paid = {for (final id in memberIds) id: 0.0};
  for (final e in spending) {
    if (paid.containsKey(e.memberId)) paid[e.memberId] = paid[e.memberId]! + e.amount;
  }
  final share = paid.values.fold<double>(0, (a, b) => a + b) / memberIds.length;

  // Solde > 0 : doit recevoir ; < 0 : doit payer.
  final creditors = <MapEntry<String, double>>[];
  final debtors = <MapEntry<String, double>>[];
  paid.forEach((id, amount) {
    final balance = amount - share;
    if (balance > 0.005) creditors.add(MapEntry(id, balance));
    if (balance < -0.005) debtors.add(MapEntry(id, -balance));
  });

  final transfers = <Transfer>[];
  var c = 0, d = 0;
  var credit = creditors.isEmpty ? 0.0 : creditors[0].value;
  var debt = debtors.isEmpty ? 0.0 : debtors[0].value;
  while (c < creditors.length && d < debtors.length) {
    final amount = credit < debt ? credit : debt;
    transfers.add(Transfer(debtors[d].key, creditors[c].key, amount));
    credit -= amount;
    debt -= amount;
    if (credit <= 0.005 && ++c < creditors.length) credit = creditors[c].value;
    if (debt <= 0.005 && ++d < debtors.length) debt = debtors[d].value;
  }
  return transfers;
}
