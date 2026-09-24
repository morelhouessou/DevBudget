import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../logic/export.dart';
import '../../logic/providers/budget_provider.dart';
import '../../logic/providers/currency_provider.dart';
import '../../logic/providers/expense_provider.dart';
import '../../logic/providers/member_provider.dart';
import '../screens/expenses_screen.dart' show personalMemberId;

enum _ExportFormat { csv, pdf }

/// Menu « Exporter » : partage un fichier CSV ou PDF de toutes les opérations.
class ExportButton extends ConsumerWidget {
  const ExportButton({super.key});

  Future<void> _export(
    BuildContext context,
    WidgetRef ref,
    _ExportFormat format,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final ops = ref.read(expenseListProvider);
    if (ops.isEmpty) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Aucune opération à exporter.')));
      return;
    }

    final memberNames = {
      personalMemberId: 'Moi',
      for (final m in ref.read(memberListProvider)) m.id: m.name,
    };
    final budgets = ref.read(budgetListProvider);
    final stamp = DateFormat('yyyyMMdd').format(DateTime.now());

    try {
      final Uint8List bytes;
      final String name;
      final String mime;
      if (format == _ExportFormat.csv) {
        bytes = csvBytes(buildCsv(
          ops,
          memberNames: memberNames,
          budgetNames: {for (final b in budgets) b.id: b.name},
        ));
        name = 'devbudget_$stamp.csv';
        mime = 'text/csv';
      } else {
        bytes = await buildPdf(
          ops,
          memberNames: memberNames,
          budgets: ref.read(budgetStatusesProvider).values.toList(),
          total: ref.read(totalExpensesProvider),
          income: ref.read(totalIncomeProvider),
          currencyCode: ref.read(displayCurrencyProvider),
        );
        name = 'devbudget_$stamp.pdf';
        mime = 'application/pdf';
      }
      await SharePlus.instance.share(ShareParams(
        files: [XFile.fromData(bytes, mimeType: mime)],
        fileNameOverrides: [name],
        downloadFallbackEnabled: true,
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Export impossible : $e')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      PopupMenuButton<_ExportFormat>(
        tooltip: 'Exporter',
        icon: const Icon(Icons.ios_share_outlined),
        onSelected: (format) => _export(context, ref, format),
        itemBuilder: (_) => const [
          PopupMenuItem(
            value: _ExportFormat.csv,
            child: ListTile(
              leading: Icon(Icons.table_chart_outlined),
              title: Text('Exporter en CSV'),
            ),
          ),
          PopupMenuItem(
            value: _ExportFormat.pdf,
            child: ListTile(
              leading: Icon(Icons.picture_as_pdf_outlined),
              title: Text('Exporter en PDF'),
            ),
          ),
        ],
      );
}
