import 'package:flutter/material.dart';
import 'package:currency_picker/currency_picker.dart';
import 'expenses_screen.dart';
import 'budget_screen.dart';
import 'stats_screen.dart';
import 'team_screen.dart';

class CurrencyScope extends InheritedNotifier<ValueNotifier<Currency>> {
  const CurrencyScope({
    super.key,
    required ValueNotifier<Currency> notifier,
    required super.child,
  }) : super(notifier: notifier);

  static Currency of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<CurrencyScope>();
    return scope!.notifier!.value;
  }

  static void update(BuildContext context, Currency currency) {
    final scope = context.findAncestorWidgetOfExactType<CurrencyScope>();
    scope?.notifier?.value = currency;
  }
}

class HomeScreen extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;

  const HomeScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  final _screens = const [
    ExpensesScreen(),
    BudgetScreen(),
    StatsScreen(),
    TeamScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final currency = CurrencyScope.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.account_balance_wallet_rounded, size: 25),
            SizedBox(width: 10),
            Text('DevBudget'),
          ],
        ),
        centerTitle: false,
        actions: [
          TextButton.icon(
            onPressed: () => showCurrencyPicker(
              context: context,
              showFlag: true,
              showCurrencyName: true,
              showCurrencyCode: true,
              onSelect: (selectedCurrency) =>
                  CurrencyScope.update(context, selectedCurrency),
            ),
            icon: const Icon(Icons.currency_exchange, size: 18),
            label: Text(currency.code),
          ),
          IconButton(
            tooltip: 'Changer de thème',
            onPressed: () => widget.onThemeChanged(!widget.isDarkMode),
            icon: Icon(widget.isDarkMode
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _screens[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.list), label: 'Dépenses'),
          NavigationDestination(icon: Icon(Icons.pie_chart), label: 'Budgets'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Stats'),
          NavigationDestination(
              icon: Icon(Icons.groups_outlined), label: 'Équipe'),
        ],
      ),
    );
  }
}
