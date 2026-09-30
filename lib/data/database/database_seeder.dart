import 'dart:math';
import 'package:expense_tracker/data/models/models.dart';
import 'package:expense_tracker/data/repositories/expense_repository.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

/// Database seeder with realistic initial financial data.
class DatabaseSeeder {
  static const _uuid = Uuid();

  static Future<void> seedIfEmpty(ExpenseRepository repo) async {
    final hasData = await repo.hasAnyData();
    if (hasData) return;

    await seedDemoData(repo);
  }

  static Future<void> seedDemoData(ExpenseRepository repo) async {
    final now = DateTime.now();

    // 1. Seed Accounts (2 accounts)
    final checkingAccount = Account(
      id: _uuid.v4(),
      name: 'Main Checking',
      type: AccountType.bank,
      initialBalanceMinor: 250000, // $2,500.00
      colorHex: '#3B82F6',
      iconCodePoint: Icons.account_balance_rounded.codePoint,
      isDefault: true,
      createdAt: now.subtract(const Duration(days: 90)),
    );

    final cashWallet = Account(
      id: _uuid.v4(),
      name: 'Cash Wallet',
      type: AccountType.cash,
      initialBalanceMinor: 40000, // $400.00
      colorHex: '#10B981',
      iconCodePoint: Icons.account_balance_wallet_rounded.codePoint,
      isDefault: false,
      createdAt: now.subtract(const Duration(days: 90)),
    );

    await repo.insertAccount(checkingAccount);
    await repo.insertAccount(cashWallet);

    // 2. Seed Categories (6+ categories with colors & icons)
    final catGroceries = Category(
      id: _uuid.v4(),
      name: 'Groceries & Food',
      type: TransactionType.expense,
      iconCodePoint: Icons.shopping_basket_rounded.codePoint,
      colorHex: '#EF4444',
      createdAt: now.subtract(const Duration(days: 90)),
    );

    final catDining = Category(
      id: _uuid.v4(),
      name: 'Dining & Cafes',
      type: TransactionType.expense,
      iconCodePoint: Icons.restaurant_rounded.codePoint,
      colorHex: '#F97316',
      createdAt: now.subtract(const Duration(days: 90)),
    );

    final catHousing = Category(
      id: _uuid.v4(),
      name: 'Housing & Utilities',
      type: TransactionType.expense,
      iconCodePoint: Icons.home_rounded.codePoint,
      colorHex: '#8B5CF6',
      createdAt: now.subtract(const Duration(days: 90)),
    );

    final catTransport = Category(
      id: _uuid.v4(),
      name: 'Transport',
      type: TransactionType.expense,
      iconCodePoint: Icons.directions_car_rounded.codePoint,
      colorHex: '#0EA5E9',
      createdAt: now.subtract(const Duration(days: 90)),
    );

    final catEntertainment = Category(
      id: _uuid.v4(),
      name: 'Entertainment',
      type: TransactionType.expense,
      iconCodePoint: Icons.movie_rounded.codePoint,
      colorHex: '#EC4899',
      createdAt: now.subtract(const Duration(days: 90)),
    );

    final catShopping = Category(
      id: _uuid.v4(),
      name: 'Shopping',
      type: TransactionType.expense,
      iconCodePoint: Icons.shopping_bag_rounded.codePoint,
      colorHex: '#EAB308',
      createdAt: now.subtract(const Duration(days: 90)),
    );

    final catSalary = Category(
      id: _uuid.v4(),
      name: 'Salary & Earnings',
      type: TransactionType.income,
      iconCodePoint: Icons.attach_money_rounded.codePoint,
      colorHex: '#10B981',
      createdAt: now.subtract(const Duration(days: 90)),
    );

    final catFreelance = Category(
      id: _uuid.v4(),
      name: 'Freelance & Side-gig',
      type: TransactionType.income,
      iconCodePoint: Icons.laptop_chromebook_rounded.codePoint,
      colorHex: '#06B6D4',
      createdAt: now.subtract(const Duration(days: 90)),
    );

    final categories = [
      catGroceries,
      catDining,
      catHousing,
      catTransport,
      catEntertainment,
      catShopping,
      catSalary,
      catFreelance,
    ];

    for (final cat in categories) {
      await repo.insertCategory(cat);
    }

    // 3. Seed Budgets for current month
    final currentMonthYear = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    await repo.upsertBudget(Budget(
      id: _uuid.v4(),
      categoryId: catGroceries.id,
      limitMinor: 60000, // $600.00
      monthYear: currentMonthYear,
      createdAt: now,
    ));
    await repo.upsertBudget(Budget(
      id: _uuid.v4(),
      categoryId: catDining.id,
      limitMinor: 25000, // $250.00
      monthYear: currentMonthYear,
      createdAt: now,
    ));
    await repo.upsertBudget(Budget(
      id: _uuid.v4(),
      categoryId: catTransport.id,
      limitMinor: 15000, // $150.00
      monthYear: currentMonthYear,
      createdAt: now,
    ));
    await repo.upsertBudget(Budget(
      id: _uuid.v4(),
      categoryId: catEntertainment.id,
      limitMinor: 10000, // $100.00
      monthYear: currentMonthYear,
      createdAt: now,
    ));

    // 4. Seed 35+ realistic transactions across the last 3 months (90 days)
    final random = Random(42);
    final expensePool = [
      (title: 'Supermarket Groceries', cat: catGroceries, min: 4500, max: 14500),
      (title: 'Organic Food Market', cat: catGroceries, min: 2500, max: 8000),
      (title: 'Sushi Dinner', cat: catDining, min: 3500, max: 7500),
      (title: 'Morning Espresso & Croissant', cat: catDining, min: 650, max: 1200),
      (title: 'Pizza Friday', cat: catDining, min: 2200, max: 4000),
      (title: 'Electric & Gas Bill', cat: catHousing, min: 9000, max: 13000),
      (title: 'High-speed Internet', cat: catHousing, min: 6000, max: 7500),
      (title: 'Subway & Bus Pass', cat: catTransport, min: 3000, max: 6500),
      (title: 'Uber Ride', cat: catTransport, min: 1400, max: 3200),
      (title: 'Cinema Tickets', cat: catEntertainment, min: 2400, max: 4200),
      (title: 'Streaming Subscriptions', cat: catEntertainment, min: 1599, max: 2199),
      (title: 'New Running Shoes', cat: catShopping, min: 7900, max: 12000),
      (title: 'Bookstore purchase', cat: catShopping, min: 1800, max: 3500),
    ];

    // Seed 3 Monthly Salaries
    for (int monthOffset = 0; monthOffset < 3; monthOffset++) {
      final salaryDate = DateTime(now.year, now.month - monthOffset, 1);
      await repo.insertTransaction(Transaction(
        id: _uuid.v4(),
        title: 'Monthly Salary Paycheck',
        amountMinor: 380000, // $3,800.00
        type: TransactionType.income,
        categoryId: catSalary.id,
        accountId: checkingAccount.id,
        date: salaryDate,
        note: 'Bi-monthly company direct deposit',
        createdAt: salaryDate,
      ));

      // Occasional freelance income
      final freelanceDate = salaryDate.add(const Duration(days: 14));
      await repo.insertTransaction(Transaction(
        id: _uuid.v4(),
        title: 'Mobile Consulting Gig',
        amountMinor: 65000 + (random.nextInt(3) * 15000), // ~$650 - $950
        type: TransactionType.income,
        categoryId: catFreelance.id,
        accountId: checkingAccount.id,
        date: freelanceDate,
        note: 'Flutter UI architecture sprint',
        createdAt: freelanceDate,
      ));
    }

    // Seed 32 scattered expenses across 85 days
    for (int i = 0; i < 32; i++) {
      final daysAgo = (i * 2.6).round();
      final date = now.subtract(Duration(days: daysAgo, hours: random.nextInt(12)));
      final template = expensePool[random.nextInt(expensePool.length)];
      final amount = template.min + random.nextInt(template.max - template.min + 1);
      final account = random.nextBool() ? checkingAccount : cashWallet;

      await repo.insertTransaction(Transaction(
        id: _uuid.v4(),
        title: template.title,
        amountMinor: amount,
        type: TransactionType.expense,
        categoryId: template.cat.id,
        accountId: account.id,
        date: date,
        note: 'Logged automatically via transaction manager',
        createdAt: date,
      ));
    }
  }
}
