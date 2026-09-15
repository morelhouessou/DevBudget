import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:devbudget/data/models/budget_model.dart';
import 'package:devbudget/data/models/expense_model.dart';
import 'package:devbudget/data/models/member_model.dart';
import 'package:devbudget/logic/providers/budget_provider.dart';
import 'package:devbudget/logic/providers/expense_provider.dart';
import 'package:devbudget/main.dart';

void main() {
  late Directory hiveDirectory;

  setUpAll(() async {
    hiveDirectory = await Directory.systemTemp.createTemp('devbudget_functional_');
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

  testWidgets('l application affiche la navigation principale et l etat vide',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: DevBudgetApp()));

    expect(find.text('DevBudget'), findsOneWidget);
    expect(find.text('Depenses'), findsOneWidget);
    expect(find.text('Budgets'), findsOneWidget);
    expect(find.text('Stats'), findsOneWidget);

    await tester.tap(find.text('Stats'));
    await tester.pumpAndSettle();

    expect(
      find.text('Ajoutez une depense pour voir vos statistiques.'),
      findsOneWidget,
    );
  });

  testWidgets('la liste des depenses affiche les donnees et les montants',
      (WidgetTester tester) async {
    final expenseBox = Hive.box<ExpenseModel>('expenses');
    await expenseBox.put(
      'exp-1',
      ExpenseModel(
        id: 'exp-1',
        title: 'Loyer',
        amount: 120.5,
        category: 'Logement',
        date: DateTime(2025, 1, 10),
        memberId: 'member-1',
      ),
    );

    await tester.pumpWidget(const ProviderScope(child: DevBudgetApp()));
    await tester.pumpAndSettle();

    expect(find.text('Loyer'), findsOneWidget);
    expect(find.text('120.50'), findsOneWidget);
    expect(find.text('Logement'), findsOneWidget);
  });

  testWidgets('la liste des budgets affiche les informations de periode',
      (WidgetTester tester) async {
    final budgetBox = Hive.box<BudgetModel>('budgets');
    await budgetBox.put(
      'budget-1',
      BudgetModel(
        id: 'budget-1',
        name: 'Budget vacances',
        totalAmount: 2400,
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 3, 31),
      ),
    );

    await tester.pumpWidget(const ProviderScope(child: DevBudgetApp()));
    await tester.tap(find.text('Budgets'));
    await tester.pumpAndSettle();

    expect(find.text('Budget vacances'), findsOneWidget);
    expect(find.textContaining('2400.00'), findsOneWidget);
    expect(find.textContaining('2025-01-01'), findsOneWidget);
  });

  testWidgets('la vue statistiques calcule les totaux et regroupements',
      (WidgetTester tester) async {
    final expenseBox = Hive.box<ExpenseModel>('expenses');
    await expenseBox.put(
      'exp-1',
      ExpenseModel(
        id: 'exp-1',
        title: 'Courses',
        amount: 80,
        category: 'Alimentation',
        date: DateTime(2025, 2, 1),
        memberId: 'member-1',
      ),
    );
    await expenseBox.put(
      'exp-2',
      ExpenseModel(
        id: 'exp-2',
        title: 'Transport',
        amount: 70,
        category: 'Transport',
        date: DateTime(2025, 2, 15),
        memberId: 'member-2',
      ),
    );

    await tester.pumpWidget(const ProviderScope(child: DevBudgetApp()));
    await tester.tap(find.text('Stats'));
    await tester.pumpAndSettle();

    expect(find.text('Vue d\'ensemble'), findsOneWidget);
    expect(find.text('150.00 EUR depenses'), findsOneWidget);
    expect(find.text('Alimentation'), findsOneWidget);
    expect(find.text('Transport'), findsOneWidget);
  });

  test('les providers ajoutent et suppriment les donnees sans erreur', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final expenseNotifier = container.read(expenseListProvider.notifier);
    await expenseNotifier.addExpense(
      ExpenseModel(
        id: 'exp-1',
        title: 'Courses',
        amount: 65,
        category: 'Alimentation',
        date: DateTime(2025, 2, 5),
        memberId: 'member-1',
      ),
    );

    expect(container.read(expenseListProvider), hasLength(1));
    expect(container.read(expenseListProvider).first.title, 'Courses');

    await expenseNotifier.deleteExpense('exp-1');
    expect(container.read(expenseListProvider), isEmpty);

    final budgetNotifier = container.read(budgetListProvider.notifier);
    await budgetNotifier.addBudget(
      BudgetModel(
        id: 'budget-1',
        name: 'Budget mensuel',
        totalAmount: 1200,
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 1, 31),
      ),
    );

    expect(container.read(budgetListProvider), hasLength(1));
    expect(container.read(budgetListProvider).first.name, 'Budget mensuel');
  });
}
