import 'package:expense_tracker/data/models/derived_models.dart';
import 'package:expense_tracker/data/models/models.dart';
import 'package:expense_tracker/data/repositories/expense_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Repository singleton provider.
final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository();
});

/// Ticks whenever database data changes to trigger reactive refreshes.
final dataChangeStreamProvider = StreamProvider<void>((ref) {
  final repo = ref.watch(expenseRepositoryProvider);
  return repo.onDataChanged;
});

/// Current balance in minor units (cents).
final currentBalanceProvider = FutureProvider<int>((ref) async {
  ref.watch(dataChangeStreamProvider);
  final repo = ref.watch(expenseRepositoryProvider);
  return repo.getCurrentBalanceMinor();
});

/// Current month summary (Total Income & Expense).
final currentMonthTotalsProvider = FutureProvider<({int incomeMinor, int expenseMinor})>((ref) async {
  ref.watch(dataChangeStreamProvider);
  final repo = ref.watch(expenseRepositoryProvider);
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, 1);
  final end = DateTime(now.year, now.month + 1, 1).subtract(const Duration(milliseconds: 1));
  return repo.getTotalsByDateRange(start, end);
});

/// Top 5 most recent transactions.
final recentTransactionsProvider = FutureProvider<List<TransactionWithDetails>>((ref) async {
  ref.watch(dataChangeStreamProvider);
  final repo = ref.watch(expenseRepositoryProvider);
  return repo.getTransactions(limit: 5);
});

/// All transactions without pagination for exports, reports, and backups.
final allTransactionsProvider = FutureProvider<List<TransactionWithDetails>>((ref) async {
  ref.watch(dataChangeStreamProvider);
  final repo = ref.watch(expenseRepositoryProvider);
  return repo.getTransactions();
});

/// 6-month monthly cashflow history.
final monthlyFlowHistoryProvider = FutureProvider<List<MonthlyFlowSummary>>((ref) async {
  ref.watch(dataChangeStreamProvider);
  final repo = ref.watch(expenseRepositoryProvider);
  return repo.getMonthlyFlowHistory(6);
});

/// Category spending for the current month.
final categorySpendingProvider = FutureProvider<List<CategorySpendingSummary>>((ref) async {
  ref.watch(dataChangeStreamProvider);
  final repo = ref.watch(expenseRepositoryProvider);
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, 1);
  final end = DateTime(now.year, now.month + 1, 1).subtract(const Duration(milliseconds: 1));
  return repo.getCategorySpending(start: start, end: end);
});

/// Active filter state for the transaction list.
class TransactionFilterState {
  final String searchQuery;
  final TransactionType? type;
  final String? categoryId;
  final String? accountId;
  final DateTime? startDate;
  final DateTime? endDate;

  const TransactionFilterState({
    this.searchQuery = '',
    this.type,
    this.categoryId,
    this.accountId,
    this.startDate,
    this.endDate,
  });

  TransactionFilterState copyWith({
    String? searchQuery,
    TransactionType? type,
    bool clearType = false,
    String? categoryId,
    bool clearCategory = false,
    String? accountId,
    bool clearAccount = false,
    DateTime? startDate,
    DateTime? endDate,
    bool clearDates = false,
  }) {
    return TransactionFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      type: clearType ? null : (type ?? this.type),
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      accountId: clearAccount ? null : (accountId ?? this.accountId),
      startDate: clearDates ? null : (startDate ?? this.startDate),
      endDate: clearDates ? null : (endDate ?? this.endDate),
    );
  }
}

final transactionFilterProvider = StateProvider<TransactionFilterState>((ref) {
  return const TransactionFilterState();
});

/// Filtered transactions grouped by day.
final filteredTransactionsProvider = FutureProvider<List<DailyTransactionGroup>>((ref) async {
  ref.watch(dataChangeStreamProvider);
  final repo = ref.watch(expenseRepositoryProvider);
  final filter = ref.watch(transactionFilterProvider);

  final items = await repo.getTransactions(
    searchQuery: filter.searchQuery,
    type: filter.type,
    categoryId: filter.categoryId,
    accountId: filter.accountId,
    startDate: filter.startDate,
    endDate: filter.endDate,
  );

  // Group items by Day
  final Map<String, List<TransactionWithDetails>> grouped = {};
  for (final item in items) {
    final key = '${item.transaction.date.year}-${item.transaction.date.month.toString().padLeft(2, '0')}-${item.transaction.date.day.toString().padLeft(2, '0')}';
    grouped.putIfAbsent(key, () => []).add(item);
  }

  final groups = <DailyTransactionGroup>[];
  for (final entry in grouped.entries) {
    final dayItems = entry.value;
    int income = 0;
    int expense = 0;
    for (final it in dayItems) {
      if (it.transaction.type == TransactionType.income) {
        income += it.transaction.amountMinor;
      } else {
        expense += it.transaction.amountMinor;
      }
    }
    groups.add(DailyTransactionGroup(
      date: dayItems.first.transaction.date,
      items: dayItems,
      totalIncomeMinor: income,
      totalExpenseMinor: expense,
    ));
  }

  return groups;
});

/// Category list provider.
final categoriesProvider = FutureProvider.family<List<Category>, TransactionType?>((ref, type) async {
  ref.watch(dataChangeStreamProvider);
  final repo = ref.watch(expenseRepositoryProvider);
  return repo.getAllCategories(type: type);
});

/// Account list provider.
final accountsProvider = FutureProvider<List<Account>>((ref) async {
  ref.watch(dataChangeStreamProvider);
  final repo = ref.watch(expenseRepositoryProvider);
  return repo.getAllAccounts();
});

/// Specific account balance provider.
final accountBalanceProvider = FutureProvider.family<int, String>((ref, accountId) async {
  ref.watch(dataChangeStreamProvider);
  final repo = ref.watch(expenseRepositoryProvider);
  return repo.getAccountBalanceMinor(accountId);
});

/// Selected month/year for budget view ('YYYY-MM').
final selectedBudgetMonthProvider = StateProvider<String>((ref) {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}';
});

/// Budgets with progress provider.
final budgetsProvider = FutureProvider<List<BudgetProgress>>((ref) async {
  ref.watch(dataChangeStreamProvider);
  final repo = ref.watch(expenseRepositoryProvider);
  final monthYear = ref.watch(selectedBudgetMonthProvider);
  return repo.getBudgetsWithProgress(monthYear);
});

/// Recurring transactions provider.
final recurringTransactionsProvider = FutureProvider<List<RecurringTransactionWithDetails>>((ref) async {
  ref.watch(dataChangeStreamProvider);
  final repo = ref.watch(expenseRepositoryProvider);
  return repo.getAllRecurringTransactions();
});

/// Theme mode provider.
final themeModeProvider = StateProvider<bool>((ref) => false); // false = light, true = dark

