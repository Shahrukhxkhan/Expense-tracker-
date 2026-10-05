import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/presentation/providers/expense_providers.dart';
import 'package:expense_tracker/presentation/providers/theme_provider.dart';
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
              switch (ref.watch(themeSettingsProvider).themeMode) {
                AppThemeMode.light => Icons.light_mode_rounded,
                AppThemeMode.dark => Icons.dark_mode_rounded,
                AppThemeMode.amoled => Icons.nightlight_round,
              },
            ),
            tooltip: 'Cycle Theme Mode (Light / Dark / OLED)',
            onPressed: () {
              ref.read(themeSettingsProvider.notifier).cycleThemeMode();
            },
          ),
          IconButton(
            icon: const Icon(Icons.flight_takeoff_outlined),
            tooltip: 'Travel & Multi-Currency',
            onPressed: () => context.push('/travel'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings & Customization',
            onPressed: () => context.push('/settings'),
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

            const SizedBox(height: 14),

            // Quick Access Features Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildQuickAction(
                    context,
                    title: 'Accounts',
                    icon: Icons.account_balance_wallet_rounded,
                    color: Colors.blue,
                    route: '/accounts',
                  ),
                  const SizedBox(width: 8),
                  _buildQuickAction(
                    context,
                    title: 'Budgets',
                    icon: Icons.pie_chart_rounded,
                    color: Colors.purple,
                    route: '/budgets',
                  ),
                  const SizedBox(width: 8),
                  _buildQuickAction(
                    context,
                    title: 'Recurring',
                    icon: Icons.repeat_rounded,
                    color: Colors.orange,
                    route: '/recurring',
                  ),
                  const SizedBox(width: 8),
                  _buildQuickAction(
                    context,
                    title: 'Categories',
                    icon: Icons.category_rounded,
                    color: Colors.teal,
                    route: '/categories',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

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

  Widget _buildQuickAction(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required String route,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () => context.push(route),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF334155)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
