import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models/expense_model.dart';
import '../../logic/providers/budget_provider.dart';
import '../../logic/providers/expense_provider.dart';
import '../../logic/providers/member_provider.dart';
import 'home_screen.dart';
import '../widgets/expense_tile.dart';
import '../widgets/form_utils.dart';

/// Identifiant du « membre » utilisé pour les dépenses personnelles.
const personalMemberId = 'personal';

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final expenses = ref.watch(expenseListProvider);
    final members = ref.watch(memberListProvider);
    final total = expenses.fold<double>(0, (sum, item) => sum + item.amount);
    final currency = CurrencyScope.of(context);
    final scheme = Theme.of(context).colorScheme;

    final now = DateTime.now();
    final monthTotal = expenses
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .fold<double>(0, (sum, e) => sum + e.amount);
    final daysElapsed = now.day;

    final query = _query.trim().toLowerCase();
    final visible = (query.isEmpty
        ? [...expenses]
        : expenses
            .where((e) =>
                e.title.toLowerCase().contains(query) ||
                e.category.toLowerCase().contains(query))
            .toList())
      ..sort((a, b) => b.date.compareTo(a.date));

    String? memberName(String id) {
      for (final member in members) {
        if (member.id == id) return member.name;
      }
      return null;
    }

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(Icons.account_balance_wallet_outlined,
                            color: scheme.onPrimaryContainer),
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
                      Icon(Icons.trending_up, color: scheme.primary),
                    ],
                  ),
                  if (monthTotal > 0) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Ce mois-ci : ${monthTotal.toStringAsFixed(0)} ${currency.code}'
                      ' · moyenne ${(monthTotal / daysElapsed).toStringAsFixed(0)}/jour',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (expenses.isNotEmpty) ...[
            const SizedBox(height: 4),
            TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(
                hintText: 'Rechercher une dépense',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (expenses.isEmpty)
            const _EmptyState(
              icon: Icons.receipt_long_outlined,
              message: 'Aucune dépense pour le moment.',
            )
          else if (visible.isEmpty)
            const _EmptyState(
              icon: Icons.search_off,
              message: 'Aucun résultat pour cette recherche.',
            )
          else
            ...visible.map((expense) => Dismissible(
                  key: ValueKey(expense.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    color: scheme.errorContainer,
                    child: const Icon(Icons.delete_outline),
                  ),
                  onDismissed: (_) async {
                    final notifier = ref.read(expenseListProvider.notifier);
                    await notifier.deleteExpense(expense.id);
                    if (!context.mounted) return;
                    showUndoSnackBar(
                      context,
                      message: 'Dépense « ${expense.title} » supprimée',
                      onUndo: () => notifier.addExpense(expense),
                    );
                  },
                  child: ExpenseTile(
                    title: expense.title,
                    category: expense.category,
                    date: expense.date,
                    amount: expense.amount,
                    memberName: memberName(expense.memberId),
                    onTap: () =>
                        _showExpenseForm(context, ref, existing: expense),
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

  Future<void> _showExpenseForm(
    BuildContext context,
    WidgetRef ref, {
    ExpenseModel? existing,
  }) async {
    final titleController = TextEditingController(text: existing?.title);
    final amountController = TextEditingController(
        text: existing == null ? null : existing.amount.toString());
    final currencyCode = CurrencyScope.of(context).code;
    var category = existing?.category ?? expenseCategories.first;
    var date = existing?.date ?? DateTime.now();
    var memberId = existing?.memberId ?? personalMemberId;
    String? budgetId = existing?.budgetId;
    final formKey = GlobalKey<FormState>();
    final members = ref.read(memberListProvider);
    final budgets = ref.read(budgetListProvider);

    // Une catégorie ou un membre disparu doit rester sélectionnable.
    final categories = expenseCategories.contains(category)
        ? expenseCategories
        : [...expenseCategories, category];
    final memberItems = <DropdownMenuItem<String>>[
      const DropdownMenuItem(value: personalMemberId, child: Text('Moi')),
      ...members.map(
          (m) => DropdownMenuItem(value: m.id, child: Text(m.name))),
      if (memberId != personalMemberId && !members.any((m) => m.id == memberId))
        DropdownMenuItem(value: memberId, child: const Text('Ancien membre')),
    ];
    if (budgetId != null && !budgets.any((b) => b.id == budgetId)) {
      budgetId = null;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SingleChildScrollView(
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
              Text(existing == null ? 'Nouvelle dépense' : 'Modifier la dépense',
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
                validator: amountValidator,
              ),
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: const InputDecoration(labelText: 'Catégorie'),
                items: categories
                    .map((item) =>
                        DropdownMenuItem(value: item, child: Text(item)))
                    .toList(),
                onChanged: (value) => setState(() => category = value!),
              ),
              if (members.isNotEmpty)
                DropdownButtonFormField<String>(
                  initialValue: memberId,
                  decoration: const InputDecoration(labelText: 'Payé par'),
                  items: memberItems,
                  onChanged: (value) => setState(() => memberId = value!),
                ),
              if (budgets.isNotEmpty)
                DropdownButtonFormField<String?>(
                  initialValue: budgetId,
                  decoration: const InputDecoration(labelText: 'Budget'),
                  items: [
                    const DropdownMenuItem<String?>(
                        value: null, child: Text('Selon la période')),
                    ...budgets.map((b) => DropdownMenuItem<String?>(
                        value: b.id, child: Text(b.name))),
                  ],
                  onChanged: (value) => setState(() => budgetId = value),
                ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_outlined),
                title: Text(DateFormat('dd/MM/yyyy').format(date)),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().isAfter(date)
                        ? DateTime.now()
                        : date,
                    initialDate: date,
                  );
                  if (picked != null) setState(() => date = picked);
                },
              ),
              FilledButton.icon(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final notifier = ref.read(expenseListProvider.notifier);
                  final title = titleController.text.trim();
                  final amount = parseAmount(amountController.text)!;

                  if (existing == null) {
                    await notifier.addExpense(ExpenseModel(
                      id: newId(),
                      title: title,
                      amount: amount,
                      category: category,
                      date: date,
                      memberId: memberId,
                      budgetId: budgetId,
                    ));
                  } else {
                    await notifier.updateExpense(existing.copyWith(
                      title: title,
                      amount: amount,
                      category: category,
                      date: date,
                      memberId: memberId,
                      budgetId: budgetId,
                      clearBudgetId: budgetId == null,
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
