import 'package:flutter/foundation.dart';

@immutable
class Trip {
  final String id;
  final String name;
  final String destination;
  final String currencyCode;
  final int totalBudgetMinor;
  final int dailyAllowanceMinor;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final DateTime createdAt;

  const Trip({
    required this.id,
    required this.name,
    required this.destination,
    required this.currencyCode,
    required this.totalBudgetMinor,
    required this.dailyAllowanceMinor,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
    required this.createdAt,
  });

  int get totalDays {
    final diff = endDate.difference(startDate).inDays;
    return diff <= 0 ? 1 : diff + 1;
  }

  Trip copyWith({
    String? id,
    String? name,
    String? destination,
    String? currencyCode,
    int? totalBudgetMinor,
    int? dailyAllowanceMinor,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Trip(
      id: id ?? this.id,
      name: name ?? this.name,
      destination: destination ?? this.destination,
      currencyCode: currencyCode ?? this.currencyCode,
      totalBudgetMinor: totalBudgetMinor ?? this.totalBudgetMinor,
      dailyAllowanceMinor: dailyAllowanceMinor ?? this.dailyAllowanceMinor,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'destination': destination,
      'currencyCode': currencyCode,
      'totalBudgetMinor': totalBudgetMinor,
      'dailyAllowanceMinor': dailyAllowanceMinor,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Trip.fromMap(Map<String, dynamic> map) {
    return Trip(
      id: map['id'] as String,
      name: map['name'] as String,
      destination: map['destination'] as String,
      currencyCode: map['currencyCode'] as String? ?? 'USD',
      totalBudgetMinor: (map['totalBudgetMinor'] as num).toInt(),
      dailyAllowanceMinor: (map['dailyAllowanceMinor'] as num).toInt(),
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: DateTime.parse(map['endDate'] as String),
      isActive: (map['isActive'] as int? ?? 1) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}

class TripExpenseItem {
  final String id;
  final String tripId;
  final String title;
  final int amountMinor;
  final String categoryName;
  final DateTime date;

  const TripExpenseItem({
    required this.id,
    required this.tripId,
    required this.title,
    required this.amountMinor,
    required this.categoryName,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tripId': tripId,
      'title': title,
      'amountMinor': amountMinor,
      'categoryName': categoryName,
      'date': date.toIso8601String(),
    };
  }

  factory TripExpenseItem.fromMap(Map<String, dynamic> map) {
    return TripExpenseItem(
      id: map['id'] as String,
      tripId: map['tripId'] as String,
      title: map['title'] as String,
      amountMinor: (map['amountMinor'] as num).toInt(),
      categoryName: map['categoryName'] as String,
      date: DateTime.parse(map['date'] as String),
    );
  }
}

class TripSummary {
  final Trip trip;
  final int totalSpentMinor;
  final int remainingBudgetMinor;
  final int todaySpentMinor;
  final double budgetUsagePercentage;
  final List<TripExpenseItem> expenses;

  const TripSummary({
    required this.trip,
    required this.totalSpentMinor,
    required this.remainingBudgetMinor,
    required this.todaySpentMinor,
    required this.budgetUsagePercentage,
    required this.expenses,
  });
}
