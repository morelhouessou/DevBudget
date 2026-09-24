import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models/budget_model.dart';
import '../../logic/providers/budget_provider.dart';
import '../../logic/providers/expense_provider.dart';
import '../widgets/form_utils.dart';
import 'home_screen.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgets = ref.watch(budgetListProvider);
    final expenses = ref.watch(expenseListProvider);
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
            ...budgets.map((budget) {
              final spent = spentOfBudget(budget, expenses);
              return Dismissible(
                key: ValueKey(budget.id),
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24),
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: const Icon(Icons.delete_outline),
                ),
                direction: DismissDirection.endToStart,
                onDismissed: (_) async {
                  final notifier = ref.read(budgetListProvider.notifier);
                  await notifier.deleteBudget(budget.id);
                  if (!context.mounted) return;
                  showUndoSnackBar(
                    context,
                    message: 'Budget « ${budget.name} » supprimé',
                    onUndo: () => notifier.addBudget(budget),
                  );
                },
                child: _BudgetCard(
                  budget: budget,
                  spent: spent,
                  currencyCode: currency.code,
                  onTap: () => _showBudgetForm(context, ref, existing: budget),
                ),
              );
            }),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBudgetForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Budget'),
      ),
    );
  }

  Future<void> _showBudgetForm(
    BuildContext context,
    WidgetRef ref, {
    BudgetModel? existing,
  }) async {
    final nameController = TextEditingController(text: existing?.name);
    final amountController = TextEditingController(
        text: existing == null ? null : existing.totalAmount.toString());
    final currencyCode = CurrencyScope.of(context).code;
    final formKey = GlobalKey<FormState>();
    final now = DateTime.now();
    var start = existing?.startDate ?? DateTime(now.year, now.month, 1);
    var end = existing?.endDate ?? DateTime(now.year, now.month + 1, 0);
    final dateFormat = DateFormat('dd/MM/yyyy');

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
        child: StatefulBuilder(
          builder: (context, setState) => Form(
            key: formKey,
            child: Wrap(runSpacing: 12, children: [
              Text(existing == null ? 'Nouveau budget' : 'Modifier le budget',
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
                decoration: InputDecoration(
                    labelText: 'Montant limite ($currencyCode)'),
                validator: amountValidator,
              ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.event_outlined, size: 18),
                      label: Text('Début ${dateFormat.format(start)}'),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                          initialDate: start,
                        );
                        if (picked != null) {
                          setState(() {
                            start = picked;
                            if (end.isBefore(start)) end = start;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.event_available_outlined,
                          size: 18),
                      label: Text('Fin ${dateFormat.format(end)}'),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: start,
                          lastDate: DateTime(2100),
                          initialDate: end,
                        );
                        if (picked != null) setState(() => end = picked);
                      },
                    ),
                  ),
                ],
              ),
              FilledButton.icon(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final notifier = ref.read(budgetListProvider.notifier);
                  final name = nameController.text.trim();
                  final amount = parseAmount(amountController.text)!;
                  if (existing == null) {
                    await notifier.addBudget(BudgetModel(
                      id: newId(),
                      name: name,
                      totalAmount: amount,
                      startDate: start,
                      endDate: end,
                      ownerId: 'local-user',
                    ));
                  } else {
                    await notifier.updateBudget(existing.copyWith(
                      name: name,
                      totalAmount: amount,
                      startDate: start,
                      endDate: end,
                    ));
                  }

                  if (!sheetContext.mounted) return;
                  Navigator.pop(sheetContext);
                },
                icon: const Icon(Icons.check),
                label: const Text('Enregistrer'),
              ),
            ]),
          ),
        ),
      ),
    );
    nameController.dispose();
    amountController.dispose();
  }
}

class _BudgetCard extends StatelessWidget {
  final BudgetModel budget;
  final double spent;
  final String currencyCode;
  final VoidCallback onTap;

  const _BudgetCard({
    required this.budget,
    required this.spent,
    required this.currencyCode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total = budget.totalAmount;
    final ratio = total <= 0 ? 0.0 : spent / total;
    final over = ratio > 1;
    final color = over
        ? scheme.error
        : ratio >= 0.75
            ? Colors.orange.shade700
            : scheme.primary;
    final remaining = total - spent;
    final dateFormat = DateFormat('dd/MM/yy');

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: scheme.primaryContainer,
                    foregroundColor: scheme.onPrimaryContainer,
                    child: const Icon(Icons.pie_chart_outline),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(budget.name,
                            style: Theme.of(context).textTheme.titleMedium),
                        Text(
                          '${dateFormat.format(budget.startDate)} - '
                          '${dateFormat.format(budget.endDate)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Text('${total.toStringAsFixed(2)} $currencyCode',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: ratio.clamp(0.0, 1.0),
                  minHeight: 8,
                  color: color,
                  backgroundColor: scheme.surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${(ratio * 100).toStringAsFixed(0)} % utilisé',
                      style: Theme.of(context).textTheme.bodySmall),
                  if (over)
                    Text(
                        'Dépassé de ${(-remaining).toStringAsFixed(0)} $currencyCode',
                        style: TextStyle(
                            color: scheme.error, fontWeight: FontWeight.w700))
                  else
                    Text('Reste ${remaining.toStringAsFixed(0)} $currencyCode',
                        style: TextStyle(
                            color: color, fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
