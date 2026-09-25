import 'package:currency_picker/currency_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models/expense_model.dart';
import '../../logic/money.dart';
import '../../logic/notifications.dart';
import '../brand.dart';
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
  static const _incomeFilter = '__income';

  String _query = '';

  /// Filtre actif : vide = tout, [_incomeFilter] = revenus, sinon une catégorie.
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final expenses = ref.watch(expenseListProvider);
    final members = ref.watch(memberListProvider);
    final spending = ref.watch(spendingProvider);
    final total = ref.watch(totalExpensesProvider);
    final income = ref.watch(totalIncomeProvider);
    final currency = CurrencyScope.of(context);
    final scheme = Theme.of(context).colorScheme;

    final now = DateTime.now();
    final monthTotal = sumOf(spending
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .toList());
    final daysElapsed = now.day;

    final query = _query.trim().toLowerCase();
    final visible = expenses
        .where((e) =>
            (query.isEmpty ||
                e.title.toLowerCase().contains(query) ||
                e.category.toLowerCase().contains(query)) &&
            (_filter.isEmpty ||
                (_filter == _incomeFilter ? e.isIncome : e.category == _filter)))
        .toList()
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
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              gradient: heroGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: brandBlue.withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                            Icons.account_balance_wallet_outlined,
                            color: Colors.white),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total dépensé',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(color: Colors.white70)),
                            const SizedBox(height: 4),
                            Text(formatMoney(total, currency.code),
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white)),
                          ],
                        ),
                      ),
                      const Icon(Icons.trending_up, color: Colors.white),
                    ],
                  ),
                  if (income > 0) ...[
                    const SizedBox(height: 14),
                    Text(
                      'Revenus : ${formatMoney(income, currency.code)}'
                      ' · Solde : ${formatMoney(income - total, currency.code)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: income - total >= 0
                                ? Colors.greenAccent.shade100
                                : Colors.red.shade100,
                          ),
                    ),
                  ],
                  if (monthTotal > 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Ce mois-ci : ${formatMoney(monthTotal, currency.code)}'
                      ' · moyenne ${formatMoney(monthTotal / daysElapsed, currency.code)}/jour',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.white70),
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
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final (label, value) in [
                    ('Tout', ''),
                    ('Revenus', _incomeFilter),
                    for (final c in expenseCategories) (c, c),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(label),
                        selected: _filter == value,
                        showCheckmark: false,
                        labelStyle: TextStyle(
                            color: _filter == value ? Colors.white : null,
                            fontWeight: FontWeight.w600),
                        onSelected: (_) => setState(() => _filter = value),
                      ),
                    ),
                ],
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
                      message: '« ${expense.title} » supprimé(e)',
                      onUndo: () => notifier.addExpense(expense),
                    );
                  },
                  child: ExpenseTile(
                    title: expense.title,
                    category: expense.category,
                    date: expense.date,
                    amount: expense.amount,
                    currencyCode: expense.currency ?? defaultCurrency,
                    isIncome: expense.isIncome,
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

  /// Prévient si l'opération enregistrée fait passer un budget en alerte.
  void _alertBudgets(
    ScaffoldMessengerState messenger,
    ExpenseModel saved,
  ) {
    if (saved.isIncome) return;
    BudgetStatus? worst;
    for (final status in ref.read(budgetStatusesProvider).values) {
      if (status.isAlert &&
          budgetCounts(status.budget, saved) &&
          (worst == null || status.ratio > worst.ratio)) {
        worst = status;
      }
    }
    if (worst == null) return;
    final message = worst.isOver
        ? 'Budget « ${worst.budget.name} » dépassé !'
        : 'Budget « ${worst.budget.name} » à '
            '${(worst.ratio * 100).toStringAsFixed(0)} %';
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
    notifyBudgetAlert('Alerte budget', message);
  }

  Future<void> _showExpenseForm(
    BuildContext context,
    WidgetRef ref, {
    ExpenseModel? existing,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final titleController = TextEditingController(text: existing?.title);
    final amountController =
        TextEditingController(text: existing?.amount.toString());
    var currencyCode =
        existing == null ? CurrencyScope.of(context).code : existing.currency ?? defaultCurrency;
    var isIncome = existing?.isIncome ?? false;
    var category = existing?.category ?? expenseCategories.first;
    var date = existing?.date ?? DateTime.now();
    var memberId = existing?.memberId ?? personalMemberId;
    String? budgetId = existing?.budgetId;
    final formKey = GlobalKey<FormState>();
    final members = ref.read(memberListProvider);
    final budgets = ref.read(budgetListProvider);

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
          builder: (context, setState) {
            // Une catégorie disparue doit rester sélectionnable.
            final base = isIncome ? incomeCategories : expenseCategories;
            final categories =
                base.contains(category) ? base : [...base, category];
            return Form(
              key: formKey,
              child: Wrap(runSpacing: 12, children: [
                Text(
                    existing == null
                        ? 'Nouvelle opération'
                        : 'Modifier l’opération',
                    style: Theme.of(context).textTheme.titleLarge),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('Dépense')),
                      ButtonSegment(value: true, label: Text('Revenu')),
                    ],
                    selected: {isIncome},
                    onSelectionChanged: (value) => setState(() {
                      isIncome = value.first;
                      category = isIncome
                          ? incomeCategories.first
                          : expenseCategories.first;
                    }),
                  ),
                ),
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Libellé'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Saisissez un libellé'
                      : null,
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(labelText: 'Montant'),
                        validator: amountValidator,
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => showCurrencyPicker(
                        context: context,
                        showFlag: true,
                        showCurrencyName: true,
                        showCurrencyCode: true,
                        onSelect: (c) => setState(() => currencyCode = c.code),
                      ),
                      child: Text(currencyCode),
                    ),
                  ],
                ),
                DropdownButtonFormField<String>(
                  key: ValueKey(isIncome),
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
                    decoration: InputDecoration(
                        labelText: isIncome ? 'Reçu par' : 'Payé par'),
                    items: memberItems,
                    onChanged: (value) => setState(() => memberId = value!),
                  ),
                if (budgets.isNotEmpty && !isIncome)
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
                      lastDate:
                          DateTime.now().isAfter(date) ? DateTime.now() : date,
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
                    final effectiveBudget = isIncome ? null : budgetId;

                    final ExpenseModel saved;
                    if (existing == null) {
                      saved = ExpenseModel(
                        id: newId(),
                        title: title,
                        amount: amount,
                        category: category,
                        date: date,
                        memberId: memberId,
                        budgetId: effectiveBudget,
                        isIncome: isIncome,
                        currency: currencyCode,
                      );
                      await notifier.addExpense(saved);
                    } else {
                      saved = existing.copyWith(
                        title: title,
                        amount: amount,
                        category: category,
                        date: date,
                        memberId: memberId,
                        budgetId: effectiveBudget,
                        clearBudgetId: effectiveBudget == null,
                        isIncome: isIncome,
                        currency: currencyCode,
                      );
                      await notifier.updateExpense(saved);
                    }

                    _alertBudgets(messenger, saved);
                    if (!sheetContext.mounted) return;
                    Navigator.pop(sheetContext);
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Enregistrer'),
                ),
              ]),
            );
          },
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
