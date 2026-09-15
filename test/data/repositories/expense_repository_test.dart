import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:devbudget/data/models/expense_model.dart';
import 'package:devbudget/data/repositories/expense_repository.dart';

void main() {
  late Directory hiveDirectory;
  late Box<ExpenseModel> box;

  setUpAll(() async {
    /// Crée un répertoire temporaire pour Hive afin d'éviter les conflits avec les données existantes.
    hiveDirectory = await Directory.systemTemp.createTemp('devbudget_test_');
    Hive.init(hiveDirectory.path);

    /// Enregistre l'adaptateur pour le modèle ExpenseModel afin que Hive puisse sérialiser et désérialiser les objets ExpenseModel.
    Hive.registerAdapter(ExpenseModelAdapter());
    box = await Hive.openBox<ExpenseModel>('expenses');
  });

  tearDownAll(() async {
    /// Ferme la box Hive et supprime le répertoire temporaire après tous les tests pour nettoyer les ressources utilisées.
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
  });

  group('ExpenseRepository', () {
    late ExpenseRepository expenseRepository;

    setUp(() async {
      /// Nettoie la box avant chaque test pour éviter les interférences
      /// entre tests (données laissées par un test précédent).
      await box.clear();
      expenseRepository = ExpenseRepository();
    });

    test('add stores an expense and getAll returns it', () async {
      /// Crée deux instances d'ExpenseModel pour tester l'ajout et la récupération des dépenses.

      final expense1 = ExpenseModel(
        id: '1',
        title: 'Test Expense 1',
        amount: 100.0,
        category: 'Food',
        date: DateTime(2026, 1, 1),
        memberId: 'member1',
      );
      final expense2 = ExpenseModel(
        id: '2',
        title: 'Test Expense 2',
        amount: 200.0,
        category: 'Transport',
        date: DateTime(2026, 1, 2),
        memberId: 'member1',
      );

      /// Ajoute les dépenses à la box via le repository et vérifie que getAll retourne bien les dépenses ajoutées.
      await expenseRepository.add(expense1);
      await expenseRepository.add(expense2);

      final expenses = expenseRepository.getAll();

      expect(expenses.length, 2);
      expect(expenses, containsAll([expense1, expense2]));
    });

    /// Teste la méthode getById pour s'assurer qu'elle retourne la dépense correcte ou null si l'ID n'existe pas.

    test('getById returns the correct expense, or null if absent', () async {
      /// Crée une instance d'ExpenseModel pour tester la récupération par ID.
      final expense = ExpenseModel(
        id: '1',
        title: 'Test Expense 1',
        amount: 100.0,
        category: 'Food',
        date: DateTime(2026, 1, 1),
        memberId: 'member1',
      );

      await expenseRepository.add(expense);

      /// Récupère la dépense par ID et vérifie que la dépense retournée est correcte, et que la récupération d'un ID inexistant retourne null.
      final foundExpense = expenseRepository.getById('1');
      final missingExpense = expenseRepository.getById('unknown');

      expect(foundExpense, expense);
      expect(missingExpense, isNull);
    });

    /// Teste la méthode delete pour s'assurer qu'elle supprime correctement une dépense de la box.

    test('delete removes an expense from the box', () async {
      /// Crée une instance d'ExpenseModel pour tester la suppression.
      final expense = ExpenseModel(
        id: '1',
        title: 'Test Expense 1',
        amount: 100.0,
        category: 'Food',
        date: DateTime(2026, 1, 1),
        memberId: 'member1',
      );

      await expenseRepository.add(expense);
      expect(expenseRepository.getById('1'), isNotNull);

      await expenseRepository.delete('1');

      expect(expenseRepository.getById('1'), isNull);
      expect(expenseRepository.getAll(), isEmpty);
    });
  });
}
