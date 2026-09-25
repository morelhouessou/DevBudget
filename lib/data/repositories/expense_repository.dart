import 'package:hive/hive.dart';
import '../../logic/sync/sync_service.dart';
import '../models/expense_model.dart';

class ExpenseRepository {
  final Box<ExpenseModel> _box = Hive.box<ExpenseModel>('expenses');

  List<ExpenseModel> getAll() => _box.values.toList();

  /// Retourne la dépense correspondant à [id], ou `null` s'il n'existe pas.
  ExpenseModel? getById(String id) => _box.get(id);

  /// Ajoute (ou remplace si l'id existe déjà) une dépense dans la box.
  Future<void> add(ExpenseModel expense) async {
    await _box.put(expense.id, expense);
    SyncOutbox.markUpsert('expenses', expense.id);
  }

  /// Supprime la dépense correspondant à [id] de la box.
  Future<void> delete(String id) async {
    await _box.delete(id);
    SyncOutbox.markDelete('expenses', id);
  }

  /// Met à jour une dépense déjà présente dans la box.
  Future<void> update(ExpenseModel expense) async {
    await _box.put(expense.id, expense);
    SyncOutbox.markUpsert('expenses', expense.id);
  }
}
