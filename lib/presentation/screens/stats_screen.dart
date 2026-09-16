import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/expense_model.dart';
import '../../logic/providers/expense_provider.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(expenseListProvider);

    if (expenses.isEmpty) {
      return const Center(
        child: Text('Ajoutez une depense pour voir vos statistiques.'),
      );
    }

    final categoryTotals = totalsByCategory(expenses);
    final monthlyTotals = totalsByMonth(expenses);
    final total =
        expenses.fold<double>(0, (sum, expense) => sum + expense.amount);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        Text('Vue d\'ensemble',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(
          '${total.toStringAsFixed(2)} EUR depenses',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 24),
        _ChartPanel(
          title: 'Depenses par categorie',
          child: _CategoryChart(totals: categoryTotals, total: total),
        ),
        const SizedBox(height: 16),
        _ChartPanel(
          title: 'Depenses par mois',
          child: _MonthlyChart(totals: monthlyTotals),
        ),
      ],
    );
  }
}

Map<String, double> totalsByCategory(List<ExpenseModel> expenses) {
  final totals = <String, double>{};
  for (final expense in expenses) {
    totals.update(
      expense.category,
      (value) => value + expense.amount,
      ifAbsent: () => expense.amount,
    );
  }
  return totals;
}

List<double> totalsByMonth(List<ExpenseModel> expenses) {
  final now = DateTime.now();
  final firstMonth = DateTime(now.year, now.month - 5);
  final totals = List<double>.filled(6, 0);

  for (final expense in expenses) {
    final monthIndex = (expense.date.year - firstMonth.year) * 12 +
        expense.date.month -
        firstMonth.month;
    if (monthIndex >= 0 && monthIndex < totals.length) {
      totals[monthIndex] += expense.amount;
    }
  }
  return totals;
}

class _ChartPanel extends StatelessWidget {
  const _ChartPanel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}

class _CategoryChart extends StatelessWidget {
  const _CategoryChart({required this.totals, required this.total});

  final Map<String, double> totals;
  final double total;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = [
      scheme.primary,
      scheme.secondary,
      scheme.tertiary,
      scheme.error,
      scheme.primaryContainer,
      scheme.secondaryContainer,
    ];
    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(
              centerSpaceRadius: 52,
              sectionsSpace: 3,
              sections: [
                for (var index = 0; index < entries.length; index++)
                  PieChartSectionData(
                    value: entries[index].value,
                    color: colors[index % colors.length],
                    radius: 72,
                    title: '${(entries[index].value / total * 100).round()}%',
                    titleStyle: TextStyle(
                      color: scheme.onPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 8,
          children: [
            for (var index = 0; index < entries.length; index++)
              _LegendItem(
                label: entries[index].key,
                color: colors[index % colors.length],
              ),
          ],
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}

class _MonthlyChart extends StatelessWidget {
  const _MonthlyChart({required this.totals});

  final List<double> totals;

  static const _monthLabels = [
    'Jan',
    'Fev',
    'Mar',
    'Avr',
    'Mai',
    'Jun',
    'Jui',
    'Aou',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final firstMonth = DateTime(now.year, now.month - 5);
    final maximum = totals.reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 250,
      child: BarChart(
        BarChartData(
          maxY: maximum == 0 ? 1 : maximum * 1.2,
          alignment: BarChartAlignment.spaceAround,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barTouchData: const BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 42),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= totals.length) {
                    return const SizedBox.shrink();
                  }
                  final month =
                      DateTime(firstMonth.year, firstMonth.month + index);
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(_monthLabels[month.month - 1]),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var index = 0; index < totals.length; index++)
              BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: totals[index],
                    width: 18,
                    color: scheme.primary,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
