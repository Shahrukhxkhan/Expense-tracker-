import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/data/models/models.dart';
import 'package:expense_tracker/presentation/providers/expense_providers.dart';
import 'package:expense_tracker/presentation/widgets/category_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts & Wallets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded),
            tooltip: 'Transfer Funds',
            onPressed: () => _openTransferDialog(context, ref),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAccountDialog(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Account'),
      ),
      body: accountsAsync.when(
        data: (accounts) {
          if (accounts.isEmpty) {
            return const Center(child: Text('No accounts found.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            itemCount: accounts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final account = accounts[index];
              return _AccountCard(account: account);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Future<void> _openTransferDialog(BuildContext context, WidgetRef ref) async {
    final accounts = await ref.read(expenseRepositoryProvider).getAllAccounts();
    if (accounts.length < 2) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('At least 2 accounts are required to transfer funds.')),
        );
      }
      return;
    }

    Account fromAcc = accounts.first;
    Account toAcc = accounts[1];
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dCtx, setModalState) {
            return AlertDialog(
              title: const Text('Transfer Between Accounts'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        value: fromAcc.id,
                        decoration: InputDecoration(
                          labelText: 'From Account',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        items: accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() {
                              fromAcc = accounts.firstWhere((a) => a.id == val);
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: toAcc.id,
                        decoration: InputDecoration(
                          labelText: 'To Account',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        items: accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() {
                              toAcc = accounts.firstWhere((a) => a.id == val);
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Amount',
                          prefixText: '\$ ',
                          hintText: '0.00',
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
                      TextFormField(
                        controller: noteController,
                        decoration: InputDecoration(
                          labelText: 'Note (Optional)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    if (fromAcc.id == toAcc.id) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Source and destination accounts must be different')),
                      );
                      return;
                    }

                    final minor = CurrencyFormatter.parseToMinor(amountController.text);
                    await ref.read(expenseRepositoryProvider).transferFunds(
                          fromAccount: fromAcc,
                          toAccount: toAcc,
                          amountMinor: minor,
                          date: DateTime.now(),
                          note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
                        );
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Transfer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _openAccountDialog(BuildContext context, WidgetRef ref, {Account? existing}) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final balanceController = TextEditingController(
      text: existing != null ? (existing.initialBalanceMinor / 100.0).toStringAsFixed(2) : '0.00',
    );
    var selectedType = existing?.type ?? AccountType.bank;
    var isDefault = existing?.isDefault ?? false;
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dCtx, setModalState) {
            return AlertDialog(
              title: Text(existing != null ? 'Edit Account' : 'New Account'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Account Name',
                          hintText: 'e.g. Chase Checking, Cash Wallet',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Enter name' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<AccountType>(
                        value: selectedType,
                        decoration: InputDecoration(
                          labelText: 'Account Type',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        items: AccountType.values.map((t) {
                          return DropdownMenuItem(value: t, child: Text(t.name.toUpperCase()));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => selectedType = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: balanceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Starting Balance',
                          prefixText: '\$ ',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Enter starting balance' : null,
                      ),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        title: const Text('Set as Default Account'),
                        value: isDefault,
                        onChanged: (val) => setModalState(() => isDefault = val ?? false),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final minor = CurrencyFormatter.parseToMinor(balanceController.text);
                    final repo = ref.read(expenseRepositoryProvider);

                    final acc = Account(
                      id: existing?.id ?? const Uuid().v4(),
                      name: nameController.text.trim(),
                      type: selectedType,
                      initialBalanceMinor: minor,
                      colorHex: existing?.colorHex ?? '#2196F3',
                      iconCodePoint: existing?.iconCodePoint ?? 0xe040,
                      isDefault: isDefault,
                      createdAt: existing?.createdAt ?? DateTime.now(),
                    );

                    if (existing != null) {
                      await repo.updateAccount(acc);
                    } else {
                      await repo.insertAccount(acc);
                    }

                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: Text(existing != null ? 'Save' : 'Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _AccountCard extends ConsumerWidget {
  final Account account;

  const _AccountCard({required this.account});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(accountBalanceProvider(account.id));
    final color = parseHexColor(account.colorHex);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: account.isDefault
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.6)
              : Theme.of(context).dividerColor.withValues(alpha: 0.12),
          width: account.isDefault ? 1.8 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.15),
                  child: Icon(
                    account.type == AccountType.cash
                        ? Icons.payments_rounded
                        : account.type == AccountType.creditCard
                            ? Icons.credit_card_rounded
                            : Icons.account_balance_rounded,
                    color: color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            account.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          if (account.isDefault) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('Default', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        account.type.name.toUpperCase(),
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                balanceAsync.when(
                  data: (bal) => Text(
                    CurrencyFormatter.formatMinor(bal),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: bal < 0 ? AppColors.expense : null,
                    ),
                  ),
                  loading: () => const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                  error: (_, __) => const Text('--'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
