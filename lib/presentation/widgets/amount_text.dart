import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:flutter/material.dart';

/// Reusable formatted currency widget with semantic colors.
class AmountText extends StatelessWidget {
  final int amountMinor;
  final TextStyle? style;
  final bool isIncome;
  final bool showSign;

  const AmountText({
    super.key,
    required this.amountMinor,
    this.style,
    this.isIncome = false,
    this.showSign = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = isIncome ? AppColors.income : AppColors.expense;
    final prefix = showSign ? (isIncome ? '+' : '-') : '';
    final formatted = CurrencyFormatter.formatMinor(amountMinor.abs());

    return Text(
      '$prefix$formatted',
      style: (style ?? const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)).copyWith(
        color: color,
      ),
    );
  }
}
