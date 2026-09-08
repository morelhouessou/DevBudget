# DevBudget

Suivi de budget personnel et d'equipe, developpe en Flutter et Dart.

## Stack technique
- Flutter et Dart
- Persistance locale: Hive
- State management: Riverpod
- Visualisation: fl_chart

## Architecture

Le projet suit une architecture en couches:

- lib/data : modeles (ExpenseModel, BudgetModel, MemberModel) et repositories (acces a Hive)
- lib/logic : providers Riverpod, logique metier et gestion d'etat
- lib/presentation : ecrans (screens) et composants graphiques (widgets)

## Repartition des taches (4 lots)

### Lot 1 - Persistance et modeles de donnees
Membre en charge de Hive: definir les modeles (ExpenseModel, BudgetModel, MemberModel),
generer les adapters Hive, creer les repositories, et ecrire des tests simples
pour verifier l'ajout, la lecture et la suppression de donnees.

### Lot 2 - State management et logique metier
Membre en charge de Riverpod: creer les providers pour les depenses et les budgets,
gerer les calculs (total des depenses, solde restant par budget), et faire le lien
entre les repositories du Lot 1 et l'interface graphique.

### Lot 3 - Interface graphique principale
Membre en charge des ecrans: construire l'ecran d'accueil avec la navigation,
l'ecran de liste des depenses, l'ecran des budgets, ainsi que les formulaires
d'ajout et de modification (depense, budget).

### Lot 4 - Visualisation et finitions
Membre en charge des graphiques: integrer fl_chart pour visualiser les depenses
par categorie (camembert) et par mois (barres), soigner le theme visuel de
l'application, et preparer une courte demo ou des captures d'ecran pour la
presentation finale du projet.

## Chef de projet
Coordination generale, architecture, gestion du depot Git et du Discord,
integration des quatre lots dans la branche principale.
