import 'package:flutter_test/flutter_test.dart';

import 'package:devbudget/data/models/budget_model.dart';
import 'package:devbudget/data/models/expense_model.dart';
import 'package:devbudget/logic/money.dart';
import 'package:devbudget/logic/providers/budget_provider.dart';
import 'package:devbudget/logic/settlement.dart';

ExpenseModel expense({
  double amount = 10,
  String category = 'Alimentation',
  DateTime? date,
  String memberId = 'a',
  String? budgetId,
  bool isIncome = false,
}) =>
    ExpenseModel(
      id: 'e${amount}_$category',
      title: 't',
      amount: amount,
      category: category,
      date: date ?? DateTime(2026, 9, 10),
      memberId: memberId,
      budgetId: budgetId,
      isIncome: isIncome,
    );

BudgetModel budget({String? category, bool recurring = false}) => BudgetModel(
      id: 'b1',
      name: 'Sept',
      totalAmount: 1000,
      startDate: DateTime(2026, 9, 1),
      endDate: DateTime(2026, 9, 30),
      ownerId: 'me',
      category: category,
      recurring: recurring,
    );

void main() {
  group('formatMoney', () {
    test('devise sans décimales, séparateur de milliers', () {
      expect(formatMoney(2400, 'XAF'), '2 400 XAF');
    });
    test('devise à 2 décimales, virgule décimale', () {
      expect(formatMoney(1200.5, 'EUR'), '1 200,50 EUR');
    });
  });

  group('convertAmount', () {
    final rates = {...fixedPerEur, 'USD': 1.10};
    test('XAF vers EUR utilise la parité fixe', () {
      expect(convertAmount(655957, 'XAF', 'EUR', rates), closeTo(1000, 1e-6));
    });
    test('EUR vers USD', () {
      expect(convertAmount(10, 'EUR', 'USD', rates), closeTo(11, 1e-9));
    });
    test('taux inconnu ou même devise : montant inchangé', () {
      expect(convertAmount(5, 'XAF', 'ZZZ', rates), 5);
      expect(convertAmount(5, 'USD', 'USD', rates), 5);
    });
  });

  group('budgetCounts', () {
    test('compte une dépense dans la période, y compris le dernier jour à 15h',
        () {
      final lastDay = expense(date: DateTime(2026, 9, 30, 15, 30));
      expect(budgetCounts(budget(), lastDay), isTrue);
    });
    test('ignore les revenus et les dépenses hors période', () {
      expect(budgetCounts(budget(), expense(isIncome: true)), isFalse);
      expect(
          budgetCounts(budget(), expense(date: DateTime(2026, 10, 1))), isFalse);
    });
    test('budget par catégorie', () {
      final b = budget(category: 'Transport');
      expect(budgetCounts(b, expense(category: 'Alimentation')), isFalse);
      expect(budgetCounts(b, expense(category: 'Transport')), isTrue);
    });
    test('budgetId explicite : hors période compte, autre budget exclu', () {
      final old = expense(date: DateTime(2026, 1, 1), budgetId: 'b1');
      expect(budgetCounts(budget(), old), isTrue);
      expect(budgetCounts(budget(recurring: true), old), isFalse);
      expect(budgetCounts(budget(), expense(budgetId: 'autre')), isFalse);
    });
  });

  group('computeSettlements', () {
    test('rien à régler avec moins de 2 membres', () {
      expect(computeSettlements(['a'], [expense(amount: 50)]), isEmpty);
    });
    test('un seul payeur : les autres lui doivent leur part', () {
      final t = computeSettlements(
          ['a', 'b', 'c'], [expense(amount: 90, memberId: 'a')]);
      expect(t, hasLength(2));
      expect(t.every((x) => x.toId == 'a' && (x.amount - 30).abs() < 1e-9),
          isTrue);
    });
    test('parts déjà équilibrées : aucun transfert', () {
      final t = computeSettlements([
        'a',
        'b'
      ], [
        expense(amount: 40, memberId: 'a'),
        expense(amount: 40, category: 'Transport', memberId: 'b'),
      ]);
      expect(t, isEmpty);
    });
    test('la somme remboursée égale la somme due', () {
      final t = computeSettlements([
        'a',
        'b',
        'c'
      ], [
        expense(amount: 100, memberId: 'a'),
        expense(amount: 50, category: 'Transport', memberId: 'b'),
      ]);
      final total = t.fold<double>(0, (s, x) => s + x.amount);
      // c doit 50, b doit 0 (a payé 100, b 50, part 50) : seul c paie 50.
      expect(total, closeTo(50, 1e-9));
    });
  });
}
