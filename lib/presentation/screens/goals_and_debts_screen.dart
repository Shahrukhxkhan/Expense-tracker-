import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/goals_and_debts_model.dart';
import '../providers/goals_and_debts_provider.dart';

class GoalsAndDebtsScreen extends ConsumerStatefulWidget {
  const GoalsAndDebtsScreen({super.key});

  @override
  ConsumerState<GoalsAndDebtsScreen> createState() =>
      _GoalsAndDebtsScreenState();
}

class _GoalsAndDebtsScreenState extends ConsumerState<GoalsAndDebtsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Goals & Debt Tracker'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.savings_outlined), text: 'Savings & Sinking'),
            Tab(icon: Icon(Icons.handshake_outlined), text: 'Debts & Loans'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGoalsTab(),
          _buildDebtsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tabController.index == 0) {
            _showAddGoalDialog(context);
          } else {
            _showAddDebtDialog(context);
          }
        },
        icon: const Icon(Icons.add),
        label: Text(_tabController.index == 0 ? 'New Goal' : 'New Loan / Debt'),
      ),
    );
  }

  // --- TAB 1: SAVINGS GOALS & SINKING FUNDS ---
  Widget _buildGoalsTab() {
    final goals = ref.watch(goalsProvider);

    int totalTarget = 0;
    int totalSaved = 0;
    for (final g in goals) {
      totalTarget += g.targetAmountMinor;
      totalSaved += g.currentSavedMinor;
    }
    final overallProgress = totalTarget > 0 ? (totalSaved / totalTarget) : 0.0;

    return ListView(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
      children: [
        // Summary Card
        Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Saved Towards Goals',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      '${(overallProgress * 100).toInt()}% Done',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '\$${(totalSaved / 100).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: overallProgress.clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: Colors.white24,
                    color: AppColors.income,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Target: \$${(totalTarget / 100).toStringAsFixed(2)} across ${goals.length} active goals',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        if (goals.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('No savings goals yet. Tap + to set one!'),
            ),
          )
        else
          ...goals.map((goal) => _buildGoalCard(goal)),
      ],
    );
  }

  Widget _buildGoalCard(FinancialGoal goal) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Color(
                        int.parse(goal.colorHex.replaceFirst('#', '0xFF')),
                      ).withValues(alpha: 0.2),
                      child: Icon(
                        IconData(goal.iconCodePoint, fontFamily: 'MaterialIcons'),
                        size: 20,
                        color: Color(int.parse(goal.colorHex.replaceFirst('#', '0xFF'))),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          'Target: ${dateFormat.format(goal.targetDate)}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: goal.isAchieved ? Colors.green.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    goal.isAchieved ? 'Achieved 🏆' : '${(goal.progressPercentage * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: goal.isAchieved ? Colors.green : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: goal.progressPercentage,
                minHeight: 8,
                backgroundColor: Colors.grey.withValues(alpha: 0.2),
                color: Color(int.parse(goal.colorHex.replaceFirst('#', '0xFF'))),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Saved: \$${(goal.currentSavedMinor / 100).toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  'Goal: \$${(goal.targetAmountMinor / 100).toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showTransferFundsDialog(goal, isDeposit: false),
                  icon: const Icon(Icons.remove, size: 14),
                  label: const Text('Withdraw', style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _showTransferFundsDialog(goal, isDeposit: true),
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('Deposit Funds', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB 2: DEBTS & LOANS TRACKER ---
  Widget _buildDebtsTab() {
    final debts = ref.watch(debtsProvider);

    int totalBorrowedOwed = 0;
    int totalLentReceivable = 0;

    for (final d in debts) {
      if (!d.isSettled) {
        if (d.type == DebtType.borrowed) {
          totalBorrowedOwed += d.remainingBalanceMinor;
        } else {
          totalLentReceivable += d.remainingBalanceMinor;
        }
      }
    }

    return ListView(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
      children: [
        // Summary Cards
        Row(
          children: [
            Expanded(
              child: Card(
                color: Colors.red.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total You Owe (Debts)',
                        style: TextStyle(fontSize: 12, color: Colors.red),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${(totalBorrowedOwed / 100).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Card(
                color: Colors.green.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Owed To You (IOUs)',
                        style: TextStyle(fontSize: 12, color: Colors.green),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${(totalLentReceivable / 100).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        if (debts.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('No debt or loan accounts tracked.'),
            ),
          )
        else
          ...debts.map((debt) => _buildDebtCard(debt)),
      ],
    );
  }

  Widget _buildDebtCard(DebtItem debt) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final isOwedByMe = debt.type == DebtType.borrowed;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isOwedByMe
                                ? Icons.arrow_circle_up_outlined
                                : Icons.arrow_circle_down_outlined,
                            size: 18,
                            color: isOwedByMe ? Colors.red : Colors.green,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              debt.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${isOwedByMe ? "Creditor" : "Debtor"}: ${debt.counterparty} • Due ${dateFormat.format(debt.dueDate)}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: debt.isSettled
                        ? Colors.green.withValues(alpha: 0.15)
                        : Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    debt.isSettled ? 'Settled' : 'Active',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: debt.isSettled ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: debt.repaymentProgress,
                minHeight: 8,
                backgroundColor: Colors.grey.withValues(alpha: 0.2),
                color: isOwedByMe ? Colors.red : Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Remaining: \$${(debt.remainingBalanceMinor / 100).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isOwedByMe ? Colors.red : Colors.green,
                  ),
                ),
                Text(
                  'Principal: \$${(debt.principalAmountMinor / 100).toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
            if (debt.monthlyEmiMinor > 0) ...[
              const SizedBox(height: 4),
              Text(
                'Monthly Installment (EMI): \$${(debt.monthlyEmiMinor / 100).toStringAsFixed(2)} @ ${debt.interestRatePercentage}% p.a.',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!debt.isSettled)
                  ElevatedButton.icon(
                    onPressed: () => _showRecordRepaymentDialog(debt),
                    icon: const Icon(Icons.payment, size: 14),
                    label: Text(
                      isOwedByMe ? 'Make Payment' : 'Record Received',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- DIALOGS ---
  void _showAddGoalDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    GoalType selectedType = GoalType.savings;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return AlertDialog(
              title: const Text('Add Savings Goal'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Goal Name (e.g. New Car)'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Target Amount (\$)'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<GoalType>(
                    initialValue: selectedType,
                    decoration: const InputDecoration(labelText: 'Goal Category'),
                    items: const [
                      DropdownMenuItem(
                        value: GoalType.savings,
                        child: Text('Savings Goal'),
                      ),
                      DropdownMenuItem(
                        value: GoalType.sinkingFund,
                        child: Text('Sinking Fund (Planned Spend)'),
                      ),
                      DropdownMenuItem(
                        value: GoalType.emergencyFund,
                        child: Text('Emergency Safety Net'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setDlgState(() => selectedType = val);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final amt = double.tryParse(amountCtrl.text) ?? 0.0;
                    if (amt > 0 && titleCtrl.text.isNotEmpty) {
                      ref.read(goalsProvider.notifier).addGoal(
                            title: titleCtrl.text,
                            targetAmountMinor: (amt * 100).toInt(),
                            targetDate: DateTime.now().add(const Duration(days: 180)),
                            colorHex: '#6366F1',
                            type: selectedType,
                          );
                    }
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save Goal'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showTransferFundsDialog(FinancialGoal goal, {required bool isDeposit}) {
    final amountCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(isDeposit ? 'Deposit to ${goal.title}' : 'Withdraw from ${goal.title}'),
          content: TextField(
            controller: amountCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Amount (\$)'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final amt = double.tryParse(amountCtrl.text) ?? 0.0;
                if (amt > 0) {
                  if (isDeposit) {
                    ref.read(goalsProvider.notifier).depositToGoal(
                          goalId: goal.id,
                          amountMinor: (amt * 100).toInt(),
                        );
                  } else {
                    ref.read(goalsProvider.notifier).withdrawFromGoal(
                          goalId: goal.id,
                          amountMinor: (amt * 100).toInt(),
                        );
                  }
                }
                Navigator.pop(ctx);
              },
              child: Text(isDeposit ? 'Deposit' : 'Withdraw'),
            ),
          ],
        );
      },
    );
  }

  void _showAddDebtDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final personCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final emiCtrl = TextEditingController();
    DebtType type = DebtType.borrowed;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return AlertDialog(
              title: const Text('Track Loan / Debt'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<DebtType>(
                      initialValue: type,
                      decoration: const InputDecoration(labelText: 'Type'),
                      items: const [
                        DropdownMenuItem(
                          value: DebtType.borrowed,
                          child: Text('I Owe Money (Loan / Credit / Debt)'),
                        ),
                        DropdownMenuItem(
                          value: DebtType.lent,
                          child: Text('Someone Owes Me (IOU / Lent)'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) setDlgState(() => type = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(labelText: 'Description / Loan Name'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: personCtrl,
                      decoration: const InputDecoration(labelText: 'Counterparty / Bank / Person'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Principal Amount (\$)'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emiCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Monthly EMI / Installment (\$)'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final amt = double.tryParse(amountCtrl.text) ?? 0.0;
                    final emi = double.tryParse(emiCtrl.text) ?? 0.0;
                    if (amt > 0 && titleCtrl.text.isNotEmpty) {
                      ref.read(debtsProvider.notifier).addDebt(
                            counterparty: personCtrl.text.isEmpty ? 'Bank' : personCtrl.text,
                            title: titleCtrl.text,
                            type: type,
                            principalAmountMinor: (amt * 100).toInt(),
                            monthlyEmiMinor: (emi * 100).toInt(),
                            dueDate: DateTime.now().add(const Duration(days: 30)),
                          );
                    }
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showRecordRepaymentDialog(DebtItem debt) {
    final amountCtrl = TextEditingController(
      text: debt.monthlyEmiMinor > 0
          ? (debt.monthlyEmiMinor / 100).toStringAsFixed(2)
          : (debt.remainingBalanceMinor / 100).toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Record Repayment for ${debt.title}'),
          content: TextField(
            controller: amountCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Payment Amount (\$)'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final amt = double.tryParse(amountCtrl.text) ?? 0.0;
                if (amt > 0) {
                  ref.read(debtsProvider.notifier).recordRepayment(
                        debtId: debt.id,
                        paymentMinor: (amt * 100).toInt(),
                      );
                }
                Navigator.pop(ctx);
              },
              child: const Text('Save Payment'),
            ),
          ],
        );
      },
    );
  }
}
