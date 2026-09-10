import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/budget_model.dart';
import '../../data/models/expense_model.dart';
import '../../data/repositories/budget_repository.dart';
import 'expense_provider.dart';

/// Instance unique du repository des budgets (acces a la box Hive).
final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepository();
});

/// Liste des budgets, mise a jour a chaque ajout / modification / suppression.
final budgetListProvider =
    StateNotifierProvider<BudgetNotifier, List<BudgetModel>>((ref) {
  final repo = ref.watch(budgetRepositoryProvider);
  return BudgetNotifier(repo);
});

class BudgetNotifier extends StateNotifier<List<BudgetModel>> {
  final BudgetRepository _repository;

  BudgetNotifier(this._repository) : super(_repository.getAll());

  Future<void> addBudget(BudgetModel budget) async {
    await _repository.add(budget);
    state = _repository.getAll();
  }

  Future<void> updateBudget(BudgetModel budget) async {
    await _repository.update(budget);
    state = _repository.getAll();
  }

  Future<void> deleteBudget(String id) async {
    await _repository.delete(id);
    state = _repository.getAll();
  }
}


// Calculs derives (logique metier)

// Hypothese de liaison budget <-> depenses : ExpenseModel n'a pas de champ
// budgetId (cf. Lot 1). Une depense est donc rattachee a un budget si sa
// date tombe dans la periode [startDate, endDate] de ce budget. A valider
// avec le reste de l'equipe si un lien explicite est prefere plus tard.

/// Depenses qui tombent dans la periode d'un budget donne.
final expensesForBudgetProvider =
    Provider.family<List<ExpenseModel>, BudgetModel>((ref, budget) {
  final expenses = ref.watch(expenseListProvider);
  return expenses
      .where((e) =>
          !e.date.isBefore(budget.startDate) &&
          !e.date.isAfter(budget.endDate))
      .toList();
});

/// Montant total deja depense dans le cadre d'un budget donne.
final spentForBudgetProvider =
    Provider.family<double, BudgetModel>((ref, budget) {
  final expenses = ref.watch(expensesForBudgetProvider(budget));
  return expenses.fold<double>(0.0, (sum, e) => sum + e.amount);
});

/// Solde restant d'un budget (negatif en cas de depassement).
final remainingBalanceProvider =
    Provider.family<double, BudgetModel>((ref, budget) {
  final spent = ref.watch(spentForBudgetProvider(budget));
  return budget.totalAmount - spent;
});