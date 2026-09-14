import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../logic/providers/budget_provider.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgets = ref.watch(budgetListProvider);

    return ListView.builder(
      itemCount: budgets.length,
      itemBuilder: (context, i) {
        final b = budgets[i];
        return ListTile(
          title: Text(b.name),
          subtitle: const Text('\${b.startDate} - \${b.endDate}'),
          trailing: const Text('\${b.totalAmount.toStringAsFixed(2)}'),
        );
      },
    );
  }
}
