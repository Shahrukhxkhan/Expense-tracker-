import 'package:fl_chart/fl_chart.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/data/models/derived_models.dart';
import 'package:expense_tracker/presentation/widgets/category_chip.dart';
import 'package:flutter/material.dart';

/// Donut chart displaying spending split across top categories.
class CategoryDonutChart extends StatefulWidget {
  final List<CategorySpendingSummary> spendingList;

  const CategoryDonutChart({super.key, required this.spendingList});

  @override
  State<CategoryDonutChart> createState() => _CategoryDonutChartState();
}

class _CategoryDonutChartState extends State<CategoryDonutChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.spendingList.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(child: Text('No expense data this month')),
      );
    }

    final topItems = widget.spendingList.take(5).toList();

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      touchedIndex = -1;
                      return;
                    }
                    touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 3,
              centerSpaceRadius: 46,
              sections: topItems.asMap().entries.map((entry) {
                final idx = entry.key;
                final data = entry.value;
                final isTouched = idx == touchedIndex;
                final fontSize = isTouched ? 14.0 : 11.0;
                final radius = isTouched ? 38.0 : 30.0;
                final color = parseHexColor(data.category.colorHex);

                return PieChartSectionData(
                  color: color,
                  value: data.percentage,
                  title: '${data.percentage.toStringAsFixed(0)}%',
                  radius: radius,
                  titleStyle: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: topItems.map((item) {
            final color = parseHexColor(item.category.colorHex);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 4),
                Text(
                  item.category.name,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// 6-month historical bar chart showing Income vs Expense trends.
class SixMonthBarChart extends StatelessWidget {
  final List<MonthlyFlowSummary> history;

  const SixMonthBarChart({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const SizedBox(height: 180, child: Center(child: Text('No historical trends')));
    }

    double maxVal = 0;
    for (final h in history) {
      if (h.totalIncomeMinor > maxVal) maxVal = h.totalIncomeMinor.toDouble();
      if (h.totalExpenseMinor > maxVal) maxVal = h.totalExpenseMinor.toDouble();
    }
    if (maxVal == 0) maxVal = 10000;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      height: 220,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: (maxVal / 100) * 1.2,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final isIncome = rodIndex == 0;
                final flow = history[groupIndex];
                final val = isIncome ? flow.totalIncomeMinor : flow.totalExpenseMinor;
                return BarTooltipItem(
                  '${isIncome ? "Income" : "Expense"}\n${CurrencyFormatter.formatMinor(val)}',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (val, meta) {
                  final idx = val.toInt();
                  if (idx >= 0 && idx < history.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Text(
                        history[idx].monthLabel,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: history.asMap().entries.map((entry) {
            final idx = entry.key;
            final data = entry.value;
            return BarChartGroupData(
              x: idx,
              barRods: [
                BarChartRodData(
                  toY: data.totalIncomeMinor / 100.0,
                  color: AppColors.income,
                  width: 9,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
                BarChartRodData(
                  toY: data.totalExpenseMinor / 100.0,
                  color: AppColors.expense,
                  width: 9,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
