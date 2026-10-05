import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/data/models/models.dart';
import 'package:expense_tracker/presentation/providers/expense_providers.dart';
import 'package:expense_tracker/presentation/widgets/category_chip.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

/// Form screen to Add or Edit an expense or income entry.
class AddEditTransactionScreen extends ConsumerStatefulWidget {
  final Transaction? initialTransaction;

  const AddEditTransactionScreen({super.key, this.initialTransaction});

  @override
  ConsumerState<AddEditTransactionScreen> createState() =>
      _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState
    extends ConsumerState<AddEditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  late TransactionType _selectedType;
  String? _selectedCategoryId;
  String? _selectedAccountId;
  late DateTime _selectedDate;
  String? _receiptPath;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final init = widget.initialTransaction;
    if (init != null) {
      _selectedType = init.type;
      _titleController.text = init.title;
      _amountController.text = (init.amountMinor / 100.0).toStringAsFixed(2);
      _noteController.text = init.note ?? '';
      _selectedCategoryId = init.categoryId;
      _selectedAccountId = init.accountId;
      _selectedDate = init.date;
      _receiptPath = init.receiptPath;
    } else {
      _selectedType = TransactionType.expense;
      _selectedDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialTransaction != null;
    final categoriesAsync = ref.watch(categoriesProvider(_selectedType));
    final accountsAsync = ref.watch(accountsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Transaction' : 'New Transaction'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.expense),
              tooltip: 'Delete Transaction',
              onPressed: () => _confirmDelete(context),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // 1. Expense / Income Segmented Switch
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
              selected: {_selectedType},
              onSelectionChanged: (set) {
                setState(() {
                  _selectedType = set.first;
                  _selectedCategoryId = null; // reset category on type change
                });
              },
            ),

            const SizedBox(height: 24),

            // 2. Amount Input (Keypad friendly)
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800),
              decoration: InputDecoration(
                prefixText: '\$ ',
                prefixStyle: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800),
                hintText: '0.00',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 18),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Enter an amount';
                final minor = CurrencyFormatter.parseToMinor(val);
                if (minor <= 0) return 'Amount must be greater than zero';
                return null;
              },
            ),

            const SizedBox(height: 20),

            // 3. Title Field
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title / Description',
                hintText: 'e.g. Weekly Groceries',
                prefixIcon: const Icon(Icons.edit_note_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Title is required';
                return null;
              },
            ),

            const SizedBox(height: 20),

            // 4. Category Selector
            const Text(
              'Select Category',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            const SizedBox(height: 8),
            categoriesAsync.when(
              data: (cats) {
                if (cats.isEmpty) {
                  return const Text('No categories available for this type.');
                }
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: cats.map((cat) {
                    final isSelected = cat.id == _selectedCategoryId;
                    return CategoryChipWidget(
                      label: cat.name,
                      icon: IconData(cat.iconCodePoint, fontFamily: 'MaterialIcons'),
                      color: parseHexColor(cat.colorHex),
                      isSelected: isSelected,
                      onTap: () {
                        setState(() {
                          _selectedCategoryId = cat.id;
                        });
                      },
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('Error loading categories: $err'),
            ),

            const SizedBox(height: 20),

            // 5. Account & Date Pickers Row
            Row(
              children: [
                // Account Dropdown
                Expanded(
                  child: accountsAsync.when(
                    data: (accounts) {
                      _selectedAccountId ??= accounts.firstOrNull?.id;
                      return DropdownButtonFormField<String>(
                        initialValue: _selectedAccountId,
                        decoration: InputDecoration(
                          labelText: 'Account / Wallet',
                          prefixIcon: const Icon(Icons.account_balance_wallet_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        items: accounts.map((acc) {
                          return DropdownMenuItem(
                            value: acc.id,
                            child: Text(acc.name, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedAccountId = val;
                          });
                        },
                      );
                    },
                    loading: () => const SizedBox(),
                    error: (error, stack) => const SizedBox(),
                  ),
                ),
                const SizedBox(width: 12),
                // Date Picker Button
                Expanded(
                  child: InkWell(
                    onTap: () => _pickDate(context),
                    borderRadius: BorderRadius.circular(16),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Date',
                        prefixIcon: const Icon(Icons.calendar_today_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        DateFormat('MMM d, yyyy').format(_selectedDate),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 6. Note Field
            TextFormField(
              controller: _noteController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Note (Optional)',
                hintText: 'Add details or tags...',
                prefixIcon: const Icon(Icons.notes_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),

            const SizedBox(height: 20),

            // 7. Receipt / Attachment Section
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.15)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.receipt_long_rounded, size: 20),
                            SizedBox(width: 8),
                            Text('Receipt / Attachment', style: TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: _pickReceipt,
                          icon: Icon(_receiptPath != null ? Icons.change_circle_rounded : Icons.attach_file_rounded),
                          label: Text(_receiptPath != null ? 'Change' : 'Attach'),
                        ),
                      ],
                    ),
                    if (_receiptPath != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.description_rounded, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _receiptPath!.split(RegExp(r'[\\/]')).last,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              tooltip: 'Remove Receipt',
                              onPressed: () => setState(() => _receiptPath = null),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // 8. Save Action Button
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _isSubmitting ? null : _saveTransaction,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        isEditing ? 'Save Changes' : 'Record Transaction',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickReceipt() async {
    try {
      final result = await FilePickerPlatform.instance.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      );
      if (result.isNotEmpty) {
        final path = result.first.path ?? result.first.name;
        setState(() {
          _receiptPath = path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick file: $e')),
        );
      }
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }
    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an account')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(expenseRepositoryProvider);
      final amountMinor = CurrencyFormatter.parseToMinor(_amountController.text);
      final isEditing = widget.initialTransaction != null;

      final transaction = Transaction(
        id: isEditing ? widget.initialTransaction!.id : const Uuid().v4(),
        title: _titleController.text.trim(),
        amountMinor: amountMinor,
        type: _selectedType,
        categoryId: _selectedCategoryId!,
        accountId: _selectedAccountId!,
        date: _selectedDate,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        receiptPath: _receiptPath,
        createdAt: isEditing ? widget.initialTransaction!.createdAt : DateTime.now(),
      );

      if (isEditing) {
        await repo.updateTransaction(transaction);
      } else {
        await repo.insertTransaction(transaction);
      }

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save transaction: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction?'),
        content: const Text('Are you sure you want to permanently delete this entry?'),
        actions: [
          TextButton(onPressed: () => ctx.pop(false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
            onPressed: () => ctx.pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final repo = ref.read(expenseRepositoryProvider);
      await repo.deleteTransaction(widget.initialTransaction!.id);
      if (!mounted) return;
      if (context.mounted) {
        context.pop();
      }
    }
  }
}
