import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/presentation/providers/expense_providers.dart';
import 'package:expense_tracker/presentation/widgets/analytics_charts.dart';
import 'package:expense_tracker/presentation/widgets/empty_state.dart';
import 'package:expense_tracker/presentation/widgets/summary_card.dart';
import 'package:expense_tracker/presentation/widgets/transaction_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Dashboard / Home view.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(currentBalanceProvider);
    final monthTotalsAsync = ref.watch(currentMonthTotalsProvider);
    final recentTxAsync = ref.watch(recentTransactionsProvider);
    final donutDataAsync = ref.watch(categorySpendingProvider);
    final historyAsync = ref.watch(monthlyFlowHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        actions: [
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
            ),
            tooltip: 'Toggle Theme',
            onPressed: () {
              ref.read(themeModeProvider.notifier).state =
                  !ref.read(themeModeProvider.notifier).state;
            },
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Manage Categories',
            onPressed: () => context.push('/categories'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(currentBalanceProvider);
          ref.invalidate(currentMonthTotalsProvider);
          ref.invalidate(recentTransactionsProvider);
          ref.invalidate(categorySpendingProvider);
          ref.invalidate(monthlyFlowHistoryProvider);
        },
        child: ListView(
          padding: const EdgeInsets.only(bottom: 96),
          children: [
            // 1. Balance & Month Flow Hero Card
            balanceAsync.when(
              data: (balance) {
                final totals = monthTotalsAsync.value ?? (incomeMinor: 0, expenseMinor: 0);
                return SummaryCard(
                  balanceMinor: balance,
                  incomeMinor: totals.incomeMinor,
                  expenseMinor: totals.expenseMinor,
                );
              },
              loading: () => const SizedBox(
                height: 180,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Error loading balance: $err'),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 2. Spending by Category (Donut Chart)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'This Month Spending Split',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      donutDataAsync.when(
                        data: (spending) => CategoryDonutChart(spendingList: spending),
                        loading: () => const SizedBox(
                          height: 150,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (err, _) => Text('Error loading chart: $err'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 3. 6-Month Income vs Expense Trend
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '6-Month Financial Flow',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                          Row(
                            children: [
                              Container(width: 8, height: 8, color: AppColors.income),
                              const SizedBox(width: 4),
                              const Text('In', style: TextStyle(fontSize: 11)),
                              const SizedBox(width: 8),
                              Container(width: 8, height: 8, color: AppColors.expense),
                              const SizedBox(width: 4),
                              const Text('Out', style: TextStyle(fontSize: 11)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      historyAsync.when(
                        data: (history) => SixMonthBarChart(history: history),
                        loading: () => const SizedBox(
                          height: 180,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (err, _) => Text('Error loading chart: $err'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 4. Recent Transactions Header & List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Transactions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  TextButton(
                    onPressed: () => context.go('/transactions'),
                    child: const Text('See All'),
                  ),
                ],
              ),
            ),

            recentTxAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return const EmptyStateWidget(
                    icon: Icons.receipt_long_rounded,
                    title: 'No Transactions Yet',
                    subtitle: 'Tap the + button to record your first income or expense.',
                  );
                }
                return Column(
                  children: items.map((it) {
                    return TransactionTile(
                      item: it,
                      onTap: () => context.push('/transaction/edit', extra: it.transaction),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'dashboard_fab',
        onPressed: () => context.push('/transaction/add'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Entry'),
      ),
    );
  }
}
