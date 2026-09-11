import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logic/providers/expense_provider.dart';
import 'home_screen.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  static const _categoryColors = [
    Color(0xff176b87),
    Color(0xffe58f65),
    Color(0xff6c7a89),
    Color(0xffd9a441),
    Color(0xff7b9e87),
    Color(0xffa66a9f),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(expenseListProvider);
    final expenseNotifier = ref.read(expenseListProvider.notifier);
    final currency = CurrencyScope.of(context);
    final total =
        expenses.fold<double>(0, (sum, expense) => sum + expense.amount);
    final categories = expenseNotifier.totalsByCategory;
    final months = expenseNotifier.totalsByMonth();
    final topCategory = categories.entries.isEmpty
        ? null
        : (categories.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
            .first;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Text('Vue d’ensemble',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                )),
        const SizedBox(height: 4),
        const Text('Comprenez où part votre budget.'),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.payments_outlined,
                label: 'Total dépensé',
                value: '${total.toStringAsFixed(2)} ${currency.code}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                icon: Icons.category_outlined,
                label: 'Catégorie principale',
                value: topCategory?.key ?? 'Aucune',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (expenses.isEmpty)
          const _EmptyStats()
        else ...[
          _ChartCard(
            title: 'Dépenses par catégorie',
            subtitle: 'Répartition du montant total',
            child: SizedBox(
              height: 230,
              child: Row(
                children: [
                  Expanded(child: _CategoryChart(data: categories)),
                  Expanded(child: _CategoryLegend(data: categories)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _ChartCard(
            title: 'Évolution mensuelle',
            subtitle: 'Les six derniers mois',
            child: SizedBox(height: 230, child: _MonthlyChart(data: months)),
          ),
        ],
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetricCard(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 12),
              Text(label, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 4),
              Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      );
}

class _ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _ChartCard(
      {required this.title, required this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 2),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      );
}

class _CategoryChart extends StatelessWidget {
  final Map<String, double> data;

  const _CategoryChart({required this.data});

  @override
  Widget build(BuildContext context) => PieChart(
        PieChartData(
          sectionsSpace: 3,
          centerSpaceRadius: 42,
          sections: data.entries.toList().asMap().entries.map((entry) {
            final color = StatsScreen._categoryColors[
                entry.key % StatsScreen._categoryColors.length];
            return PieChartSectionData(
              value: entry.value.value,
              color: color,
              radius: 34,
              showTitle: false,
            );
          }).toList(),
        ),
      );
}

class _CategoryLegend extends StatelessWidget {
  final Map<String, double> data;

  const _CategoryLegend({required this.data});

  @override
  Widget build(BuildContext context) {
    final total = data.values.fold<double>(0, (sum, value) => sum + value);
    return ListView(
      padding: const EdgeInsets.only(left: 8),
      children: data.entries.toList().asMap().entries.map((entry) {
        final color = StatsScreen
            ._categoryColors[entry.key % StatsScreen._categoryColors.length];
        final percentage = total == 0 ? 0 : entry.value.value / total * 100;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              Container(width: 10, height: 10, color: color),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(entry.value.key,
                      maxLines: 1, overflow: TextOverflow.ellipsis)),
              Text('${percentage.toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _MonthlyChart extends StatelessWidget {
  final Map<DateTime, double> data;
  static const _monthLabels = [
    'janv.',
    'févr.',
    'mars',
    'avr.',
    'mai',
    'juin',
    'juil.',
    'août',
    'sept.',
    'oct.',
    'nov.',
    'déc.',
  ];

  const _MonthlyChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxValue = data.values.fold<double>(0, math.max);
    final ceiling = maxValue == 0 ? 100.0 : maxValue * 1.25;
    final months = data.keys.toList();

    return BarChart(
      BarChartData(
        maxY: ceiling,
        minY: 0,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                BarTooltipItem(
              '${rod.toY.toStringAsFixed(2)} ${CurrencyScope.of(context).code}',
              const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= months.length) {
                  return const SizedBox();
                }
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    _monthLabels[months[index].month - 1],
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: data.entries.toList().asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.value,
                width: 18,
                borderRadius: BorderRadius.circular(4),
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _EmptyStats extends StatelessWidget {
  const _EmptyStats();

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 20),
          child: Column(
            children: [
              Icon(Icons.insights_outlined,
                  size: 48, color: Theme.of(context).colorScheme.outline),
              const SizedBox(height: 12),
              const Text('Ajoutez une dépense pour voir vos graphiques.'),
            ],
          ),
        ),
      );
}
