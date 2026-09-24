import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../screens/home_screen.dart';
import 'form_utils.dart';

class ExpenseTile extends StatelessWidget {
  final String title;
  final String category;
  final DateTime date;
  final double amount;
  final String? memberName;
  final VoidCallback? onTap;

  const ExpenseTile({
    super.key,
    required this.title,
    required this.category,
    required this.date,
    required this.amount,
    this.memberName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currency = CurrencyScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final details = [
      category,
      DateFormat('dd/MM/yyyy').format(date),
      if (memberName != null) memberName!,
    ].join(' - ');

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: scheme.secondaryContainer,
        child: Icon(categoryIcon(category), color: scheme.onSecondaryContainer),
      ),
      title: Text(title),
      subtitle: Text(details),
      trailing: Text(
        '${amount.toStringAsFixed(2)} ${currency.code}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}
