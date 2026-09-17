import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/expense_model.dart';
import '../../data/models/member_model.dart';
import 'expense_provider.dart';

final memberListProvider =
    StateNotifierProvider<MemberNotifier, List<MemberModel>>((ref) {
  final notifier = MemberNotifier(
    Hive.box<MemberModel>('members'),
    ref.watch(expenseListProvider),
  );
  ref.listen(expenseListProvider, (_, expenses) {
    notifier.updateExpenses(expenses);
  });
  return notifier;
});

class MemberNotifier extends StateNotifier<List<MemberModel>> {
  final Box<MemberModel> _box;
  List<ExpenseModel> _expenses;

  MemberNotifier(this._box, this._expenses) : super(_box.values.toList());

  void updateExpenses(List<ExpenseModel> expenses) {
    _expenses = expenses;
    state = [...state];
  }

  double spentByMember(String memberId) {
    return _expenses
        .where((expense) => expense.memberId == memberId)
        .fold<double>(0, (total, expense) => total + expense.amount);
  }

  double get teamTotal {
    final memberIds = state.map((member) => member.id).toSet();
    return _expenses
        .where((expense) => memberIds.contains(expense.memberId))
        .fold<double>(0, (total, expense) => total + expense.amount);
  }

  Future<void> addMember({required String name, required String role}) async {
    final member = MemberModel(
      id: const Uuid().v4(),
      name: name,
      role: role,
    );
    await _box.put(member.id, member);
    state = _box.values.toList();
  }

  Future<void> deleteMember(String id) async {
    await _box.delete(id);
    state = _box.values.toList();
  }
}
