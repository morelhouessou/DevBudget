// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:devbudget/data/models/budget_model.dart';
import 'package:devbudget/data/models/expense_model.dart';
import 'package:devbudget/data/models/member_model.dart';
import 'package:devbudget/logic/providers/budget_provider.dart';
import 'package:devbudget/logic/providers/expense_provider.dart';
import 'package:devbudget/presentation/screens/stats_screen.dart';

void main() {
  late Directory hiveDirectory;

  setUpAll(() async {
    hiveDirectory = await Directory.systemTemp.createTemp('devbudget_test_');
    Hive.init(hiveDirectory.path);
    Hive.registerAdapter(ExpenseModelAdapter());
    Hive.registerAdapter(BudgetModelAdapter());
    Hive.registerAdapter(MemberModelAdapter());
    await Hive.openBox<ExpenseModel>('expenses');
    await Hive.openBox<BudgetModel>('budgets');
    await Hive.openBox<MemberModel>('members');
  });

  setUp(() async {
    await Hive.box<ExpenseModel>('expenses').clear();
    await Hive.box<BudgetModel>('budgets').clear();
    await Hive.box<MemberModel>('members').clear();
  });

  tearDownAll(() async {
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
  });

  test('le repository des depenses ajoute, lit et supprime des donnees', () async {
    final box = Hive.box<ExpenseModel>('expenses');
    final model = ExpenseModel(
      id: 'exp-1',
      title: 'Courses',
      amount: 42.5,
      category: 'Alimentation',
      date: DateTime(2025, 2, 10),
      memberId: 'member-1',
    );

    await box.put(model.id, model);
    expect(box.values, hasLength(1));
    expect(box.get('exp-1')?.title, 'Courses');

    await box.delete('exp-1');
    expect(box.values, isEmpty);
  });

  test('le provider de depenses met a jour la liste', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(expenseListProvider.notifier);
    await notifier.addExpense(
      ExpenseModel(
        id: 'exp-1',
        title: 'Courses',
        amount: 42.5,
        category: 'Alimentation',
        date: DateTime(2025, 2, 10),
        memberId: 'member-1',
      ),
    );

    expect(container.read(expenseListProvider), hasLength(1));
    await notifier.deleteExpense('exp-1');
    expect(container.read(expenseListProvider), isEmpty);
  });

  test('le provider des budgets ajoute un budget', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(budgetListProvider.notifier);
    await notifier.addBudget(
      BudgetModel(
        id: 'budget-1',
        name: 'Budget mensuel',
        totalAmount: 1500,
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 1, 31),
      ),
    );

    expect(container.read(budgetListProvider), hasLength(1));
    expect(container.read(budgetListProvider).first.name, 'Budget mensuel');
  });

  test('les calculs de stats regroupent les depenses correctement', () {
    final now = DateTime.now();
    final expenses = [
      ExpenseModel(
        id: 'exp-1',
        title: 'Courses',
        amount: 80,
        category: 'Alimentation',
        date: DateTime(now.year, now.month, 1),
        memberId: 'member-1',
      ),
      ExpenseModel(
        id: 'exp-2',
        title: 'Transport',
        amount: 70,
        category: 'Transport',
        date: DateTime(now.year, now.month, 14),
        memberId: 'member-2',
      ),
    ];

    final byCategory = totalsByCategory(expenses);
    expect(byCategory['Alimentation'], 80);
    expect(byCategory['Transport'], 70);

    final byMonth = totalsByMonth(expenses);
    expect(byMonth.length, 6);
    expect(byMonth.fold<double>(0, (sum, value) => sum + value), 150);
  });
}
