import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/expense_model.dart';
import '../../data/repositories/expense_repository.dart';

final expenseRepositoryProvider = Provider((ref) => ExpenseRepository());

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

  Future<void> deleteExpense(String id) async {
    await _repository.delete(id);
    state = _repository.getAll();
  }
}
