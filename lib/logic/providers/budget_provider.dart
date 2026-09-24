import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/budget_model.dart';
import '../../data/models/expense_model.dart';
import '../../data/repositories/budget_repository.dart';
import '../money.dart';
import 'currency_provider.dart';
import 'expense_provider.dart';

/// Seuil d'alerte : au-dela, le budget est considere comme presque epuise.
const budgetAlertRatio = 0.8;

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

  BudgetNotifier(this._repository) : super(_repository.getAll()) {
    Future.microtask(_rollRecurring);
  }

  /// Un budget mensuel dont la periode est terminee passe au mois courant.
  // ponytail: l'historique du mois passe n'est pas conserve, un budget
  // recurrent est une seule ligne qui avance ; a dupliquer si on veut l'historique.
  Future<void> _rollRecurring() async {
    final now = DateTime.now();
    var changed = false;
    for (final budget in state) {
      if (budget.recurring && budget.endDate.isBefore(now)) {
        await _repository.update(budget.copyWith(
          startDate: DateTime(now.year, now.month, 1),
          endDate: DateTime(now.year, now.month + 1, 0),
        ));
        changed = true;
      }
    }
    if (changed && mounted) state = _repository.getAll();
  }

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

/// Indique si [expense] compte dans [budget].
/// - les revenus ne comptent jamais ;
/// - un budget par categorie ne compte que cette categorie ;
/// - une depense rattachee a un autre budget ne compte pas ici ;
/// - rattachee a ce budget, elle compte toujours (sauf budget mensuel, ou la
///   periode s'applique) ; sinon elle compte si sa date est dans la periode.
bool budgetCounts(BudgetModel budget, ExpenseModel expense) {
  if (expense.isIncome) return false;
  if (budget.category != null && expense.category != budget.category) {
    return false;
  }
  if (expense.budgetId != null && expense.budgetId != budget.id) return false;
  if (expense.budgetId == budget.id && !budget.recurring) return true;
  // Comparaison au jour pres : une depense saisie le dernier jour, avec
  // l'heure courante, doit rester dans la periode.
  final day = DateTime(expense.date.year, expense.date.month, expense.date.day);
  return !day.isBefore(budget.startDate) && !day.isAfter(budget.endDate);
}

/// Etat d'un budget dans la devise d'affichage.
class BudgetStatus {
  final BudgetModel budget;
  final double total;
  final double spent;

  const BudgetStatus(this.budget, this.total, this.spent);

  double get remaining => total - spent;
  double get ratio => total <= 0 ? 0 : spent / total;
  bool get isOver => ratio > 1;
  bool get isAlert => ratio >= budgetAlertRatio;
}

/// Etat de chaque budget (par id), montants convertis dans la devise
/// d'affichage. Recalcule a chaque modification des budgets ou des depenses.
final budgetStatusesProvider = Provider<Map<String, BudgetStatus>>((ref) {
  final display = ref.watch(displayCurrencyProvider);
  final rates = ref.watch(ratesProvider);
  final spending = ref.watch(spendingProvider);
  return {
    for (final budget in ref.watch(budgetListProvider))
      budget.id: BudgetStatus(
        budget,
        convertAmount(budget.totalAmount, budget.currency ?? defaultCurrency,
            display, rates),
        sumOf(spending.where((e) => budgetCounts(budget, e)).toList()),
      ),
  };
});
