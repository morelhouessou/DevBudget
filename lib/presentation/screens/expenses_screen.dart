import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../logic/providers/expense_provider.dart';

class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(expenseListProvider);

    return ListView.builder(
      itemCount: expenses.length,
      itemBuilder: (context, i) {
        final e = expenses[i];
        return ListTile(
          title: Text(e.title),
          subtitle: Text(e.category),
          trailing: const Text('\${e.amount.toStringAsFixed(2)}'),
        );
      },
    );
  }
}
