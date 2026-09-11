import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../logic/providers/budget_provider.dart';
import 'home_screen.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgets = ref.watch(budgetListProvider);
    final currency = CurrencyScope.of(context);

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          Text('Mes budgets',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  )),
          const SizedBox(height: 4),
          const Text('Définissez vos limites et gardez le cap.'),
          const SizedBox(height: 16),
          if (budgets.isEmpty)
            Card(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
                child: Column(
                  children: [
                    Icon(Icons.account_balance_outlined,
                        size: 48, color: Theme.of(context).colorScheme.outline),
                    const SizedBox(height: 12),
                    Text('Aucun budget créé.',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text('Créez votre premier budget pour suivre vos limites.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            )
          else
            ...budgets.map((budget) => Dismissible(
                  key: ValueKey(budget.id),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: const Icon(Icons.delete_outline),
                  ),
                  onDismissed: (_) => ref
                      .read(budgetListProvider.notifier)
                      .deleteBudget(budget.id),
                  child: Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                          child: Icon(Icons.pie_chart_outline)),
                      title: Text(budget.name),
                      subtitle: Text(
                        '${DateFormat('dd/MM/yy').format(budget.startDate)} - '
                        '${DateFormat('dd/MM/yy').format(budget.endDate)}',
                      ),
                      trailing: Text(
                          '${budget.totalAmount.toStringAsFixed(2)} ${currency.code}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                )),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBudgetForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Budget'),
      ),
    );
  }

  Future<void> _showBudgetForm(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final currencyCode = CurrencyScope.of(context).code;
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.viewInsetsOf(sheetContext).bottom + 20,
        ),
        child: Form(
          key: formKey,
          child: Wrap(runSpacing: 12, children: [
            Text('Nouveau budget',
                style: Theme.of(context).textTheme.titleLarge),
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nom du budget'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Saisissez un nom'
                  : null,
            ),
            TextFormField(
              controller: amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration:
                  InputDecoration(labelText: 'Montant limite ($currencyCode)'),
              validator: (value) =>
                  double.tryParse((value ?? '').replaceAll(',', '.')) == null
                      ? 'Saisissez un montant valide'
                      : null,
            ),
            FilledButton.icon(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final now = DateTime.now();
                await ref.read(budgetListProvider.notifier).addBudgetFromForm(
                      name: nameController.text.trim(),
                      totalAmount: double.parse(
                          amountController.text.replaceAll(',', '.')),
                      startDate: DateTime(now.year, now.month, 1),
                      endDate: DateTime(now.year, now.month + 1, 0),
                    );
                if (!sheetContext.mounted) return;
                Navigator.pop(sheetContext);
              },
              icon: const Icon(Icons.check),
              label: const Text('Enregistrer'),
            ),
          ]),
        ),
      ),
    );
    nameController.dispose();
    amountController.dispose();
  }
}
