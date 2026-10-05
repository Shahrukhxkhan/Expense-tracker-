import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Widget Data Model for Home Screen / Quick Glances
class ExpenseWidgetData {
  final double totalIncome;
  final double totalExpense;
  final double remainingBudget;
  final double netBalance;
  final String currencySymbol;
  final DateTime lastUpdated;

  const ExpenseWidgetData({
    required this.totalIncome,
    required this.totalExpense,
    required this.remainingBudget,
    required this.netBalance,
    this.currencySymbol = '\$',
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() => {
        'totalIncome': totalIncome,
        'totalExpense': totalExpense,
        'remainingBudget': remainingBudget,
        'netBalance': netBalance,
        'currencySymbol': currencySymbol,
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  factory ExpenseWidgetData.fromJson(Map<String, dynamic> json) =>
      ExpenseWidgetData(
        totalIncome: (json['totalIncome'] as num?)?.toDouble() ?? 0.0,
        totalExpense: (json['totalExpense'] as num?)?.toDouble() ?? 0.0,
        remainingBudget: (json['remainingBudget'] as num?)?.toDouble() ?? 0.0,
        netBalance: (json['netBalance'] as num?)?.toDouble() ?? 0.0,
        currencySymbol: json['currencySymbol'] as String? ?? '\$',
        lastUpdated: DateTime.tryParse(json['lastUpdated'] ?? '') ??
            DateTime.now(),
      );
}

/// Service to sync data to native widget storage / app group
class WidgetBridgeService {
  WidgetBridgeService._();
  static final WidgetBridgeService instance = WidgetBridgeService._();

  ExpenseWidgetData? _cachedData;
  ExpenseWidgetData? get cachedData => _cachedData;

  /// Update widget summary data and broadcast to platform widget
  Future<void> updateWidgetData({
    required double totalIncome,
    required double totalExpense,
    required double remainingBudget,
    required double netBalance,
  }) async {
    _cachedData = ExpenseWidgetData(
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      remainingBudget: remainingBudget,
      netBalance: netBalance,
      lastUpdated: DateTime.now(),
    );

    try {
      debugPrint('Widget data refreshed: ${jsonEncode(_cachedData!.toJson())}');
      // In native integration, save to SharedPreferences / AppGroup UserDefaults
      // for iOS WidgetKit / Android Glance/AppWidgetProvider.
    } catch (e) {
      debugPrint('Failed to sync widget data: $e');
    }
  }
}
