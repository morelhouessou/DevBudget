import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:devbudget/data/models/budget_model.dart';
import 'package:devbudget/data/models/expense_model.dart';
import 'package:devbudget/data/models/member_model.dart';
import 'package:devbudget/logic/sync/sync_service.dart';

void main() {
  group('conversions modèle <-> ligne Supabase', () {
    test('dépense : aller-retour sans perte', () {
      final e = ExpenseModel(
        id: 'e1',
        title: 'Taxi « aéroport »',
        amount: 5000.5,
        category: 'Transport',
        date: DateTime(2026, 9, 10, 14, 30),
        memberId: 'm1',
        budgetId: 'b1',
        isIncome: true,
        currency: 'EUR',
      );
      final row = expenseToRow(e, 'user-1');
      expect(row['owner_id'], 'user-1');
      expect((row['date'] as String).endsWith('Z'), isTrue); // UTC
      final back = expenseFromRow({...row, 'updated_at': 'x'});
      expect(back.title, e.title);
      expect(back.amount, e.amount);
      expect(back.date.isAtSameMomentAs(e.date), isTrue);
      expect(back.budgetId, 'b1');
      expect(back.isIncome, isTrue);
      expect(back.currency, 'EUR');
    });

    test('budget : catégorie, récurrence et membres conservés', () {
      final b = BudgetModel(
        id: 'b1',
        name: 'Transport',
        totalAmount: 50000,
        startDate: DateTime(2026, 9, 1),
        endDate: DateTime(2026, 9, 30),
        ownerId: 'x',
        category: 'Transport',
        recurring: true,
        currency: 'XAF',
        memberIds: ['m1', 'm2'],
      );
      final back = budgetFromRow({...budgetToRow(b, 'user-1')});
      expect(back.ownerId, 'user-1');
      expect(back.category, 'Transport');
      expect(back.recurring, isTrue);
      expect(back.memberIds, ['m1', 'm2']);
      expect(back.isShared, isTrue);
      expect(back.endDate.isAtSameMomentAs(b.endDate), isTrue);
    });

    test('membre : le rôle passe par son nom', () {
      final m = MemberModel(id: 'm1', name: 'Aline', role: MemberRole.viewer);
      expect(memberToRow(m, 'u')['role'], 'viewer');
      expect(memberFromRow(memberToRow(m, 'u')).role, MemberRole.viewer);
    });
  });

  group('SyncOutbox', () {
    late Directory dir;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('outbox_');
      Hive.init(dir.path);
      await Hive.openBox<String>('settings');
    });

    tearDown(() async {
      await Hive.close();
      await dir.delete(recursive: true);
    });

    test('mémorise, remplace par la dernière opération et efface', () async {
      SyncOutbox.markUpsert('expenses', 'e1');
      SyncOutbox.markUpsert('expenses', 'e2');
      SyncOutbox.markUpsert('budgets', 'b1');
      expect(SyncOutbox.pending('expenses'),
          {'e1': 'upsert', 'e2': 'upsert'});

      SyncOutbox.markDelete('expenses', 'e1'); // la dernière opération gagne
      expect(SyncOutbox.pending('expenses')['e1'], 'delete');
      expect(SyncOutbox.isDirty('budgets', 'b1'), isTrue);
      expect(SyncOutbox.isDirty('budgets', 'autre'), isFalse);

      await SyncOutbox.clear('expenses', ['e1', 'e2']);
      expect(SyncOutbox.pending('expenses'), isEmpty);
      expect(SyncOutbox.pending('budgets'), {'b1': 'upsert'}); // intact
    });

    test('sans box settings (tests, web), ne fait rien', () async {
      await Hive.close();
      SyncOutbox.markUpsert('expenses', 'e1');
      expect(SyncOutbox.pending('expenses'), isEmpty);
      await Hive.openBox<String>('settings'); // pour le tearDown
    });
  });
}
