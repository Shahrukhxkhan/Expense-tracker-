import 'dart:async';
import 'package:expense_tracker/data/database/app_database.dart';
import 'package:expense_tracker/data/models/derived_models.dart';
import 'package:expense_tracker/data/models/models.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart' hide Transaction;

/// Repository for handling all persistence, queries, calculations, and mutations.
class ExpenseRepository {
  final AppDatabase _dbProvider;

  // Stream controllers to broadcast real-time updates when mutations occur
  final _dataChangeController = StreamController<void>.broadcast();

  ExpenseRepository({AppDatabase? dbProvider})
      : _dbProvider = dbProvider ?? AppDatabase.instance;

  Stream<void> get onDataChanged => _dataChangeController.stream;

  void _notifyChanged() {
    _dataChangeController.add(null);
  }

  // ===================== ACCOUNTS =====================

  Future<List<Account>> getAllAccounts() async {
    final db = await _dbProvider.database;
    final maps = await db.query('accounts', orderBy: 'name ASC');
    return maps.map(Account.fromMap).toList();
  }

  Future<void> insertAccount(Account account) async {
    final db = await _dbProvider.database;
    await db.insert(
      'accounts',
      account.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _notifyChanged();
  }

  // ===================== CATEGORIES =====================

  Future<List<Category>> getAllCategories({TransactionType? type}) async {
    final db = await _dbProvider.database;
    final where = type != null ? 'type = ?' : null;
    final whereArgs = type != null ? [type.name] : null;

    final maps = await db.query(
      'categories',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'name ASC',
    );
    return maps.map(Category.fromMap).toList();
  }

  Future<void> insertCategory(Category category) async {
    final db = await _dbProvider.database;
    await db.insert(
      'categories',
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _notifyChanged();
  }

  Future<void> deleteCategory(String id) async {
    final db = await _dbProvider.database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
    _notifyChanged();
  }

  // ===================== TRANSACTIONS =====================

  Future<void> insertTransaction(Transaction transaction) async {
    if (transaction.amountMinor <= 0) {
      throw ArgumentError('Amount must be positive');
    }
    if (transaction.title.trim().isEmpty) {
      throw ArgumentError('Title cannot be empty');
    }

    final db = await _dbProvider.database;
    await db.insert(
      'transactions',
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _notifyChanged();
  }

  Future<void> updateTransaction(Transaction transaction) async {
    if (transaction.amountMinor <= 0) {
      throw ArgumentError('Amount must be positive');
    }
    if (transaction.title.trim().isEmpty) {
      throw ArgumentError('Title cannot be empty');
    }

    final db = await _dbProvider.database;
    await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
    _notifyChanged();
  }

  Future<void> deleteTransaction(String id) async {
    final db = await _dbProvider.database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
    _notifyChanged();
  }

  Future<List<TransactionWithDetails>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    TransactionType? type,
    String? searchQuery,
    int? limit,
  }) async {
    final db = await _dbProvider.database;

    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (startDate != null) {
      whereClauses.add('t.date >= ?');
      whereArgs.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      whereClauses.add('t.date <= ?');
      whereArgs.add(endDate.toIso8601String());
    }
    if (categoryId != null && categoryId.isNotEmpty) {
      whereClauses.add('t.categoryId = ?');
      whereArgs.add(categoryId);
    }
    if (type != null) {
      whereClauses.add('t.type = ?');
      whereArgs.add(type.name);
    }
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      whereClauses.add('(t.title LIKE ? OR t.note LIKE ?)');
      final term = '%${searchQuery.trim()}%';
      whereArgs.add(term);
      whereArgs.add(term);
    }

    final whereSql = whereClauses.isNotEmpty ? 'WHERE ${whereClauses.join(' AND ')}' : '';
    final limitSql = limit != null ? 'LIMIT $limit' : '';

    final query = '''
      SELECT 
        t.id AS t_id, t.title AS t_title, t.amountMinor AS t_amountMinor,
        t.type AS t_type, t.categoryId AS t_categoryId, t.accountId AS t_accountId,
        t.date AS t_date, t.note AS t_note, t.createdAt AS t_createdAt,
        c.id AS c_id, c.name AS c_name, c.type AS c_type,
        c.iconCodePoint AS c_iconCodePoint, c.colorHex AS c_colorHex, c.createdAt AS c_createdAt,
        a.id AS a_id, a.name AS a_name, a.type AS a_type,
        a.initialBalanceMinor AS a_initialBalanceMinor, a.colorHex AS a_colorHex,
        a.iconCodePoint AS a_iconCodePoint, a.isDefault AS a_isDefault, a.createdAt AS a_createdAt
      FROM transactions t
      JOIN categories c ON t.categoryId = c.id
      JOIN accounts a ON t.accountId = a.id
      $whereSql
      ORDER BY t.date DESC, t.createdAt DESC
      $limitSql
    ''';

    final rows = await db.rawQuery(query, whereArgs);

    return rows.map((row) {
      final transaction = Transaction(
        id: row['t_id'] as String,
        title: row['t_title'] as String,
        amountMinor: (row['t_amountMinor'] as num).toInt(),
        type: TransactionType.fromString(row['t_type'] as String),
        categoryId: row['t_categoryId'] as String,
        accountId: row['t_accountId'] as String,
        date: DateTime.parse(row['t_date'] as String),
        note: row['t_note'] as String?,
        createdAt: DateTime.parse(row['t_createdAt'] as String),
      );

      final category = Category(
        id: row['c_id'] as String,
        name: row['c_name'] as String,
        type: TransactionType.fromString(row['c_type'] as String),
        iconCodePoint: (row['c_iconCodePoint'] as num).toInt(),
        colorHex: row['c_colorHex'] as String,
        createdAt: DateTime.parse(row['c_createdAt'] as String),
      );

      final account = Account(
        id: row['a_id'] as String,
        name: row['a_name'] as String,
        type: AccountType.fromString(row['a_type'] as String),
        initialBalanceMinor: (row['a_initialBalanceMinor'] as num).toInt(),
        colorHex: row['a_colorHex'] as String,
        iconCodePoint: (row['a_iconCodePoint'] as num).toInt(),
        isDefault: (row['a_isDefault'] as int? ?? 0) == 1,
        createdAt: DateTime.parse(row['a_createdAt'] as String),
      );

      return TransactionWithDetails(
        transaction: transaction,
        category: category,
        account: account,
      );
    }).toList();
  }

