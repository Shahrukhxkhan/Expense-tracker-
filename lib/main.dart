import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'data/database/database_seeder.dart';
import 'data/models/models.dart';
import 'data/repositories/expense_repository.dart';
import 'presentation/providers/expense_providers.dart';
import 'presentation/screens/accounts_screen.dart';
import 'presentation/screens/add_edit_transaction_screen.dart';
import 'presentation/screens/budgets_screen.dart';
import 'presentation/screens/category_management_screen.dart';
import 'presentation/screens/dashboard_screen.dart';
import 'presentation/screens/recurring_transactions_screen.dart';
import 'presentation/screens/transaction_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize and seed repository if database is empty
  final repository = ExpenseRepository();
  await DatabaseSeeder.seedIfEmpty(repository);

  // Automatically process any due recurring items on app launch
  await repository.processDueRecurringTransactions();

  runApp(
    const ProviderScope(
      child: ExpenseTrackerApp(),
    ),
  );
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/transactions',
      builder: (context, state) => const TransactionListScreen(),
    ),
    GoRoute(
      path: '/transaction/add',
      builder: (context, state) => const AddEditTransactionScreen(),
    ),
    GoRoute(
      path: '/transaction/edit',
      builder: (context, state) {
        final transaction = state.extra as Transaction?;
        return AddEditTransactionScreen(initialTransaction: transaction);
      },
    ),
    GoRoute(
      path: '/categories',
      builder: (context, state) => const CategoryManagementScreen(),
    ),
    GoRoute(
      path: '/budgets',
      builder: (context, state) => const BudgetsScreen(),
    ),
    GoRoute(
      path: '/accounts',
      builder: (context, state) => const AccountsScreen(),
    ),
    GoRoute(
      path: '/recurring',
      builder: (context, state) => const RecurringTransactionsScreen(),
    ),
  ],
);

class ExpenseTrackerApp extends ConsumerWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      routerConfig: _router,
    );
  }
}
