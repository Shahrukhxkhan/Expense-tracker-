import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/services/analytics_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/derived_models.dart';
import '../providers/expense_providers.dart';
import '../providers/goals_and_debts_provider.dart';
import '../widgets/category_chip.dart';

class VisualAnalyticsScreen extends ConsumerStatefulWidget {
  const VisualAnalyticsScreen({super.key});

  @override
  ConsumerState<VisualAnalyticsScreen> createState() =>
      _VisualAnalyticsScreenState();
}

class _VisualAnalyticsScreenState extends ConsumerState<VisualAnalyticsScreen> {
  int _selectedDonutIndex = -1;

  @override
  Widget build(BuildContext context) {
    final balanceAsync = ref.watch(currentBalanceProvider);
    final monthTotalsAsync = ref.watch(currentMonthTotalsProvider);
    final spendingAsync = ref.watch(categorySpendingProvider);
    final historyAsync = ref.watch(monthlyFlowHistoryProvider);
    final totals = monthTotalsAsync.value ?? (incomeMinor: 0, expenseMinor: 0);
    final balance = balanceAsync.value ?? 0;
    final spendingList = spendingAsync.value ?? [];
    final history = historyAsync.value ?? [];
    final allTx = allTxAsync.value ?? [];

    // Net worth computation
    final netWorth = AnalyticsService.instance.calculateNetWorth(
      currentTotalBalanceMinor: balance,
      goals: goals,
      debts: debts,
    );

    // Forecasting
    final forecast = AnalyticsService.instance.forecastMonthEnd(
      currentMonthSpentMinor: totals.expenseMinor,
      currentMonthIncomeMinor: totals.incomeMinor,
      currentBalanceMinor: balance,
    );

    // Anomalies & Insights
    final insights = AnalyticsService.instance.detectAnomaliesAndInsights(
      currentSpending: spendingList,
      currentMonthIncomeMinor: totals.incomeMinor,
      currentMonthExpenseMinor: totals.expenseMinor,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics & Visual Insights'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. NET WORTH TRACKER HERO CARD
          _buildNetWorthHeroCard(netWorth),

          const SizedBox(height: 20),

          // 2. SMART INSIGHTS & ANOMALY DETECTION
          _buildSectionHeader('Smart AI Financial Insights', Icons.auto_awesome),
          const SizedBox(height: 8),
          ...insights.map((insight) => _buildInsightCard(insight)),

          const SizedBox(height: 20),

          // 3. FINANCIAL FORECASTING & RUNWAY
          _buildSectionHeader('Month-End Forecast & Runway', Icons.timeline),
          const SizedBox(height: 8),
          _buildForecastingCard(forecast),

          const SizedBox(height: 20),

          // 4. CASHFLOW TRENDS (INCOME VS EXPENSE)
          _buildSectionHeader('Cashflow History (6-Month Trend)', Icons.bar_chart),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildLegend(AppColors.income, 'Income'),
                      const SizedBox(width: 12),
                      _buildLegend(AppColors.expense, 'Expense'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 200,
                    child: history.isEmpty
                        ? const Center(child: Text('No historical transactions'))
                        : _buildHistoryBarChart(history),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 5. INTERACTIVE CATEGORY DRILL-DOWN DONUT
          _buildSectionHeader('Interactive Category Breakdown', Icons.donut_large),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tap any slice to drill down into transaction history',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  if (spendingList.isEmpty)
                    const Center(child: Text('No expenses recorded this month'))
                  else ...[
                    SizedBox(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 3,
                          centerSpaceRadius: 50,
                          pieTouchData: PieTouchData(
                            touchCallback: (event, pieTouchResponse) {
                              setState(() {
                                if (!event.isInterestedForInteractions ||
                                    pieTouchResponse == null ||
                                    pieTouchResponse.touchedSection == null) {
                                  _selectedDonutIndex = -1;
                                  return;
                                }
                                _selectedDonutIndex = pieTouchResponse
                                    .touchedSection!.touchedSectionIndex;
                              });
                            },
                          ),
                          sections: spendingList.take(6).toList().asMap().entries.map((entry) {
                            final idx = entry.key;
                            final item = entry.value;
                            final isTouched = idx == _selectedDonutIndex;
                            return PieChartSectionData(
                              color: parseHexColor(item.category.colorHex),
                              value: item.percentage,
                              radius: isTouched ? 42.0 : 32.0,
                              title: '${item.percentage.toStringAsFixed(0)}%',
                              titleStyle: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Drill-down Details
                    if (_selectedDonutIndex >= 0 &&
                        _selectedDonutIndex < spendingList.length)
                      _buildDrillDownCategoryHistory(
                        spendingList[_selectedDonutIndex],
                        allTx,
                      )
                    else
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: spendingList.map((item) {
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: parseHexColor(item.category.colorHex),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${item.category.name} (${item.percentage.toStringAsFixed(0)}%)',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildNetWorthHeroCard(NetWorthSummary netWorth) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.tertiary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TOTAL NET WORTH',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            CurrencyFormatter.formatMinor(netWorth.netWorthMinor),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildNetWorthMetric(
                  'Total Assets',
                  CurrencyFormatter.formatMinor(netWorth.totalAssetsMinor),
                  Colors.white,
                ),
              ),
              Expanded(
                child: _buildNetWorthMetric(
                  'Liabilities / Debts',
                  CurrencyFormatter.formatMinor(netWorth.totalLiabilitiesMinor),
                  Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNetWorthMetric(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildInsightCard(SmartFinancialInsight insight) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: insight.color.withValues(alpha: 0.15),
          child: Icon(insight.icon, color: insight.color, size: 22),
        ),
        title: Text(
          insight.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          insight.description,
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildForecastingCard(FinancialForecasting forecast) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildForecastMetric(
                    'Daily Burn Rate',
                    CurrencyFormatter.formatMinor(
                        forecast.burnRatePerDayMinor.round()),
                    Icons.local_fire_department_outlined,
                  ),
                ),
                Expanded(
                  child: _buildForecastMetric(
                    'Projected Spend',
                    CurrencyFormatter.formatMinor(
                        forecast.projectedMonthEndExpenseMinor),
                    Icons.trending_up,
                  ),
                ),
                Expanded(
                  child: _buildForecastMetric(
                    'Projected Balance',
                    CurrencyFormatter.formatMinor(
                        forecast.projectedMonthEndBalanceMinor),
                    Icons.account_balance_wallet_outlined,
                  ),
                ),
              ],
            ),
            if (forecast.estimatedBudgetExhaustionDate != null) ...[
              const Divider(height: 24),
              Row(
                children: [
                  const Icon(Icons.timer_outlined, color: Colors.orange, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'At current pace, balance runs out around ${DateFormat('MMM dd').format(forecast.estimatedBudgetExhaustionDate!)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildForecastMetric(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildHistoryBarChart(List<MonthlyFlowSummary> history) {
    double maxVal = 0;
    for (final h in history) {
      if (h.totalIncomeMinor > maxVal) maxVal = h.totalIncomeMinor.toDouble();
      if (h.totalExpenseMinor > maxVal) maxVal = h.totalExpenseMinor.toDouble();
    }
    if (maxVal == 0) maxVal = 10000;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (maxVal / 100) * 1.2,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) {
                final idx = val.toInt();
                if (idx >= 0 && idx < history.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      history[idx].monthLabel,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
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
        barGroups: history.asMap().entries.map((entry) {
          final idx = entry.key;
          final flow = entry.value;
          return BarChartGroupData(
            x: idx,
            barRods: [
              BarChartRodData(
                toY: flow.totalIncomeMinor / 100.0,
                color: AppColors.income,
                width: 8,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
              BarChartRodData(
                toY: flow.totalExpenseMinor / 100.0,
                color: AppColors.expense,
                width: 8,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDrillDownCategoryHistory(
    CategorySpendingSummary summary,
    List<TransactionWithDetails> allTx,
  ) {
    final catTx = allTx.where((t) => t.category.id == summary.category.id).take(4).toList();
    final color = parseHexColor(summary.category.colorHex);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Drill-down: ${summary.category.name}',
                style: TextStyle(fontWeight: FontWeight.bold, color: color),
              ),
              Text(
                '${CurrencyFormatter.formatMinor(summary.totalSpentMinor)} (${summary.percentage.toStringAsFixed(0)}%)',
                style: TextStyle(fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (catTx.isEmpty)
            const Text('No recent items for this category.', style: TextStyle(fontSize: 12))
          else
            ...catTx.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item.transaction.title, style: const TextStyle(fontSize: 12)),
                    Text(
                      CurrencyFormatter.formatMinor(item.transaction.amountMinor),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
