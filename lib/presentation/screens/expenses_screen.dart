import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../logic/providers/expense_provider.dart';
import 'home_screen.dart';
import '../widgets/expense_tile.dart';

class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(expenseListProvider);
    final total = expenses.fold<double>(0, (sum, item) => sum + item.amount);
    final currency = CurrencyScope.of(context);

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          Text('Mes dépenses',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  )),
          const SizedBox(height: 4),
          Text('${expenses.length} opération(s) enregistrée(s)'),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.account_balance_wallet_outlined,
                        color:
                            Theme.of(context).colorScheme.onPrimaryContainer),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total dépensé',
                            style: Theme.of(context).textTheme.labelLarge),
                        const SizedBox(height: 4),
                        Text('${total.toStringAsFixed(2)} ${currency.code}',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  Icon(Icons.trending_up,
                      color: Theme.of(context).colorScheme.primary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (expenses.isEmpty)
            const _EmptyState(
              icon: Icons.receipt_long_outlined,
              message: 'Aucune dépense pour le moment.',
            )
          else
            ...expenses.map((expense) => Dismissible(
                  key: ValueKey(expense.id),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: const Icon(Icons.delete_outline),
                  ),
                  onDismissed: (_) => ref
                      .read(expenseListProvider.notifier)
                      .deleteExpense(expense.id),
                  child: ExpenseTile(
                    title: expense.title,
                    category: expense.category,
                    date: expense.date,
                    amount: expense.amount,
                  ),
                )),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showExpenseForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Dépense'),
      ),
    );
  }

  Future<void> _showExpenseForm(BuildContext context, WidgetRef ref) async {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final currencyCode = CurrencyScope.of(context).code;
    var category = 'Alimentation';
    var date = DateTime.now();
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
        child: StatefulBuilder(
          builder: (context, setState) => Form(
            key: formKey,
            child: Wrap(runSpacing: 12, children: [
              Text('Nouvelle dépense',
                  style: Theme.of(context).textTheme.titleLarge),
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Libellé'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Saisissez un libellé'
                    : null,
              ),
              TextFormField(
                controller: amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration:
                    InputDecoration(labelText: 'Montant ($currencyCode)'),
                validator: (value) =>
                    double.tryParse((value ?? '').replaceAll(',', '.')) == null
                        ? 'Saisissez un montant valide'
                        : null,
              ),
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: const InputDecoration(labelText: 'Catégorie'),
                items: const [
                  'Alimentation',
                  'Transport',
                  'Logement',
                  'Loisirs',
                  'Autre'
                ]
                    .map((item) =>
                        DropdownMenuItem(value: item, child: Text(item)))
                    .toList(),
                onChanged: (value) => setState(() => category = value!),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_outlined),
                title: Text(DateFormat('dd/MM/yyyy').format(date)),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    initialDate: date,
                  );
                  if (picked != null) setState(() => date = picked);
                },
              ),
              FilledButton.icon(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  await ref
                      .read(expenseListProvider.notifier)
                      .addExpenseFromForm(
                        title: titleController.text.trim(),
                        amount: double.parse(
                            amountController.text.replaceAll(',', '.')),
                        category: category,
                        date: date,
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
      ),
    );
    titleController.dispose();
    amountController.dispose();
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 56),
        child: Column(children: [
          Icon(icon, size: 48, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 12),
          Text(message),
        ]),
      );
}
