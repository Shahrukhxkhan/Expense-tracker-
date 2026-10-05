import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../data/models/derived_models.dart';

class PdfReportService {
  PdfReportService._();
  static final PdfReportService instance = PdfReportService._();

  Future<Uint8List> generateFinancialReport({
    required String title,
    required String subtitle,
    required List<TransactionWithDetails> transactions,
    required double totalIncome,
    required double totalExpense,
    required String currencySymbol,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('MMM dd, yyyy');

    final netSavings = totalIncome - totalExpense;
    final savingsRate = totalIncome > 0
        ? ((netSavings / totalIncome) * 100).clamp(0.0, 100.0)
        : 0.0;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'EXPENSE TRACKER FINANCIAL STATEMENT',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.indigo700,
                  ),
                ),
                pw.Text(
                  DateFormat('yyyy-MM-dd').format(DateTime.now()),
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                ),
              ],
            ),
            pw.Divider(thickness: 1, color: PdfColors.grey400),
            pw.SizedBox(height: 10),
          ],
        ),
        build: (context) => [
          // Title Banner
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  title,
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 4),
                pw.Text(subtitle, style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // Executive Summary Cards
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryBox(
                'Total Income',
                '$currencySymbol${totalIncome.toStringAsFixed(2)}',
                PdfColors.emerald700,
              ),
              pw.SizedBox(width: 10),
              _buildSummaryBox(
                'Total Expense',
                '$currencySymbol${totalExpense.toStringAsFixed(2)}',
                PdfColors.red700,
              ),
              pw.SizedBox(width: 10),
              _buildSummaryBox(
                'Net Cashflow',
                '$currencySymbol${netSavings.toStringAsFixed(2)}',
                netSavings >= 0 ? PdfColors.emerald700 : PdfColors.red700,
              ),
              pw.SizedBox(width: 10),
              _buildSummaryBox(
                'Savings Rate',
                '${savingsRate.toStringAsFixed(1)}%',
                PdfColors.indigo700,
              ),
            ],
          ),

          pw.SizedBox(height: 24),

          // Transaction Breakdown Table
          pw.Text(
            'Itemized Transaction Details (${transactions.length} records)',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),

          pw.TableHelper.fromTextArray(
            headers: ['Date', 'Title', 'Category', 'Account', 'Type', 'Amount'],
            data: transactions.take(40).map((item) {
              final tx = item.transaction;
              final isExp = tx.type.name.toLowerCase() == 'expense';
              return [
                dateFormat.format(tx.date),
                tx.title,
                item.category.name,
                item.account.name,
                tx.type.name.toUpperCase(),
                '${isExp ? "-" : "+"}$currencySymbol${(tx.amountMinor / 100.0).toStringAsFixed(2)}',
              ];
            }).toList(),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo600),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignment: pw.Alignment.centerLeft,
            cellHeight: 24,
            rowDecoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
              ),
            ),
          ),

          if (transactions.length > 40) ...[
            pw.SizedBox(height: 10),
            pw.Text(
              '* Showing 40 of ${transactions.length} records for page limits.',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
          ],
        ],
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Generated securely by Expense Tracker Offline Engine',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
            pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildSummaryBox(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
            pw.SizedBox(height: 4),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Print or share PDF directly
  Future<void> printReport(Uint8List pdfBytes, String filename) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: filename,
    );
  }
}
