import 'package:expense_tracker/data/models/models.dart';

/// Computed total and percentage for a single category within a period.
class CategorySpendingSummary {
  final Category category;
  final int totalSpentMinor;
  final double percentage;

  const CategorySpendingSummary({
    required this.category,
    required this.totalSpentMinor,
    required this.percentage,
  });
}

/// Computed budget progress for category spending in a given month.
class BudgetProgress {
  final Budget budget;
  final Category category;
  final int spentMinor;

  const BudgetProgress({
    required this.budget,
    required this.category,
    required this.spentMinor,
  });

  int get remainingMinor => budget.limitMinor - spentMinor;
  double get ratio => budget.limitMinor == 0 ? 0.0 : spentMinor / budget.limitMinor;
  bool get isAmber => ratio >= 0.8 && ratio < 1.0;
  bool get isRed => ratio >= 1.0;
}

/// Monthly cash flow summary.
class MonthlyFlowSummary {
  final String monthLabel;
  final int totalIncomeMinor;
  final int totalExpenseMinor;

  const MonthlyFlowSummary({
    required this.monthLabel,
    required this.totalIncomeMinor,
    required this.totalExpenseMinor,
  });

  int get netSavingsMinor => totalIncomeMinor - totalExpenseMinor;
}

/// Daily group of transactions for grouped list displays.
class DailyTransactionGroup {
  final DateTime date;
  final List<TransactionWithDetails> items;
  final int totalIncomeMinor;
  final int totalExpenseMinor;

  const DailyTransactionGroup({
    required this.date,
    required this.items,
    required this.totalIncomeMinor,
    required this.totalExpenseMinor,
  });
}

/// Full transaction with resolved category and account metadata.
class TransactionWithDetails {
  final Transaction transaction;
  final Category category;
  final Account account;

  const TransactionWithDetails({
    required this.transaction,
    required this.category,
    required this.account,
  });
}
