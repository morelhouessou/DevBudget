import 'dart:convert';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../data/models/expense_model.dart';
import 'money.dart';
import 'providers/budget_provider.dart';

final _dateFormat = DateFormat('dd/MM/yyyy');

/// Échappe une cellule CSV. Une valeur commençant par `=`, `+`, `-` ou `@`
/// serait interprétée comme une formule par Excel : on la neutralise.
String _csvCell(String value) {
  var text = value;
  if (text.isNotEmpty && '=+-@'.contains(text[0])) text = "'$text";
  if (text.contains(';') || text.contains('"') || text.contains('\n')) {
    text = '"${text.replaceAll('"', '""')}"';
  }
  return text;
}

/// Opérations les plus récentes d'abord.
List<ExpenseModel> _sorted(List<ExpenseModel> ops) =>
    [...ops]..sort((a, b) => b.date.compareTo(a.date));

/// Construit le CSV (séparateur `;` et décimale `,` pour Excel en français).
/// Les montants restent dans leur devise d'origine. Le BOM UTF-8 en tête
/// permet à Excel d'afficher correctement les accents.
String buildCsv(
  List<ExpenseModel> ops, {
  required Map<String, String> memberNames,
  required Map<String, String> budgetNames,
}) {
  final rows = <List<String>>[
    ['Date', 'Type', 'Libellé', 'Catégorie', 'Montant', 'Devise', 'Membre', 'Budget'],
    for (final e in _sorted(ops))
      [
        _dateFormat.format(e.date),
        e.isIncome ? 'Revenu' : 'Dépense',
        e.title,
        e.category,
        e.amount.toString().replaceAll('.', ','),
        e.currency ?? defaultCurrency,
        memberNames[e.memberId] ?? '',
        budgetNames[e.budgetId] ?? '',
      ],
  ];
  return '﻿${rows.map((r) => r.map(_csvCell).join(';')).join('\r\n')}\r\n';
}

// ponytail: le PDF utilise la police par défaut (Latin-1) ; pour des libellés
// dans d'autres alphabets, embarquer une police TTF via pw.Font.ttf.
String _pdfText(String value) =>
    value.replaceAll(' ', ' ').replaceAll(' ', ' ');

/// Construit le rapport PDF : synthèse, état des budgets, liste des opérations.
/// [total], [income] et les états de budget sont dans la devise [currencyCode].
Future<Uint8List> buildPdf(
  List<ExpenseModel> ops, {
  required Map<String, String> memberNames,
  required List<BudgetStatus> budgets,
  required double total,
  required double income,
  required String currencyCode,
}) async {
  final doc = pw.Document(title: 'Rapport DevBudget');
  const headerStyle = pw.TextStyle(fontWeight: pw.FontWeight.bold);
  const sectionStyle =
      pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold);

  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.all(32),
    build: (context) => [
      pw.Text('Rapport DevBudget',
          style:
              const pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
      pw.Text('Généré le ${_dateFormat.format(DateTime.now())}'),
      pw.SizedBox(height: 16),
      pw.Text('Synthèse', style: sectionStyle),
      pw.SizedBox(height: 6),
      pw.Text(_pdfText('Total dépensé : ${formatMoney(total, currencyCode)}')),
      pw.Text(_pdfText('Revenus : ${formatMoney(income, currencyCode)}')),
      pw.Text(_pdfText('Solde : ${formatMoney(income - total, currencyCode)}')),
      if (budgets.isNotEmpty) ...[
        pw.SizedBox(height: 16),
        pw.Text('Budgets', style: sectionStyle),
        pw.SizedBox(height: 6),
        pw.TableHelper.fromTextArray(
          headerStyle: headerStyle,
          headers: ['Budget', 'Limite', 'Dépensé', 'Reste', 'Utilisé'],
          data: [
            for (final s in budgets)
              [
                _pdfText(s.budget.name),
                _pdfText(formatMoney(s.total, currencyCode)),
                _pdfText(formatMoney(s.spent, currencyCode)),
                _pdfText(formatMoney(s.remaining, currencyCode)),
                '${(s.ratio * 100).toStringAsFixed(0)} %',
              ],
          ],
        ),
      ],
      pw.SizedBox(height: 16),
      pw.Text('Opérations', style: sectionStyle),
      pw.SizedBox(height: 6),
      pw.TableHelper.fromTextArray(
        headerStyle: headerStyle,
        headers: ['Date', 'Libellé', 'Catégorie', 'Membre', 'Montant'],
        cellAlignments: {4: pw.Alignment.centerRight},
        data: [
          for (final e in _sorted(ops))
            [
              _dateFormat.format(e.date),
              _pdfText(e.title),
              _pdfText(e.category),
              _pdfText(memberNames[e.memberId] ?? ''),
              _pdfText(
                  '${e.isIncome ? '+' : '-'}${formatMoney(e.amount, e.currency ?? defaultCurrency)}'),
            ],
        ],
      ),
    ],
  ));
  return doc.save();
}

/// Octets UTF-8 du CSV, prêts à être partagés comme fichier.
Uint8List csvBytes(String csv) => Uint8List.fromList(utf8.encode(csv));