  // ===================== COMPUTED FINANCIAL METRICS =====================

  /// Current Net Worth = Sum of (Account Initial Balances) + Total Income - Total Expenses
  Future<int> getCurrentBalanceMinor() async {
    final db = await _dbProvider.database;
    final accounts = await getAllAccounts();
    final initialTotal = accounts.fold<int>(0, (sum, acc) => sum + acc.initialBalanceMinor);

    final res = await db.rawQuery('''
      SELECT 
        COALESCE(SUM(CASE WHEN type = 'income' THEN amountMinor ELSE 0 END), 0) AS total_income,
        COALESCE(SUM(CASE WHEN type = 'expense' THEN amountMinor ELSE 0 END), 0) AS total_expense
      FROM transactions
    ''');

    final totalIncome = (res.first['total_income'] as num).toInt();
    final totalExpense = (res.first['total_expense'] as num).toInt();

    return initialTotal + totalIncome - totalExpense;
  }

  /// Total income vs expense within a given date range
  Future<({int incomeMinor, int expenseMinor})> getTotalsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await _dbProvider.database;
    final res = await db.rawQuery('''
      SELECT 
        COALESCE(SUM(CASE WHEN type = 'income' THEN amountMinor ELSE 0 END), 0) AS income,
        COALESCE(SUM(CASE WHEN type = 'expense' THEN amountMinor ELSE 0 END), 0) AS expense
      FROM transactions
      WHERE date >= ? AND date <= ?
    ''', [start.toIso8601String(), end.toIso8601String()]);

