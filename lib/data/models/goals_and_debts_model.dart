import 'package:flutter/foundation.dart';

/// Type of financial goal
enum GoalType {
  savings,
  sinkingFund,
  emergencyFund;

  static GoalType fromString(String val) {
    return GoalType.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => GoalType.savings,
    );
  }
}

/// Savings goal & sinking fund model
@immutable
class FinancialGoal {
  final String id;
  final String title;
  final int targetAmountMinor;
  final int currentSavedMinor;
  final DateTime targetDate;
  final String colorHex;
  final int iconCodePoint;
  final GoalType type;
  final DateTime createdAt;

  const FinancialGoal({
    required this.id,
    required this.title,
    required this.targetAmountMinor,
    required this.currentSavedMinor,
    required this.targetDate,
    required this.colorHex,
    required this.iconCodePoint,
    required this.type,
    required this.createdAt,
  });

  double get progressPercentage {
    if (targetAmountMinor <= 0) return 0.0;
    return (currentSavedMinor / targetAmountMinor).clamp(0.0, 1.0);
  }

  int get remainingAmountMinor {
    final diff = targetAmountMinor - currentSavedMinor;
    return diff < 0 ? 0 : diff;
  }

  bool get isAchieved => currentSavedMinor >= targetAmountMinor;

  FinancialGoal copyWith({
    String? id,
    String? title,
    int? targetAmountMinor,
    int? currentSavedMinor,
    DateTime? targetDate,
    String? colorHex,
    int? iconCodePoint,
    GoalType? type,
    DateTime? createdAt,
  }) {
    return FinancialGoal(
      id: id ?? this.id,
      title: title ?? this.title,
      targetAmountMinor: targetAmountMinor ?? this.targetAmountMinor,
      currentSavedMinor: currentSavedMinor ?? this.currentSavedMinor,
      targetDate: targetDate ?? this.targetDate,
      colorHex: colorHex ?? this.colorHex,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'targetAmountMinor': targetAmountMinor,
        'currentSavedMinor': currentSavedMinor,
        'targetDate': targetDate.toIso8601String(),
        'colorHex': colorHex,
        'iconCodePoint': iconCodePoint,
        'type': type.name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory FinancialGoal.fromMap(Map<String, dynamic> map) => FinancialGoal(
        id: map['id'] as String,
        title: map['title'] as String,
        targetAmountMinor: (map['targetAmountMinor'] as num).toInt(),
        currentSavedMinor: (map['currentSavedMinor'] as num).toInt(),
        targetDate: DateTime.parse(map['targetDate'] as String),
        colorHex: map['colorHex'] as String,
        iconCodePoint: (map['iconCodePoint'] as num).toInt(),
        type: GoalType.fromString(map['type'] as String),
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}

/// Type of debt or loan
enum DebtType {
  borrowed, // Money you owe to someone / bank loan / credit card balance
  lent;     // Money someone owes you (IOU)

  static DebtType fromString(String val) {
    return DebtType.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => DebtType.borrowed,
    );
  }
}

/// Loan, Debt & EMI tracker model
@immutable
class DebtItem {
  final String id;
  final String counterparty; // Bank name or Person name
  final String title;
  final DebtType type;
  final int principalAmountMinor;
  final int paidAmountMinor;
  final double interestRatePercentage; // e.g. 5.5%
  final int monthlyEmiMinor; // Monthly installment
  final DateTime dueDate;
  final bool isSettled;
  final DateTime createdAt;

  const DebtItem({
    required this.id,
    required this.counterparty,
    required this.title,
    required this.type,
    required this.principalAmountMinor,
    required this.paidAmountMinor,
    this.interestRatePercentage = 0.0,
    this.monthlyEmiMinor = 0,
    required this.dueDate,
    this.isSettled = false,
    required this.createdAt,
  });

  int get remainingBalanceMinor {
    final diff = principalAmountMinor - paidAmountMinor;
    return diff < 0 ? 0 : diff;
  }

  double get repaymentProgress {
    if (principalAmountMinor <= 0) return 0.0;
    return (paidAmountMinor / principalAmountMinor).clamp(0.0, 1.0);
  }

  DebtItem copyWith({
    String? id,
    String? counterparty,
    String? title,
    DebtType? type,
    int? principalAmountMinor,
    int? paidAmountMinor,
    double? interestRatePercentage,
    int? monthlyEmiMinor,
    DateTime? dueDate,
    bool? isSettled,
    DateTime? createdAt,
  }) {
    return DebtItem(
      id: id ?? this.id,
      counterparty: counterparty ?? this.counterparty,
      title: title ?? this.title,
      type: type ?? this.type,
      principalAmountMinor: principalAmountMinor ?? this.principalAmountMinor,
      paidAmountMinor: paidAmountMinor ?? this.paidAmountMinor,
      interestRatePercentage: interestRatePercentage ?? this.interestRatePercentage,
      monthlyEmiMinor: monthlyEmiMinor ?? this.monthlyEmiMinor,
      dueDate: dueDate ?? this.dueDate,
      isSettled: isSettled ?? this.isSettled,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'counterparty': counterparty,
        'title': title,
        'type': type.name,
        'principalAmountMinor': principalAmountMinor,
        'paidAmountMinor': paidAmountMinor,
        'interestRatePercentage': interestRatePercentage,
        'monthlyEmiMinor': monthlyEmiMinor,
        'dueDate': dueDate.toIso8601String(),
        'isSettled': isSettled ? 1 : 0,
        'createdAt': createdAt.toIso8601String(),
      };

  factory DebtItem.fromMap(Map<String, dynamic> map) => DebtItem(
        id: map['id'] as String,
        counterparty: map['counterparty'] as String,
        title: map['title'] as String,
        type: DebtType.fromString(map['type'] as String),
        principalAmountMinor: (map['principalAmountMinor'] as num).toInt(),
        paidAmountMinor: (map['paidAmountMinor'] as num).toInt(),
        interestRatePercentage:
            (map['interestRatePercentage'] as num?)?.toDouble() ?? 0.0,
        monthlyEmiMinor: (map['monthlyEmiMinor'] as num?)?.toInt() ?? 0,
        dueDate: DateTime.parse(map['dueDate'] as String),
        isSettled: (map['isSettled'] as int? ?? 0) == 1,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}
