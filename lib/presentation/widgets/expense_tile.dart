import 'package:flutter/material.dart';
import '../../data/models/expense_model.dart';

class ExpenseTile extends StatelessWidget {
  final ExpenseModel expense;
  const ExpenseTile({super.key, required this.expense});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(expense.title),
      subtitle: Text(expense.category),
      trailing: const Text('\${expense.amount.toStringAsFixed(2)}'),
    );
  }
}
