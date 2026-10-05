import 'dart:convert';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/data/models/derived_models.dart';
import 'package:intl/intl.dart';

class DataExportService {
  /// Generate a clean CSV string from transaction entries
  static String transactionsToCsv(List<TransactionWithDetails> transactions) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final rows = <List<dynamic>>[
      [
        'ID',
        'Title',
        'Type',
        'Amount',
        'Currency',
        'Category',
        'Account',
        'Date',
        'Note',
        'Receipt Attached',
      ]
    ];

    for (final item in transactions) {
      final tx = item.transaction;
      rows.add([
        tx.id,
        tx.title,
        tx.type.name.toUpperCase(),
        (tx.amountMinor / 100.0).toStringAsFixed(2),
        CurrencyFormatter.activeCurrencyCode,
        item.category.name,
        item.account.name,
        dateFormat.format(tx.date),
        tx.note ?? '',
        tx.receiptPath != null ? 'Yes' : 'No',
      ]);
    }

    final buffer = StringBuffer();
    for (final row in rows) {
      final line = row.map((cell) {
        final str = cell.toString().replaceAll('"', '""');
        return str.contains(',') || str.contains('"') || str.contains('\n')
            ? '"$str"'
            : str;
      }).join(',');
      buffer.writeln(line);
    }
    return buffer.toString();
  }

  /// Generate a formatted JSON string for data backup
  static String transactionsToJson(List<TransactionWithDetails> transactions) {
    final data = transactions.map((item) {
      final tx = item.transaction;
      return {
        'id': tx.id,
        'title': tx.title,
        'amountMinor': tx.amountMinor,
        'formattedAmount': (tx.amountMinor / 100.0).toStringAsFixed(2),
        'currency': CurrencyFormatter.activeCurrencyCode,
        'type': tx.type.name,
        'category': {
          'id': item.category.id,
          'name': item.category.name,
          'color': item.category.colorHex,
        },
        'account': {
          'id': item.account.id,
          'name': item.account.name,
          'type': item.account.type.name,
        },
        'date': tx.date.toIso8601String(),
        'note': tx.note,
        'hasReceipt': tx.receiptPath != null,
        'createdAt': tx.createdAt.toIso8601String(),
      };
    }).toList();

    return const JsonEncoder.withIndent('  ').convert({
      'version': '1.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'recordCount': data.length,
      'transactions': data,
    });
  }
}
