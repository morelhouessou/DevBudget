import 'package:flutter_test/flutter_test.dart';

import 'package:devbudget/data/models/budget_model.dart';
import 'package:devbudget/data/models/expense_model.dart';
import 'package:devbudget/logic/export.dart';
import 'package:devbudget/logic/providers/budget_provider.dart';

ExpenseModel op(String title,
        {double amount = 12.5, bool isIncome = false, String? currency}) =>
    ExpenseModel(
      id: title,
      title: title,
      amount: amount,
      category: 'Transport',
      date: DateTime(2026, 9, 10),
      memberId: 'm1',
      budgetId: 'b1',
      isIncome: isIncome,
      currency: currency,
    );

void main() {
  final members = {'m1': 'Aline'};
  final budgets = {'b1': 'Septembre'};

  test('CSV : BOM, en-tête, séparateur ; et décimale virgule', () {
    final csv = buildCsv([op('Taxi', currency: 'EUR')],
        memberNames: members, budgetNames: budgets);
    expect(csv.startsWith('﻿Date;Type;Libellé;'), isTrue);
    expect(csv, contains('10/09/2026;Dépense;Taxi;Transport;12,5;EUR;Aline;Septembre'));
  });

  test('CSV : devise absente = XAF, revenu typé', () {
    final csv = buildCsv([op('Salaire', isIncome: true)],
        memberNames: members, budgetNames: budgets);
    expect(csv, contains(';Revenu;Salaire;'));
    expect(csv, contains(';12,5;XAF;'));
  });

  test('CSV : neutralise les formules et échappe ; et guillemets', () {
    final csv = buildCsv([op('=CMD()'), op('a;b "c"')],
        memberNames: members, budgetNames: budgets);
    expect(csv, contains(";'=CMD();"));
    expect(csv, contains(';"a;b ""c""";'));
  });

  test('PDF : produit un document valide', () async {
    final bytes = await buildPdf(
      [op('Taxi'), op('Prime', isIncome: true)],
      memberNames: members,
      budgets: [
        BudgetStatus(
            BudgetModel(
              id: 'b1',
              name: 'Septembre',
              totalAmount: 1000,
              startDate: DateTime(2026, 9, 1),
              endDate: DateTime(2026, 9, 30),
              ownerId: 'me',
            ),
            1000,
            250),
      ],
      total: 250,
      income: 400,
      currencyCode: 'XAF',
    );
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(bytes.length, greaterThan(1000));
  });
}
