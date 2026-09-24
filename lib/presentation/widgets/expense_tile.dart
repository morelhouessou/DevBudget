import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../logic/money.dart';
import 'form_utils.dart';

class ExpenseTile extends StatelessWidget {
  final String title;
  final String category;
  final DateTime date;
  final double amount;

  /// Devise du montant (celle de la saisie, pas forcément l'affichage).
  final String currencyCode;
  final bool isIncome;
  final String? memberName;
  final VoidCallback? onTap;

  const ExpenseTile({
    super.key,
    required this.title,
    required this.category,
    required this.date,
    required this.amount,
    required this.currencyCode,
    this.isIncome = false,
    this.memberName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final details = [
      category,
      DateFormat('dd/MM/yyyy').format(date),
      if (memberName != null) memberName!,
    ].join(' - ');

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor:
            isIncome ? scheme.tertiaryContainer : scheme.secondaryContainer,
        child: Icon(categoryIcon(category),
            color: isIncome
                ? scheme.onTertiaryContainer
                : scheme.onSecondaryContainer),
      ),
      title: Text(title),
      subtitle: Text(details),
      trailing: Text(
        '${isIncome ? '+' : ''}${formatMoney(amount, currencyCode)}',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isIncome ? Colors.green.shade700 : null,
        ),
      ),
    );
  }
}
