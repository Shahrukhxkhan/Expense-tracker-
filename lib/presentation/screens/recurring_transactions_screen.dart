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

class RecurringTransactionsScreen extends ConsumerWidget {
  const RecurringTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recurringAsync = ref.watch(recurringTransactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recurring Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded),
            tooltip: 'Process Due Transactions Now',
            onPressed: () async {
              final count = await ref.read(expenseRepositoryProvider).processDueRecurringTransactions();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      count > 0 ? 'Generated $count recurring transaction(s).' : 'All recurring schedules are up to date.',
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openRecurringDialog(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Recurring'),
      ),
      body: recurringAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.repeat_rounded, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text(
                      'No recurring subscriptions or bills',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Set up automated subscriptions, rent, or salary entries that repeat regularly.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              return _RecurringCard(item: item);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Future<void> _openRecurringDialog(
    BuildContext context,
    WidgetRef ref, {
    RecurringTransaction? existing,
  }) async {
    final categories = await ref.read(expenseRepositoryProvider).getAllCategories();
    final accounts = await ref.read(expenseRepositoryProvider).getAllAccounts();
    if (!context.mounted) return;

    if (categories.isEmpty || accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please ensure accounts and categories are available.')),
      );
      return;
    }

    final titleController = TextEditingController(text: existing?.title ?? '');
    final amountController = TextEditingController(
      text: existing != null ? (existing.amountMinor / 100.0).toStringAsFixed(2) : '',
    );
    final noteController = TextEditingController(text: existing?.note ?? '');
    var selectedType = existing?.type ?? TransactionType.expense;
    var selectedFrequency = existing?.frequency ?? RecurringFrequency.monthly;
    var selectedCategoryId = existing?.categoryId ?? categories.first.id;
    var selectedAccountId = existing?.accountId ?? accounts.first.id;
    var selectedStartDate = existing?.startDate ?? DateTime.now();
    var isActive = existing?.isActive ?? true;

    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (dCtx, setModalState) {
            final filteredCategories = categories.where((c) => c.type == selectedType).toList();
            if (!filteredCategories.any((c) => c.id == selectedCategoryId)) {
              selectedCategoryId = filteredCategories.firstOrNull?.id ?? categories.first.id;
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(dCtx).viewInsets.bottom + 16,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            existing != null ? 'Edit Recurring Schedule' : 'New Recurring Schedule',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(dCtx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<TransactionType>(
                        segments: const [
                          ButtonSegment(
                            value: TransactionType.expense,
                            label: Text('Expense'),
                            icon: Icon(Icons.arrow_upward_rounded),
                          ),
                          ButtonSegment(
                            value: TransactionType.income,
                            label: Text('Income'),
                            icon: Icon(Icons.arrow_downward_rounded),
                          ),
                        ],
                        selected: {selectedType},
                        onSelectionChanged: (val) {
                          setModalState(() => selectedType = val.first);
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: 'Title',
                          hintText: 'e.g. Netflix Subscription, Apartment Rent',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Enter title' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Amount',
                          prefixText: '\$ ',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Enter amount';
                          final minor = CurrencyFormatter.parseToMinor(val);
                          if (minor <= 0) return 'Amount must be positive';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<RecurringFrequency>(
                              value: selectedFrequency,
                              decoration: InputDecoration(
                                labelText: 'Frequency',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              items: RecurringFrequency.values.map((f) {
                                return DropdownMenuItem(value: f, child: Text(f.displayName));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setModalState(() => selectedFrequency = val);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: dCtx,
                                  initialDate: selectedStartDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (picked != null) {
                                  setModalState(() => selectedStartDate = picked);
                                }
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Start Date',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                child: Text(DateFormat('MMM d, yyyy').format(selectedStartDate)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedCategoryId,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        items: filteredCategories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => selectedCategoryId = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedAccountId,
                        decoration: InputDecoration(
                          labelText: 'Account',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        items: accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))).toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => selectedAccountId = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: noteController,
                        decoration: InputDecoration(
                          labelText: 'Note (Optional)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        title: const Text('Active Schedule'),
                        value: isActive,
                        onChanged: (val) => setModalState(() => isActive = val ?? true),
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
                            final minor = CurrencyFormatter.parseToMinor(amountController.text);
                            final repo = ref.read(expenseRepositoryProvider);

                            final rec = RecurringTransaction(
                              id: existing?.id ?? const Uuid().v4(),
                              title: titleController.text.trim(),
                              amountMinor: minor,
                              type: selectedType,
                              categoryId: selectedCategoryId,
                              accountId: selectedAccountId,
                              frequency: selectedFrequency,
                              startDate: selectedStartDate,
                              lastProcessedDate: existing?.lastProcessedDate,
                              isActive: isActive,
                              note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
                              createdAt: existing?.createdAt ?? DateTime.now(),
                            );

                            if (existing != null) {
                              await repo.updateRecurringTransaction(rec);
                            } else {
                              await repo.insertRecurringTransaction(rec);
                            }

                            // Trigger process check
                            await repo.processDueRecurringTransactions();

                            if (dCtx.mounted) Navigator.pop(dCtx);
                          },
                          child: Text(existing != null ? 'Save Changes' : 'Create Schedule'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _RecurringCard extends ConsumerWidget {
  final RecurringTransactionWithDetails item;

  const _RecurringCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rec = item.recurring;
    final cat = item.category;
    final catColor = parseHexColor(cat.colorHex);
    final isExpense = rec.type == TransactionType.expense;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: catColor.withValues(alpha: 0.18),
              child: Icon(
                IconData(cat.iconCodePoint, fontFamily: 'MaterialIcons'),
                color: catColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rec.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${rec.frequency.displayName} • ${item.account.name}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    rec.lastProcessedDate != null
                        ? 'Last run: ${DateFormat('MMM d, yyyy').format(rec.lastProcessedDate!)}'
                        : 'Starts: ${DateFormat('MMM d, yyyy').format(rec.startDate)}',
                    style: TextStyle(
                      color: rec.isActive ? Theme.of(context).colorScheme.primary : Colors.grey,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isExpense ? '-' : '+'}${CurrencyFormatter.formatMinor(rec.amountMinor)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: isExpense ? AppColors.expense : AppColors.income,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.expense),
                  onPressed: () async {
                    await ref.read(expenseRepositoryProvider).deleteRecurringTransaction(rec.id);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
