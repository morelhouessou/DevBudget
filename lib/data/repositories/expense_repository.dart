import 'package:hive/hive.dart';
import '../models/expense_model.dart';

class ExpenseRepository {
  final Box<ExpenseModel> _box = Hive.box<ExpenseModel>('expenses');

  List<ExpenseModel> getAll() => _box.values.toList();

  Future<void> add(ExpenseModel expense) async {
    await _box.put(expense.id, expense);
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  Future<void> update(ExpenseModel expense) async {
    await expense.save();
  }
}
