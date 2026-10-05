import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/data/models/derived_models.dart';
import 'package:expense_tracker/data/models/models.dart';
import 'package:expense_tracker/presentation/providers/expense_providers.dart';
import 'package:expense_tracker/presentation/widgets/category_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedBudgetMonthProvider);
    final budgetsAsync = ref.watch(budgetsProvider);

    // Format header date (e.g. "October 2026")
    final parts = selectedMonth.split('-');
    final monthDate = DateTime(int.parse(parts[0]), int.parse(parts[1]));
    final monthLabel = DateFormat('MMMM yyyy').format(monthDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets & Limits'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openBudgetDialog(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Set Budget'),
      ),
      body: Column(
        children: [
          // Month Selector Card
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.15)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded),
                      onPressed: () {
                        final prev = DateTime(monthDate.year, monthDate.month - 1);
                        ref.read(selectedBudgetMonthProvider.notifier).state =
                            '${prev.year}-${prev.month.toString().padLeft(2, '0')}';
                      },
                    ),
                    Text(
                      monthLabel,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded),
                      onPressed: () {
                        final next = DateTime(monthDate.year, monthDate.month + 1);
                        ref.read(selectedBudgetMonthProvider.notifier).state =
                            '${next.year}-${next.month.toString().padLeft(2, '0')}';
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Budgets List
          Expanded(
            child: budgetsAsync.when(
              data: (budgets) {
                if (budgets.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.pie_chart_outline_rounded, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          const Text(
                            'No budgets set for this month',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Set spending limits on categories to keep your expenses under control.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Overall monthly budget aggregate
                int totalLimit = 0;
                int totalSpent = 0;
                for (final b in budgets) {
                  totalLimit += b.budget.limitMinor;
                  totalSpent += b.spentMinor;
                }
                final overallRatio = totalLimit == 0 ? 0.0 : totalSpent / totalLimit;

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  children: [
                    // Overall Total Card
                    Card(
                      elevation: 0,
                      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.35),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Budget Health',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Spent: ${CurrencyFormatter.formatMinor(totalSpent)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                Text(
                                  'Limit: ${CurrencyFormatter.formatMinor(totalLimit)}',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: overallRatio.clamp(0.0, 1.0),
                                minHeight: 10,
                                backgroundColor: Colors.grey.withValues(alpha: 0.2),
                                color: overallRatio >= 1.0
                                    ? AppColors.expense
                                    : overallRatio >= 0.8
                                        ? Colors.orange
                                        : AppColors.income,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${(overallRatio * 100).toStringAsFixed(1)}% used'
                              '${overallRatio >= 1.0 ? ' • Budget Exceeded!' : overallRatio >= 0.8 ? ' • Approaching Limit' : ' • On Track'}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: overallRatio >= 1.0
                                    ? AppColors.expense
                                    : overallRatio >= 0.8
                                        ? Colors.orange
                                        : AppColors.income,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Category Budgets',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...budgets.map((b) => _buildBudgetCard(context, ref, b)),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetCard(BuildContext context, WidgetRef ref, BudgetProgress b) {
    final cat = b.category;
    final catColor = parseHexColor(cat.colorHex);
    final ratio = b.ratio;
    final isExceeded = b.isRed;
    final isWarning = b.isAmber;

    Color statusColor = AppColors.income;
    if (isExceeded) {
      statusColor = AppColors.expense;
    } else if (isWarning) {
      statusColor = Colors.orange;
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isExceeded
              ? AppColors.expense.withValues(alpha: 0.5)
              : Theme.of(context).dividerColor.withValues(alpha: 0.1),
          width: isExceeded ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: catColor.withValues(alpha: 0.2),
                  child: Icon(
                    IconData(cat.iconCodePoint, fontFamily: 'MaterialIcons'),
                    color: catColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cat.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        isExceeded
                            ? 'Over by ${CurrencyFormatter.formatMinor(b.spentMinor - b.budget.limitMinor)}'
                            : '${CurrencyFormatter.formatMinor(b.remainingMinor)} remaining',
                        style: TextStyle(
                          fontSize: 12,
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_rounded, size: 20),
                  tooltip: 'Edit Budget',
                  onPressed: () => _openBudgetDialog(context, ref, existing: b.budget),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.expense),
                  tooltip: 'Delete Budget',
                  onPressed: () async {
                    await ref.read(expenseRepositoryProvider).deleteBudget(b.budget.id);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  CurrencyFormatter.formatMinor(b.spentMinor),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  'Limit: ${CurrencyFormatter.formatMinor(b.budget.limitMinor)}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: ratio.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: Colors.grey.withValues(alpha: 0.15),
                color: statusColor,
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${(ratio * 100).toStringAsFixed(0)}%',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openBudgetDialog(
    BuildContext context,
    WidgetRef ref, {
    Budget? existing,
  }) async {
    final categoriesAsync = await ref.read(expenseRepositoryProvider).getAllCategories(
          type: TransactionType.expense,
        );
    if (!context.mounted) return;

    if (categoriesAsync.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please create expense categories first.')),
      );
      return;
    }

    String selectedCategoryId = existing?.categoryId ?? categoriesAsync.first.id;
    final amountController = TextEditingController(
      text: existing != null ? (existing.limitMinor / 100.0).toStringAsFixed(2) : '',
    );
    final formKey = GlobalKey<FormState>();
    final currentMonthYear = ref.read(selectedBudgetMonthProvider);

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dCtx, setModalState) {
            return AlertDialog(
              title: Text(existing != null ? 'Edit Budget' : 'Set Category Budget'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedCategoryId,
                      decoration: InputDecoration(
                        labelText: 'Expense Category',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      items: categoriesAsync.map((c) {
                        return DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name),
                        );
                      }).toList(),
                      onChanged: existing != null
                          ? null // Cannot change category when editing existing budget key
                          : (val) {
                              if (val != null) {
                                setModalState(() => selectedCategoryId = val);
                              }
                            },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Monthly Limit Amount',
                        prefixText: '\$ ',
                        hintText: '500.00',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Please enter limit';
                        final minor = CurrencyFormatter.parseToMinor(val);
                        if (minor <= 0) return 'Limit must be positive';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final limitMinor = CurrencyFormatter.parseToMinor(amountController.text);
                    final repo = ref.read(expenseRepositoryProvider);

                    final budget = Budget(
                      id: existing?.id ?? const Uuid().v4(),
                      categoryId: selectedCategoryId,
                      limitMinor: limitMinor,
                      monthYear: currentMonthYear,
                      createdAt: existing?.createdAt ?? DateTime.now(),
                    );

                    await repo.upsertBudget(budget);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Save Budget'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
