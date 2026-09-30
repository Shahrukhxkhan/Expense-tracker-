import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/data/models/models.dart';
import 'package:expense_tracker/presentation/providers/expense_providers.dart';
import 'package:expense_tracker/presentation/widgets/empty_state.dart';
import 'package:expense_tracker/presentation/widgets/transaction_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Transaction List screen with dynamic search, filter chips, date grouping, and swipe-to-delete with undo.
class TransactionListScreen extends ConsumerStatefulWidget {
  const TransactionListScreen({super.key});

  @override
  ConsumerState<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends ConsumerState<TransactionListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(transactionFilterProvider);
    final groupedAsync = ref.watch(filteredTransactionsProvider);
    final categoriesAsync = ref.watch(categoriesProvider(null));

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Transactions'),
        actions: [
          if (filter.type != null ||
              filter.categoryId != null ||
              filter.searchQuery.isNotEmpty ||
              filter.startDate != null)
            IconButton(
              icon: const Icon(Icons.filter_alt_off_rounded),
              tooltip: 'Clear Filters',
              onPressed: () {
                _searchController.clear();
                ref.read(transactionFilterProvider.notifier).state =
                    const TransactionFilterState();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // 1. Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by title or note...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(transactionFilterProvider.notifier).state =
                              filter.copyWith(searchQuery: '');
                        },
                      )
                    : null,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (val) {
                ref.read(transactionFilterProvider.notifier).state =
                    filter.copyWith(searchQuery: val);
              },
            ),
          ),

          // 2. Type & Category Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All Types'),
                  selected: filter.type == null,
                  onSelected: (_) {
                    ref.read(transactionFilterProvider.notifier).state =
                        filter.copyWith(clearType: true);
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Expenses'),
                  selected: filter.type == TransactionType.expense,
                  selectedColor: AppColors.expense.withValues(alpha: 0.2),
                  onSelected: (selected) {
                    ref.read(transactionFilterProvider.notifier).state = filter.copyWith(
                      type: selected ? TransactionType.expense : null,
                      clearType: !selected,
                    );
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Income'),
                  selected: filter.type == TransactionType.income,
                  selectedColor: AppColors.income.withValues(alpha: 0.2),
                  onSelected: (selected) {
                    ref.read(transactionFilterProvider.notifier).state = filter.copyWith(
                      type: selected ? TransactionType.income : null,
                      clearType: !selected,
                    );
                  },
                ),
                const SizedBox(width: 8),
                categoriesAsync.when(
                  data: (cats) {
                    return DropdownButton<String?>(
                      value: filter.categoryId,
                      hint: const Text('Category'),
                      underline: const SizedBox(),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All Categories')),
                        ...cats.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                      ],
                      onChanged: (catId) {
                        ref.read(transactionFilterProvider.notifier).state = filter.copyWith(
                          categoryId: catId,
                          clearCategory: catId == null,
                        );
                      },
                    );
                  },
                  loading: () => const SizedBox(),
                  error: (_, _) => const SizedBox(),
                ),
              ],
            ),
          ),

          const Divider(height: 16),

          // 3. Grouped Transaction List
          Expanded(
            child: groupedAsync.when(
              data: (groups) {
                if (groups.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.search_off_rounded,
                    title: 'No Matching Transactions',
                    subtitle: 'Try changing your search terms or filter criteria.',
                    actionLabel: 'Add Entry',
                    onAction: () => context.push('/transaction/add'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 96),
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    final dateTitle = _formatGroupDate(group.date);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Daily Header
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                dateTitle,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Row(
                                children: [
                                  if (group.totalIncomeMinor > 0)
                                    Text(
                                      '+${CurrencyFormatter.formatMinor(group.totalIncomeMinor)} ',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.income,
                                      ),
                                    ),
                                  if (group.totalExpenseMinor > 0)
                                    Text(
                                      '-${CurrencyFormatter.formatMinor(group.totalExpenseMinor)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.expense,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Daily Items
                        ...group.items.map((item) {
                          return TransactionTile(
                            item: item,
                            onTap: () => context.push('/transaction/edit', extra: item.transaction),
                            onDismissed: (_) async {
                              final deleted = item.transaction;
                              final repo = ref.read(expenseRepositoryProvider);
                              await repo.deleteTransaction(deleted.id);

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).clearSnackBars();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Deleted "${deleted.title}"'),
                                    action: SnackBarAction(
                                      label: 'UNDO',
                                      onPressed: () async {
                                        await repo.insertTransaction(deleted);
                                      },
                                    ),
                                  ),
                                );
                              }
                            },
                          );
                        }),
                      ],
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error loading items: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'tx_list_fab',
        onPressed: () => context.push('/transaction/add'),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  String _formatGroupDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    if (target == today) return 'TODAY';
    if (target == today.subtract(const Duration(days: 1))) return 'YESTERDAY';
    return DateFormat('EEE, MMM d, yyyy').format(date).toUpperCase();
  }
}
