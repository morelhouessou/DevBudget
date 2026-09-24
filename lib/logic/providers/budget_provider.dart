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

// Liaison budget <-> depenses : si la depense porte un `budgetId`, elle
// appartient a ce budget uniquement. Sinon (anciennes depenses), elle est
// rattachee par la periode [startDate, endDate] du budget.

/// Depenses rattachees a [budget] parmi [expenses] (fonction pure : l'UI
/// l'appelle directement pour reagir aussi aux modifications du budget).
List<ExpenseModel> expensesOfBudget(
    BudgetModel budget, List<ExpenseModel> expenses) {
  return expenses.where((e) {
    if (e.budgetId != null) return e.budgetId == budget.id;
    return !e.date.isBefore(budget.startDate) &&
        !e.date.isAfter(budget.endDate);
  }).toList();
}

/// Montant depense dans [budget] parmi [expenses].
double spentOfBudget(BudgetModel budget, List<ExpenseModel> expenses) =>
    expensesOfBudget(budget, expenses)
        .fold<double>(0.0, (sum, e) => sum + e.amount);

/// Depenses rattachees a un budget donne.
final expensesForBudgetProvider =
    Provider.family<List<ExpenseModel>, BudgetModel>((ref, budget) =>
        expensesOfBudget(budget, ref.watch(expenseListProvider)));

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