    return (
      incomeMinor: (res.first['income'] as num).toInt(),
      expenseMinor: (res.first['expense'] as num).toInt(),
    );
  }

  /// Category breakdown for spending within a period
  Future<List<CategorySpendingSummary>> getCategorySpending({
    required DateTime start,
    required DateTime end,
  }) async {
    final db = await _dbProvider.database;
    final rows = await db.rawQuery('''
      SELECT 
        c.id AS c_id, c.name AS c_name, c.type AS c_type,
        c.iconCodePoint AS c_iconCodePoint, c.colorHex AS c_colorHex, c.createdAt AS c_createdAt,
        COALESCE(SUM(t.amountMinor), 0) AS spent
      FROM categories c
      JOIN transactions t ON t.categoryId = c.id
      WHERE t.type = 'expense' AND t.date >= ? AND t.date <= ?
      GROUP BY c.id
      ORDER BY spent DESC
    ''', [start.toIso8601String(), end.toIso8601String()]);

    final totalSpent = rows.fold<int>(0, (sum, r) => sum + (r['spent'] as num).toInt());

    return rows.map((r) {
      final category = Category(
        id: r['c_id'] as String,
        name: r['c_name'] as String,
        type: TransactionType.fromString(r['c_type'] as String),
        iconCodePoint: (r['c_iconCodePoint'] as num).toInt(),
        colorHex: r['c_colorHex'] as String,
        createdAt: DateTime.parse(r['c_createdAt'] as String),
      );
      final spent = (r['spent'] as num).toInt();
      final percentage = totalSpent > 0 ? (spent / totalSpent) * 100 : 0.0;

      return CategorySpendingSummary(
        category: category,
        totalSpentMinor: spent,
        percentage: percentage,
      );
    }).toList();
  }

  /// 6-month historical monthly cash flow
  Future<List<MonthlyFlowSummary>> getMonthlyFlowHistory(int numberOfMonths) async {
    final results = <MonthlyFlowSummary>[];
    final now = DateTime.now();

    for (int i = numberOfMonths - 1; i >= 0; i--) {
      final targetDate = DateTime(now.year, now.month - i, 1);
      final nextMonth = DateTime(targetDate.year, targetDate.month + 1, 1);
      final lastDateOfMonth = nextMonth.subtract(const Duration(milliseconds: 1));

      final totals = await getTotalsByDateRange(targetDate, lastDateOfMonth);
      final label = DateFormat('MMM').format(targetDate);

      results.add(MonthlyFlowSummary(
        monthLabel: label,
        totalIncomeMinor: totals.incomeMinor,
        totalExpenseMinor: totals.expenseMinor,
      ));
    }

    return results;
  }

  // ===================== BUDGETS =====================

  Future<void> upsertBudget(Budget budget) async {
    final db = await _dbProvider.database;
    await db.insert(
      'budgets',
      budget.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _notifyChanged();
  }

  Future<List<BudgetProgress>> getBudgetsWithProgress(String monthYear) async {
    final db = await _dbProvider.database;

    final parts = monthYear.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 1).subtract(const Duration(milliseconds: 1));

    final rows = await db.rawQuery('''
      SELECT 
        b.id AS b_id, b.categoryId AS b_categoryId, b.limitMinor AS b_limitMinor,
        b.monthYear AS b_monthYear, b.createdAt AS b_createdAt,
        c.id AS c_id, c.name AS c_name, c.type AS c_type,
        c.iconCodePoint AS c_iconCodePoint, c.colorHex AS c_colorHex, c.createdAt AS c_createdAt,
        (
          SELECT COALESCE(SUM(amountMinor), 0)
          FROM transactions
          WHERE categoryId = b.categoryId
            AND type = 'expense'
            AND date >= ? AND date <= ?
        ) AS spentMinor
      FROM budgets b
      JOIN categories c ON b.categoryId = c.id
      WHERE b.monthYear = ?
      ORDER BY b_limitMinor DESC
    ''', [startOfMonth.toIso8601String(), endOfMonth.toIso8601String(), monthYear]);

    return rows.map((r) {
      final budget = Budget(
        id: r['b_id'] as String,
        categoryId: r['b_categoryId'] as String,
        limitMinor: (r['b_limitMinor'] as num).toInt(),
        monthYear: r['b_monthYear'] as String,
        createdAt: DateTime.parse(r['b_createdAt'] as String),
      );

      final category = Category(
        id: r['c_id'] as String,
        name: r['c_name'] as String,
        type: TransactionType.fromString(r['c_type'] as String),
        iconCodePoint: (r['c_iconCodePoint'] as num).toInt(),
        colorHex: r['c_colorHex'] as String,
        createdAt: DateTime.parse(r['c_createdAt'] as String),
      );

      return BudgetProgress(
        budget: budget,
        category: category,
        spentMinor: (r['spentMinor'] as num).toInt(),
      );
    }).toList();
  }

  // ===================== SEED DATA =====================

  Future<bool> hasAnyData() async {
    final db = await _dbProvider.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM transactions'),
    );
    return (count ?? 0) > 0;
  }
}
