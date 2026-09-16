import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:devbudget/main.dart';
import 'package:devbudget/data/models/expense_model.dart';
import 'package:devbudget/data/models/budget_model.dart';
import 'package:devbudget/data/models/member_model.dart';

void main() {
  setUpAll(() async {
    final tempDir = Directory.systemTemp.createTempSync('hive_test');
    Hive.init(tempDir.path);

    Hive.registerAdapter(ExpenseModelAdapter());
    Hive.registerAdapter(BudgetModelAdapter());
    Hive.registerAdapter(MemberModelAdapter());
    Hive.registerAdapter(MemberRoleAdapter());

    await Hive.openBox<ExpenseModel>('expenses');
    await Hive.openBox<BudgetModel>('budgets');
    await Hive.openBox<MemberModel>('members');
  });

  tearDownAll(() async {
    await Hive.close();
  });

  testWidgets('DevBudgetApp se lance sans erreur', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: DevBudgetApp()),
    );
    await tester.pumpAndSettle();

    expect(find.byType(DevBudgetApp), findsOneWidget);
  });
}
