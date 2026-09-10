import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import 'package:devbudget/main.dart';
import 'package:devbudget/data/models/expense_model.dart';
import 'package:devbudget/data/models/budget_model.dart';
import 'package:devbudget/data/models/member_model.dart';
import 'package:devbudget/data/repositories/expense_repository.dart';
import 'package:devbudget/data/repositories/budget_repository.dart';
import 'package:devbudget/logic/providers/expense_provider.dart';
import 'package:devbudget/logic/providers/budget_provider.dart';

class _TestExpenseNotifier extends ExpenseNotifier {
  _TestExpenseNotifier() : super(ExpenseRepository());
}

class _TestBudgetNotifier extends BudgetNotifier {
  _TestBudgetNotifier() : super(BudgetRepository());
}

void main() {
  late Directory hiveDirectory;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    hiveDirectory = await Directory.systemTemp.createTemp('devbudget_test_');
    Hive.init(hiveDirectory.path);

    Hive.registerAdapter(ExpenseModelAdapter());
    Hive.registerAdapter(BudgetModelAdapter());
    Hive.registerAdapter(MemberModelAdapter());

    await Hive.openBox<ExpenseModel>('expenses');
    await Hive.openBox<BudgetModel>('budgets');
    await Hive.openBox<MemberModel>('members');
  });

  tearDownAll(() async {
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
  });

  testWidgets('affiche le tableau de bord et permet de naviguer',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          expenseListProvider.overrideWith(
            // ignore: unnecessary_new
            (ref) => _TestExpenseNotifier(),
          ),
          budgetListProvider.overrideWith(
            (ref) => _TestBudgetNotifier(),
          ),
        ],
        child: const DevBudgetApp(),
      ),
    );

    expect(find.text('DevBudget'), findsOneWidget);
    expect(find.text('Depenses'), findsOneWidget);
    expect(find.text('Budgets'), findsOneWidget);
    expect(find.text('Stats'), findsOneWidget);

    await tester.tap(find.text('Budgets'));
    await tester.pump();

    expect(find.byType(ListView), findsOneWidget);
  });
}
