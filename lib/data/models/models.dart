import 'package:flutter/foundation.dart';

/// Defines whether money was earned or spent.
enum TransactionType {
  expense,
  income;

  static TransactionType fromString(String val) {
    return TransactionType.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => TransactionType.expense,
    );
  }
}

/// Defines the category of account / wallet.
enum AccountType {
  cash,
  bank,
  creditCard,
  savings;

  static AccountType fromString(String val) {
    return AccountType.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => AccountType.cash,
    );
  }
}

/// Immutable account data class representing a wallet or bank account.
@immutable
class Account {
  final String id;
  final String name;
  final AccountType type;
  final int initialBalanceMinor;
  final String colorHex;
  final int iconCodePoint;
  final bool isDefault;
  final DateTime createdAt;

  const Account({
    required this.id,
    required this.name,
    required this.type,
    required this.initialBalanceMinor,
    required this.colorHex,
    required this.iconCodePoint,
    this.isDefault = false,
    required this.createdAt,
  });

  Account copyWith({
    String? id,
    String? name,
    AccountType? type,
    int? initialBalanceMinor,
    String? colorHex,
    int? iconCodePoint,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      initialBalanceMinor: initialBalanceMinor ?? this.initialBalanceMinor,
      colorHex: colorHex ?? this.colorHex,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'initialBalanceMinor': initialBalanceMinor,
      'colorHex': colorHex,
      'iconCodePoint': iconCodePoint,
      'isDefault': isDefault ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'] as String,
      name: map['name'] as String,
      type: AccountType.fromString(map['type'] as String),
      initialBalanceMinor: (map['initialBalanceMinor'] as num).toInt(),
      colorHex: map['colorHex'] as String,
      iconCodePoint: (map['iconCodePoint'] as num).toInt(),
      isDefault: (map['isDefault'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Account &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          type == other.type &&
          initialBalanceMinor == other.initialBalanceMinor &&
          colorHex == other.colorHex &&
          iconCodePoint == other.iconCodePoint &&
          isDefault == other.isDefault &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        type,
        initialBalanceMinor,
        colorHex,
        iconCodePoint,
        isDefault,
        createdAt,
      );
}

/// Immutable category data class.
@immutable
class Category {
  final String id;
  final String name;
  final TransactionType type;
  final int iconCodePoint;
  final String colorHex;
  final DateTime createdAt;

  const Category({
    required this.id,
    required this.name,
    required this.type,
    required this.iconCodePoint,
    required this.colorHex,
    required this.createdAt,
  });

  Category copyWith({
    String? id,
    String? name,
    TransactionType? type,
    int? iconCodePoint,
    String? colorHex,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorHex: colorHex ?? this.colorHex,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'iconCodePoint': iconCodePoint,
      'colorHex': colorHex,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String,
      name: map['name'] as String,
      type: TransactionType.fromString(map['type'] as String),
      iconCodePoint: (map['iconCodePoint'] as num).toInt(),
      colorHex: map['colorHex'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          type == other.type &&
          iconCodePoint == other.iconCodePoint &&
          colorHex == other.colorHex &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        type,
        iconCodePoint,
        colorHex,
        createdAt,
      );
}

/// Immutable transaction entry with minor unit currency storage.
@immutable
class Transaction {
  final String id;
  final String title;
  final int amountMinor;
  final TransactionType type;
  final String categoryId;
  final String accountId;
  final DateTime date;
  final String? note;
  final String? receiptPath;
  final DateTime createdAt;

  const Transaction({
    required this.id,
    required this.title,
    required this.amountMinor,
    required this.type,
    required this.categoryId,
    required this.accountId,
    required this.date,
    this.note,
    this.receiptPath,
    required this.createdAt,
  }) : assert(amountMinor > 0, 'Amount must be greater than zero');

  Transaction copyWith({
    String? id,
    String? title,
    int? amountMinor,
    TransactionType? type,
    String? categoryId,
    String? accountId,
    DateTime? date,
    String? note,
    String? receiptPath,
    DateTime? createdAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      title: title ?? this.title,
      amountMinor: amountMinor ?? this.amountMinor,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      date: date ?? this.date,
      note: note ?? this.note,
      receiptPath: receiptPath ?? this.receiptPath,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amountMinor': amountMinor,
      'type': type.name,
      'categoryId': categoryId,
      'accountId': accountId,
      'date': date.toIso8601String(),
      'note': note,
      'receiptPath': receiptPath,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as String,
      title: map['title'] as String,
      amountMinor: (map['amountMinor'] as num).toInt(),
      type: TransactionType.fromString(map['type'] as String),
      categoryId: map['categoryId'] as String,
      accountId: map['accountId'] as String,
      date: DateTime.parse(map['date'] as String),
      note: map['note'] as String?,
      receiptPath: map['receiptPath'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Transaction &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          amountMinor == other.amountMinor &&
          type == other.type &&
          categoryId == other.categoryId &&
          accountId == other.accountId &&
          date == other.date &&
          note == other.note &&
          receiptPath == other.receiptPath &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        title,
        amountMinor,
        type,
        categoryId,
        accountId,
        date,
        note,
        receiptPath,
        createdAt,
      );
}

/// Immutable Budget model per category for a given month ('YYYY-MM').
@immutable
class Budget {
  final String id;
  final String categoryId;
  final int limitMinor;
  final String monthYear;
  final DateTime createdAt;

  const Budget({
    required this.id,
    required this.categoryId,
    required this.limitMinor,
    required this.monthYear,
    required this.createdAt,
  }) : assert(limitMinor > 0, 'Budget limit must be greater than zero');

  Budget copyWith({
    String? id,
    String? categoryId,
    int? limitMinor,
    String? monthYear,
    DateTime? createdAt,
  }) {
    return Budget(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      limitMinor: limitMinor ?? this.limitMinor,
      monthYear: monthYear ?? this.monthYear,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'categoryId': categoryId,
      'limitMinor': limitMinor,
      'monthYear': monthYear,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'] as String,
      categoryId: map['categoryId'] as String,
      limitMinor: (map['limitMinor'] as num).toInt(),
      monthYear: map['monthYear'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Budget &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          categoryId == other.categoryId &&
          limitMinor == other.limitMinor &&
          monthYear == other.monthYear &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        categoryId,
        limitMinor,
        monthYear,
        createdAt,
      );
}

/// Frequency for scheduled / recurring transactions.
enum RecurringFrequency {
  daily,
  weekly,
  monthly,
  yearly;

  static RecurringFrequency fromString(String val) {
    return RecurringFrequency.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => RecurringFrequency.monthly,
    );
  }

  String get displayName {
    switch (this) {
      case RecurringFrequency.daily:
        return 'Daily';
      case RecurringFrequency.weekly:
        return 'Weekly';
      case RecurringFrequency.monthly:
        return 'Monthly';
      case RecurringFrequency.yearly:
        return 'Yearly';
    }
  }
}

/// Model for recurring template / scheduled transactions.
@immutable
class RecurringTransaction {
  final String id;
  final String title;
  final int amountMinor;
  final TransactionType type;
  final String categoryId;
  final String accountId;
  final RecurringFrequency frequency;
  final DateTime startDate;
  final DateTime? lastProcessedDate;
  final bool isActive;
  final String? note;
  final DateTime createdAt;

  const RecurringTransaction({
    required this.id,
    required this.title,
    required this.amountMinor,
    required this.type,
    required this.categoryId,
    required this.accountId,
    required this.frequency,
    required this.startDate,
    this.lastProcessedDate,
    this.isActive = true,
    this.note,
    required this.createdAt,
  });

  RecurringTransaction copyWith({
    String? id,
    String? title,
    int? amountMinor,
    TransactionType? type,
    String? categoryId,
    String? accountId,
    RecurringFrequency? frequency,
    DateTime? startDate,
    DateTime? lastProcessedDate,
    bool? isActive,
    String? note,
    DateTime? createdAt,
  }) {
    return RecurringTransaction(
      id: id ?? this.id,
      title: title ?? this.title,
      amountMinor: amountMinor ?? this.amountMinor,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      lastProcessedDate: lastProcessedDate ?? this.lastProcessedDate,
      isActive: isActive ?? this.isActive,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amountMinor': amountMinor,
      'type': type.name,
      'categoryId': categoryId,
      'accountId': accountId,
      'frequency': frequency.name,
      'startDate': startDate.toIso8601String(),
      'lastProcessedDate': lastProcessedDate?.toIso8601String(),
      'isActive': isActive ? 1 : 0,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory RecurringTransaction.fromMap(Map<String, dynamic> map) {
    return RecurringTransaction(
      id: map['id'] as String,
      title: map['title'] as String,
      amountMinor: (map['amountMinor'] as num).toInt(),
      type: TransactionType.fromString(map['type'] as String),
      categoryId: map['categoryId'] as String,
      accountId: map['accountId'] as String,
      frequency: RecurringFrequency.fromString(map['frequency'] as String),
      startDate: DateTime.parse(map['startDate'] as String),
      lastProcessedDate: map['lastProcessedDate'] != null
          ? DateTime.parse(map['lastProcessedDate'] as String)
          : null,
      isActive: (map['isActive'] as int? ?? 1) == 1,
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
