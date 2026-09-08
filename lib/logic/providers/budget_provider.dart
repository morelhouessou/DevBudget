import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/budget_model.dart';
import '../../data/repositories/budget_repository.dart';

final budgetRepositoryProvider = Provider((ref) => BudgetRepository());

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
}
