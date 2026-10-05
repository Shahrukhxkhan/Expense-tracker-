import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/goals_and_debts_model.dart';

class GoalsNotifier extends StateNotifier<List<FinancialGoal>> {
  GoalsNotifier() : super([]) {
    _initDemoGoals();
  }

  void _initDemoGoals() {
    final now = DateTime.now();
    state = [
      FinancialGoal(
        id: const Uuid().v4(),
        title: 'Emergency Fund 🛡️',
        targetAmountMinor: 500000, // $5,000.00
        currentSavedMinor: 320000, // $3,200.00
        targetDate: now.add(const Duration(days: 120)),
        colorHex: '#10B981',
        iconCodePoint: 0xe5d0, // security
        type: GoalType.emergencyFund,
        createdAt: now.subtract(const Duration(days: 60)),
      ),
      FinancialGoal(
        id: const Uuid().v4(),
        title: 'Vacation Trip ✈️',
        targetAmountMinor: 120000, // $1,200.00
        currentSavedMinor: 75000, // $750.00
        targetDate: now.add(const Duration(days: 90)),
        colorHex: '#6366F1',
        iconCodePoint: 0xe28f, // flight
        type: GoalType.savings,
        createdAt: now.subtract(const Duration(days: 30)),
      ),
      FinancialGoal(
        id: const Uuid().v4(),
        title: 'MacBook Upgrade 💻',
        targetAmountMinor: 200000, // $2,000.00
        currentSavedMinor: 60000, // $600.00
        targetDate: now.add(const Duration(days: 180)),
        colorHex: '#0EA5E9',
        iconCodePoint: 0xe39d, // laptop
        type: GoalType.sinkingFund,
        createdAt: now.subtract(const Duration(days: 15)),
      ),
    ];
  }

  void addGoal({
    required String title,
    required int targetAmountMinor,
    required DateTime targetDate,
    required String colorHex,
    required GoalType type,
  }) {
    final newGoal = FinancialGoal(
      id: const Uuid().v4(),
      title: title,
      targetAmountMinor: targetAmountMinor,
      currentSavedMinor: 0,
      targetDate: targetDate,
      colorHex: colorHex,
      iconCodePoint: 0xe5d0,
      type: type,
      createdAt: DateTime.now(),
    );
    state = [newGoal, ...state];
  }

  void depositToGoal({
    required String goalId,
    required int amountMinor,
  }) {
    state = state.map((g) {
      if (g.id == goalId) {
        return g.copyWith(
          currentSavedMinor: g.currentSavedMinor + amountMinor,
        );
      }
      return g;
    }).toList();
  }

  void withdrawFromGoal({
    required String goalId,
    required int amountMinor,
  }) {
    state = state.map((g) {
      if (g.id == goalId) {
        final newSaved = (g.currentSavedMinor - amountMinor).clamp(0, g.targetAmountMinor * 2);
        return g.copyWith(currentSavedMinor: newSaved);
      }
      return g;
    }).toList();
  }

  void deleteGoal(String id) {
    state = state.where((g) => g.id != id).toList();
  }
}

class DebtsNotifier extends StateNotifier<List<DebtItem>> {
  DebtsNotifier() : super([]) {
    _initDemoDebts();
  }

  void _initDemoDebts() {
    final now = DateTime.now();
    state = [
      DebtItem(
        id: const Uuid().v4(),
        counterparty: 'Chase Bank',
        title: 'Auto Loan Financing',
        type: DebtType.borrowed,
        principalAmountMinor: 1500000, // $15,000.00
        paidAmountMinor: 450000, // $4,500.00
        interestRatePercentage: 4.8,
        monthlyEmiMinor: 32000, // $320.00/mo
        dueDate: now.add(const Duration(days: 14)),
        isSettled: false,
        createdAt: now.subtract(const Duration(days: 90)),
      ),
      DebtItem(
        id: const Uuid().v4(),
        counterparty: 'Alex Miller',
        title: 'Dinner & Concert Tickets IOU',
        type: DebtType.lent, // Alex owes user
        principalAmountMinor: 18000, // $180.00
        paidAmountMinor: 5000, // $50.00
        interestRatePercentage: 0.0,
        monthlyEmiMinor: 0,
        dueDate: now.add(const Duration(days: 7)),
        isSettled: false,
        createdAt: now.subtract(const Duration(days: 10)),
      ),
    ];
  }

  void addDebt({
    required String counterparty,
    required String title,
    required DebtType type,
    required int principalAmountMinor,
    double interestRatePercentage = 0.0,
    int monthlyEmiMinor = 0,
    required DateTime dueDate,
  }) {
    final item = DebtItem(
      id: const Uuid().v4(),
      counterparty: counterparty,
      title: title,
      type: type,
      principalAmountMinor: principalAmountMinor,
      paidAmountMinor: 0,
      interestRatePercentage: interestRatePercentage,
      monthlyEmiMinor: monthlyEmiMinor,
      dueDate: dueDate,
      isSettled: false,
      createdAt: DateTime.now(),
    );
    state = [item, ...state];
  }

  void recordRepayment({
    required String debtId,
    required int paymentMinor,
  }) {
    state = state.map((d) {
      if (d.id == debtId) {
        final newPaid = d.paidAmountMinor + paymentMinor;
        final settled = newPaid >= d.principalAmountMinor;
        return d.copyWith(
          paidAmountMinor: newPaid,
          isSettled: settled,
        );
      }
      return d;
    }).toList();
  }

  void deleteDebt(String id) {
    state = state.where((d) => d.id != id).toList();
  }
}

final goalsProvider =
    StateNotifierProvider<GoalsNotifier, List<FinancialGoal>>(
  (ref) => GoalsNotifier(),
);

final debtsProvider =
    StateNotifierProvider<DebtsNotifier, List<DebtItem>>(
  (ref) => DebtsNotifier(),
);
