import 'package:hive/hive.dart';
import '../models/budget_model.dart';

class BudgetRepository {
  final Box<BudgetModel> _box = Hive.box<BudgetModel>('budgets');

  /// Retourne la liste de tous les budgets enregistrés.
  List<BudgetModel> getAll() => _box.values.toList();

  /// Retourne le budget correspondant à [id], ou `null` s'il n'existe pas.
  BudgetModel? getById(String id) => _box.get(id);

  /// Ajoute (ou remplace si l'id existe déjà) un budget dans la box.
  Future<void> add(BudgetModel budget) async {
    await _box.put(budget.id, budget);
  }

  /// Met à jour un budget déjà présent dans la box.
  Future<void> update(BudgetModel budget) async {
    await budget.save();
  }

  /// Supprime le budget correspondant à [id] de la box.
  Future<void> delete(String id) async {
    await _box.delete(id);
  }
}
