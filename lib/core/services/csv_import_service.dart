import 'package:csv/csv.dart';
import '../../data/models/models.dart';

class CsvColumnMapping {
  int titleIndex;
  int amountIndex;
  int dateIndex;
  int? typeIndex;
  int? categoryIndex;
  int? noteIndex;

  CsvColumnMapping({
    this.titleIndex = 0,
    this.amountIndex = 1,
    this.dateIndex = 2,
    this.typeIndex,
    this.categoryIndex,
    this.noteIndex,
  });
}

class ImportedTransactionRecord {
  final String title;
  final int amountMinor;
  final TransactionType type;
  final DateTime date;
  final String? note;
  final String? rawCategory;

  const ImportedTransactionRecord({
    required this.title,
    required this.amountMinor,
    required this.type,
    required this.date,
    this.note,
    this.rawCategory,
  });
}

class CsvImportService {
  CsvImportService._();
  static final CsvImportService instance = CsvImportService._();

  /// Parse raw CSV string into rows
  List<List<dynamic>> parseCsvRaw(String rawCsv) {
    final lines = rawCsv.split(RegExp(r'\r?\n'));
    final rows = <List<dynamic>>[];
    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      // Split by comma preserving quoted sections
      final items = line.split(',').map((e) => e.replaceAll('"', '').trim()).toList();
      rows.add(items);
    }
    return rows;
  }

  /// Guess column indices automatically from header row
  CsvColumnMapping detectColumns(List<dynamic> headerRow) {
    final mapping = CsvColumnMapping();

    for (int i = 0; i < headerRow.length; i++) {
      final col = headerRow[i].toString().toLowerCase().trim();
      if (col.contains('title') || col.contains('description') || col.contains('name') || col.contains('payee')) {
        mapping.titleIndex = i;
      } else if (col.contains('amount') || col.contains('total') || col.contains('value')) {
        mapping.amountIndex = i;
      } else if (col.contains('date') || col.contains('time')) {
        mapping.dateIndex = i;
      } else if (col.contains('type')) {
        mapping.typeIndex = i;
      } else if (col.contains('category')) {
        mapping.categoryIndex = i;
      } else if (col.contains('note') || col.contains('memo')) {
        mapping.noteIndex = i;
      }
    }

    return mapping;
  }

  /// Convert parsed CSV rows into structured transactions using mapping
  List<ImportedTransactionRecord> convertRows({
    required List<List<dynamic>> rows,
    required CsvColumnMapping mapping,
    bool skipHeader = true,
  }) {
    final results = <ImportedTransactionRecord>[];
    final startIndex = skipHeader ? 1 : 0;

    for (int r = startIndex; r < rows.length; r++) {
      final row = rows[r];
      if (row.isEmpty) continue;

      try {
        final title = (mapping.titleIndex < row.length)
            ? row[mapping.titleIndex]?.toString().trim() ?? 'Expense'
            : 'Expense';

        final rawAmtStr = (mapping.amountIndex < row.length)
            ? row[mapping.amountIndex]?.toString() ?? '0'
            : '0';

        // Parse amount (support negative numbers or signs)
        final cleanAmt = rawAmtStr.replaceAll(RegExp(r'[^\d.-]'), '');
        final parsedDouble = double.tryParse(cleanAmt) ?? 0.0;
        final amountMinor = (parsedDouble.abs() * 100).round();

        // Determine transaction type (negative amount often means expense)
        TransactionType type = TransactionType.expense;
        if (mapping.typeIndex != null && mapping.typeIndex! < row.length) {
          final tStr = row[mapping.typeIndex!].toString().toLowerCase();
          if (tStr.contains('income') || tStr.contains('credit') || tStr.contains('deposit')) {
            type = TransactionType.income;
          }
        } else if (parsedDouble > 0 && cleanAmt.startsWith('+')) {
          type = TransactionType.income;
        }

        // Parse date
        DateTime date = DateTime.now();
        if (mapping.dateIndex < row.length) {
          final dStr = row[mapping.dateIndex]?.toString().trim() ?? '';
          date = DateTime.tryParse(dStr) ??
              _parseFlexibleDate(dStr) ??
              DateTime.now();
        }

        final note = (mapping.noteIndex != null && mapping.noteIndex! < row.length)
            ? row[mapping.noteIndex!]?.toString()
            : null;

        final rawCategory = (mapping.categoryIndex != null && mapping.categoryIndex! < row.length)
            ? row[mapping.categoryIndex!]?.toString()
            : null;

        if (amountMinor > 0) {
          results.add(
            ImportedTransactionRecord(
              title: title.isEmpty ? 'Imported Transaction' : title,
              amountMinor: amountMinor,
              type: type,
              date: date,
              note: note,
              rawCategory: rawCategory,
            ),
          );
        }
      } catch (_) {
        // Skip malformed rows gracefully
      }
    }

    return results;
  }

  DateTime? _parseFlexibleDate(String input) {
    try {
      final parts = input.split(RegExp(r'[/.-]'));
      if (parts.length == 3) {
        int y = int.parse(parts[0].length == 4 ? parts[0] : parts[2]);
        int m = int.parse(parts[1]);
        int d = int.parse(parts[0].length == 4 ? parts[2] : parts[0]);
        return DateTime(y, m, d);
      }
    } catch (_) {}
    return null;
  }
}
