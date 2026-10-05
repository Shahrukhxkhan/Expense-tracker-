import 'package:flutter/material.dart';
import '../../data/models/derived_models.dart';
import '../../data/models/goals_and_debts_model.dart';

class SmartFinancialInsight {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isWarning;

  const SmartFinancialInsight({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.isWarning = false,
  });
}

class NetWorthSummary {
  final int cashAndBankMinor;
  final int investmentMinor;
  final int debtsOwedMinor;
  final int loansLentMinor;

  const NetWorthSummary({
    required this.cashAndBankMinor,
    required this.investmentMinor,
    required this.debtsOwedMinor,
    required this.loansLentMinor,
  });

  int get totalAssetsMinor => cashAndBankMinor + investmentMinor + loansLentMinor;
  int get totalLiabilitiesMinor => debtsOwedMinor;
  int get netWorthMinor => totalAssetsMinor - totalLiabilitiesMinor;
}

class FinancialForecasting {
  final int projectedMonthEndExpenseMinor;
  final int projectedMonthEndBalanceMinor;
  final DateTime? estimatedBudgetExhaustionDate;
  final double burnRatePerDayMinor;

  const FinancialForecasting({
    required this.projectedMonthEndExpenseMinor,
    required this.projectedMonthEndBalanceMinor,
    this.estimatedBudgetExhaustionDate,
    required this.burnRatePerDayMinor,
  });
}

class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  /// Calculate real-time net worth aggregating account balances, savings goals, and debts
  NetWorthSummary calculateNetWorth({
    required int currentTotalBalanceMinor,
    required List<FinancialGoal> goals,
    required List<DebtItem> debts,
  }) {
    int liquidCash = currentTotalBalanceMinor;
    int investments = 0;

    // Include savings goals in assets
    for (final g in goals) {
      investments += g.currentSavedMinor;
    }

    int debtsOwed = 0;
    int loansLent = 0;

    for (final d in debts) {
      if (!d.isSettled) {
        if (d.type == DebtType.borrowed) {
          debtsOwed += d.remainingBalanceMinor;
        } else {
          loansLent += d.remainingBalanceMinor;
        }
      }
    }

    return NetWorthSummary(
      cashAndBankMinor: liquidCash,
      investmentMinor: investments,
      debtsOwedMinor: debtsOwed,
      loansLentMinor: loansLent,
    );
  }

  /// Forecast month-end financial runway & budget exhaustion
  FinancialForecasting forecastMonthEnd({
    required int currentMonthSpentMinor,
    required int currentMonthIncomeMinor,
    required int currentBalanceMinor,
  }) {
    final now = DateTime.now();
    final dayOfMonth = now.day;
    final totalDaysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final remainingDays = totalDaysInMonth - dayOfMonth;

    final burnRatePerDay = dayOfMonth > 0
        ? (currentMonthSpentMinor / dayOfMonth)
        : currentMonthSpentMinor.toDouble();

    final projectedExpenseMinor =
        (currentMonthSpentMinor + (burnRatePerDay * remainingDays)).round();

    final projectedBalanceMinor =
        currentBalanceMinor - (burnRatePerDay * remainingDays).round();

    DateTime? exhaustionDate;
    if (burnRatePerDay > 0 && currentBalanceMinor > 0) {
      final daysLeftUntilZero = (currentBalanceMinor / burnRatePerDay).floor();
      if (daysLeftUntilZero < remainingDays && daysLeftUntilZero > 0) {
        exhaustionDate = now.add(Duration(days: daysLeftUntilZero));
      }
    }

    return FinancialForecasting(
      projectedMonthEndExpenseMinor: projectedExpenseMinor,
      projectedMonthEndBalanceMinor: projectedBalanceMinor,
      estimatedBudgetExhaustionDate: exhaustionDate,
      burnRatePerDayMinor: burnRatePerDay,
    );
  }

  /// Detect spending anomalies (e.g., categories spiking vs previous averages)
  List<SmartFinancialInsight> detectAnomaliesAndInsights({
    required List<CategorySpendingSummary> currentSpending,
    required int currentMonthIncomeMinor,
    required int currentMonthExpenseMinor,
  }) {
    final insights = <SmartFinancialInsight>[];

    // 1. Savings Rate Insight
    if (currentMonthIncomeMinor > 0) {
      final savings = currentMonthIncomeMinor - currentMonthExpenseMinor;
      final savingsRate = (savings / currentMonthIncomeMinor) * 100;
      if (savingsRate >= 20) {
        insights.add(
          SmartFinancialInsight(
            title: 'Healthy Savings Rate: ${savingsRate.toStringAsFixed(0)}% 🎯',
            description:
                'You have retained over 20% of your earnings this month. Well above standard recommendation.',
            icon: Icons.savings_outlined,
            color: Colors.green,
            isWarning: false,
          ),
        );
      } else if (savingsRate < 5 && savingsRate >= 0) {
        insights.add(
          const SmartFinancialInsight(
            title: 'Tight Monthly Margins ⚠️',
            description:
                'Your current expenses are consuming over 95% of monthly income. Consider cutting non-essential subscriptions.',
            icon: Icons.warning_amber_rounded,
            color: Colors.orange,
            isWarning: true,
          ),
        );
      } else if (savings < 0) {
        insights.add(
          const SmartFinancialInsight(
            title: 'Deficit Alert: Negative Cashflow 🚨',
            description:
                'You have spent more than you earned this month. Review high-value purchases to avoid tapping debt.',
            icon: Icons.trending_down,
            color: Colors.red,
            isWarning: true,
          ),
        );
      }
    }

    // 2. Category Concentration Anomaly
    for (final cat in currentSpending) {
      if (cat.percentage >= 40.0) {
        insights.add(
          SmartFinancialInsight(
            title: 'High Spending Spike in ${cat.category.name} 📈',
            description:
                '${cat.category.name} accounts for ${cat.percentage.toStringAsFixed(0)}% of your total outflows this month.',
            icon: Icons.pie_chart_outline,
            color: Colors.amber,
            isWarning: true,
          ),
        );
      }
    }

    if (insights.isEmpty) {
      insights.add(
        const SmartFinancialInsight(
          title: 'Steady & Predictable Spending 🧘',
          description:
              'No unusual spending anomalies detected this billing cycle. On track with typical patterns.',
          icon: Icons.check_circle_outline,
          color: Colors.blue,
          isWarning: false,
        ),
      );
    }

    return insights;
  }
}
