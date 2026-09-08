import 'package:hive/hive.dart';
import '../models/budget_model.dart';

class BudgetRepository {
  final Box<BudgetModel> _box = Hive.box<BudgetModel>('budgets');

  List<BudgetModel> getAll() => _box.values.toList();

  Future<void> add(BudgetModel budget) async {
    await _box.put(budget.id, budget);
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }
}
