import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../screens/home_screen.dart';

class ExpenseTile extends StatelessWidget {
  final String title;
  final String category;
  final DateTime date;
  final double amount;

  const ExpenseTile({
    super.key,
    required this.title,
    required this.category,
    required this.date,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    final currency = CurrencyScope.of(context);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        child: Icon(Icons.receipt_long,
            color: Theme.of(context).colorScheme.onSecondaryContainer),
      ),
      title: Text(title),
      subtitle: Text(
        '$category - ${DateFormat('dd/MM/yyyy').format(date)}',
      ),
      trailing: Text(
        '${amount.toStringAsFixed(2)} ${currency.code}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}
