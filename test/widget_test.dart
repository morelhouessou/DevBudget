// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:devbudget/data/models/budget_model.dart';
import 'package:devbudget/data/models/expense_model.dart';
import 'package:devbudget/data/models/member_model.dart';

import 'package:devbudget/main.dart';

void main() {
  setUpAll(() async {
    Hive.init(Directory.systemTemp.path);
    Hive.registerAdapter(ExpenseModelAdapter());
    Hive.registerAdapter(BudgetModelAdapter());
    Hive.registerAdapter(MemberModelAdapter());
    await Hive.openBox<ExpenseModel>('expenses');
    await Hive.openBox<BudgetModel>('budgets');
    await Hive.openBox<MemberModel>('members');
  });

  testWidgets('affiche la navigation principale', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: DevBudgetApp()));

    expect(find.text('DevBudget'), findsOneWidget);
    expect(find.text('Mes dépenses'), findsOneWidget);
    expect(find.text('Mes budgets'), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
