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

  /// Ajoute [memberId] à la liste des membres ayant accès au budget [budgetId].
  ///
  /// Ne fait rien si le budget n'existe pas, ou si le membre est déjà présent
  /// dans la liste (évite les doublons). Met automatiquement `isShared` à `true`.
  Future<void> addMember(String budgetId, String memberId) async {
    final budget = getById(budgetId);
    if (budget == null) return;

    if (budget.memberIds.contains(memberId)) return;

    final updatedMemberIds = [...budget.memberIds, memberId];
    final updatedBudget = budget.copyWith(
      memberIds: updatedMemberIds,
      isShared: true,
    );

    await _box.put(budgetId, updatedBudget);
  }

  /// Retire [memberId] de la liste des membres ayant accès au budget [budgetId].
  ///
  /// Ne fait rien si le budget n'existe pas. Remet automatiquement `isShared`
  /// à `false` si la liste des membres devient vide après le retrait.
  Future<void> removeMember(String budgetId, String memberId) async {
    final budget = getById(budgetId);
    if (budget == null) return;

    final updatedMemberIds =
        budget.memberIds.where((id) => id != memberId).toList();
    final updatedBudget = budget.copyWith(
      memberIds: updatedMemberIds,
      isShared: updatedMemberIds.isNotEmpty,
    );

    await _box.put(budgetId, updatedBudget);
  }
}
