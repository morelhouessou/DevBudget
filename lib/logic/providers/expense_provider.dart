import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/expense_model.dart';
import '../../data/repositories/expense_repository.dart';
import '../money.dart';
import 'currency_provider.dart';
 
/// Instance unique du repository des depenses (acces a la box Hive).
final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository();
});
 
/// Liste des depenses, mise a jour a chaque ajout / modification / suppression.
final expenseListProvider =
    StateNotifierProvider<ExpenseNotifier, List<ExpenseModel>>((ref) {
  final repo = ref.watch(expenseRepositoryProvider);
  return ExpenseNotifier(repo);
});
 
class ExpenseNotifier extends StateNotifier<List<ExpenseModel>> {
  final ExpenseRepository _repository;
 
  ExpenseNotifier(this._repository) : super(_repository.getAll());
 
  Future<void> addExpense(ExpenseModel expense) async {
    await _repository.add(expense);
    state = _repository.getAll();
  }
 
  Future<void> updateExpense(ExpenseModel expense) async {
    await _repository.update(expense);
    state = _repository.getAll();
  }
 
  Future<void> deleteExpense(String id) async {
    await _repository.delete(id);
    state = _repository.getAll();
  }
}
 

// Calculs derives ( logique metier)
 
/// Toutes les operations (depenses et revenus) avec le montant converti dans
/// la devise d'affichage. Base de tous les calculs : on ne cumule jamais des
/// montants de devises differentes.
final convertedExpensesProvider = Provider<List<ExpenseModel>>((ref) {
  final display = ref.watch(displayCurrencyProvider);
  final rates = ref.watch(ratesProvider);
  return ref
      .watch(expenseListProvider)
      .map((e) => e.copyWith(
            amount: convertAmount(
                e.amount, e.currency ?? defaultCurrency, display, rates),
            currency: display,
          ))
      .toList();
});

/// Depenses uniquement (revenus exclus), converties.
final spendingProvider = Provider<List<ExpenseModel>>((ref) =>
    ref.watch(convertedExpensesProvider).where((e) => !e.isIncome).toList());

/// Revenus uniquement, convertis.
final incomeProvider = Provider<List<ExpenseModel>>((ref) =>
    ref.watch(convertedExpensesProvider).where((e) => e.isIncome).toList());

double sumOf(List<ExpenseModel> items) =>
    items.fold<double>(0.0, (sum, e) => sum + e.amount);

/// Total de toutes les depenses enregistrees.
final totalExpensesProvider =
    Provider<double>((ref) => sumOf(ref.watch(spendingProvider)));

/// Total des revenus enregistres.
final totalIncomeProvider =
    Provider<double>((ref) => sumOf(ref.watch(incomeProvider)));

/// Repartition des depenses par categorie, ex: {"Alimentation": 120.0, "Transport": 40.0}.
final expensesByCategoryProvider = Provider<Map<String, double>>((ref) {
  final Map<String, double> result = {};
  for (final e in ref.watch(spendingProvider)) {
    result.update(e.category, (v) => v + e.amount, ifAbsent: () => e.amount);
  }
  return result;
});