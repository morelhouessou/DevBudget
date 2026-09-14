import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:devbudget/data/models/budget_model.dart';
import 'package:devbudget/data/repositories/budget_repository.dart';

void main() {
  /// Crée un répertoire temporaire pour Hive afin d'éviter les conflits avec les données existantes.
  late Directory hiveDirectory;
  late Box<BudgetModel> box;

  setUpAll(() async {
    /// Enregistre l'adaptateur pour le modèle BudgetModel afin que Hive puisse sérialiser et désérialiser les objets BudgetModel.
    hiveDirectory = await Directory.systemTemp.createTemp('devbudget_test_');
    Hive.init(hiveDirectory.path);

    Hive.registerAdapter(BudgetModelAdapter());
    box = await Hive.openBox<BudgetModel>('budgets');
  });

  /// Ferme la box Hive et supprime le répertoire temporaire après tous les tests pour nettoyer les ressources utilisées.
  tearDownAll(() async {
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
  });

  group('BudgetRepository', () {
    /// Nettoie la box avant chaque test pour éviter les interférences
    /// entre tests (données laissées par un test précédent).
    late BudgetRepository budgetRepository;

    setUp(() async {
      await box.clear();
      budgetRepository = BudgetRepository();
    });

    test('add stores a budget and getAll returns it', () async {
      /// Crée deux instances de BudgetModel pour tester l'ajout et la récupération des budgets.
      final budget1 = BudgetModel(
        id: '1',
        name: 'Budget Test 1',
        totalAmount: 500.0,
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 1, 31),
        ownerId: 'owner1',
      );
      final budget2 = BudgetModel(
        id: '2',
        name: 'Budget Test 2',
        totalAmount: 1000.0,
        startDate: DateTime(2026, 2, 1),
        endDate: DateTime(2026, 2, 28),
        ownerId: 'owner1',
      );

      await budgetRepository.add(budget1);
      await budgetRepository.add(budget2);

      /// Récupère tous les budgets et vérifie que les deux budgets ajoutés sont présents.
      final budgets = budgetRepository.getAll();

      expect(budgets.length, 2);
      expect(budgets, containsAll([budget1, budget2]));
    });

    test('getById returns the correct budget, or null if absent', () async {
      /// Crée une instance de BudgetModel pour tester la récupération par ID.
      final budget = BudgetModel(
        id: '1',
        name: 'Budget Test 1',
        totalAmount: 500.0,
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 1, 31),
        ownerId: 'owner1',
      );

      await budgetRepository.add(budget);

      final foundBudget = budgetRepository.getById('1');
      final missingBudget = budgetRepository.getById('unknown');

      expect(foundBudget, budget);
      expect(missingBudget, isNull);
    });

    test('delete removes a budget from the box', () async {
      /// Crée une instance de BudgetModel pour tester la suppression.
      final budget = BudgetModel(
        id: '1',
        name: 'Budget Test 1',
        totalAmount: 500.0,
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 1, 31),
        ownerId: 'owner1',
      );

      await budgetRepository.add(budget);
      expect(budgetRepository.getById('1'), isNotNull);

      await budgetRepository.delete('1');

      expect(budgetRepository.getById('1'), isNull);
      expect(budgetRepository.getAll(), isEmpty);
    });
  });
}
