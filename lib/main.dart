import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'data/database/database_seeder.dart';
import 'data/models/models.dart';
import 'data/repositories/expense_repository.dart';
import 'presentation/providers/expense_providers.dart';
import 'presentation/screens/add_edit_transaction_screen.dart';
import 'presentation/screens/dashboard_screen.dart';
import 'presentation/screens/transaction_list_screen.dart';
import 'presentation/widgets/category_chip.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize and seed repository if database is empty
  final repository = ExpenseRepository();
  await DatabaseSeeder.seedIfEmpty(repository);

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

/// Category Management screen to view and add categories
class CategoryManagementScreen extends ConsumerWidget {
  const CategoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider(null));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
      ),
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return const Center(child: Text('No categories found.'));
          }

          final expenseCategories = categories.where((c) => c.type == TransactionType.expense).toList();
          final incomeCategories = categories.where((c) => c.type == TransactionType.income).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (expenseCategories.isNotEmpty) ...[
                Text(
                  'Expense Categories (${expenseCategories.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: expenseCategories.map((cat) {
                    return CategoryChipWidget(
                      label: cat.name,
                      icon: IconData(cat.iconCodePoint, fontFamily: 'MaterialIcons'),
                      color: parseHexColor(cat.colorHex),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
              ],
              if (incomeCategories.isNotEmpty) ...[
                Text(
                  'Income Categories (${incomeCategories.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: incomeCategories.map((cat) {
                    return CategoryChipWidget(
                      label: cat.name,
                      icon: IconData(cat.iconCodePoint, fontFamily: 'MaterialIcons'),
                      color: parseHexColor(cat.colorHex),
                    );
                  }).toList(),
                ),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
