import 'package:flutter/material.dart';

/// Convertit une saisie ("12,5" ou "12.5") en nombre, ou `null` si invalide.
double? parseAmount(String? value) =>
    double.tryParse((value ?? '').trim().replaceAll(',', '.'));

/// Validateur de montant : doit être un nombre strictement positif.
String? amountValidator(String? value) {
  final amount = parseAmount(value);
  if (amount == null) return 'Saisissez un montant valide';
  if (amount <= 0) return 'Le montant doit être supérieur à 0';
  return null;
}

/// Identifiant unique pour un nouvel enregistrement.
String newId() => DateTime.now().microsecondsSinceEpoch.toString();

/// Affiche un message avec une action « Annuler » après une suppression.
void showUndoSnackBar(
  BuildContext context, {
  required String message,
  required VoidCallback onUndo,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(label: 'Annuler', onPressed: onUndo),
      ),
    );
}

/// Icône associée à une catégorie de dépense.
IconData categoryIcon(String category) {
  switch (category) {
    case 'Alimentation':
      return Icons.restaurant_outlined;
    case 'Transport':
      return Icons.directions_bus_outlined;
    case 'Logement':
      return Icons.home_outlined;
    case 'Loisirs':
      return Icons.sports_esports_outlined;
    default:
      return Icons.receipt_long_outlined;
  }
}

const expenseCategories = [
  'Alimentation',
  'Transport',
  'Logement',
  'Loisirs',
  'Autre',
];
