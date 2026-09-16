import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/expense_model.dart';
import '../../data/repositories/expense_repository.dart';
 
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
 
// Total de toutes les depenses enregistrees.
final totalExpensesProvider = Provider<double>((ref) {
  final expenses = ref.watch(expenseListProvider);
  return expenses.fold<double>(0.0, (sum, e) => sum + e.amount);
});
 
/// Repartition des depenses par categorie, ex: {"Alimentation": 120.0, "Transport": 40.0}.
final expensesByCategoryProvider = Provider<Map<String, double>>((ref) {
  final expenses = ref.watch(expenseListProvider);
  final Map<String, double> result = {};
  for (final e in expenses) {
    result.update(e.category, (v) => v + e.amount, ifAbsent: () => e.amount);
  }
  return result;
});
 
/// Depenses filtrees pour un membre donne (utile pour un suivi individuel
/// au sein d'un budget d'equipe).
final expensesByMemberProvider =
    Provider.family<List<ExpenseModel>, String>((ref, memberId) {
  final expenses = ref.watch(expenseListProvider);
  return expenses.where((e) => e.memberId == memberId).toList();
});