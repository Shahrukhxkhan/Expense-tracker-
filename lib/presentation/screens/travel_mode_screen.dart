import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/currency_service.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/trip_model.dart';
import '../providers/travel_provider.dart';

class TravelModeScreen extends ConsumerStatefulWidget {
  const TravelModeScreen({super.key});

  @override
  ConsumerState<TravelModeScreen> createState() => _TravelModeScreenState();
}

class _TravelModeScreenState extends ConsumerState<TravelModeScreen> {
  @override
  Widget build(BuildContext context) {
    final trips = ref.watch(travelModeProvider);
    final activeCurrency = ref.watch(selectedCurrencyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Travel & Multi-Currency'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Active Currency',
            icon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  activeCurrency,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const Icon(Icons.arrow_drop_down, size: 20),
              ],
            ),
            onSelected: (code) {
              ref.read(selectedCurrencyProvider.notifier).state = code;
            },
            itemBuilder: (context) {
              return CurrencyService.supportedCurrencies.values.map((info) {
                return PopupMenuItem<String>(
                  value: info.code,
                  child: Row(
                    children: [
                      Text(
                        info.symbol,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Text('${info.code} - ${info.name}'),
                    ],
                  ),
                );
              }).toList();
            },
          ),
          IconButton(
            icon: const Icon(Icons.currency_exchange),
            tooltip: 'Currency Calculator',
            onPressed: () => _showCurrencyConverterDialog(context),
          ),
        ],
      ),
      body: trips.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.flight_takeoff, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No Trips Planned Yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('Create a dedicated trip container with local currency!'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showCreateTripDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Create New Trip'),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Active Trips & Allowances',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onPressed: () => _showCreateTripDialog(context),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Trip'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...trips.map((summary) => _buildTripCard(context, summary)),
              ],
            ),
    );
  }

  Widget _buildTripCard(BuildContext context, TripSummary summary) {
    final trip = summary.trip;
    final currencyInfo = CurrencyService.instance.getCurrency(trip.currencyCode);
    final isOverBudget = summary.remainingBudgetMinor < 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            trip.destination,
                            style: const TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${trip.currencyCode} (${currencyInfo.symbol})',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Budget stats
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    'Spent',
                    '${currencyInfo.symbol}${(summary.totalSpentMinor / 100).toStringAsFixed(0)}',
                    color: AppColors.expense,
                  ),
                ),
                Expanded(
                  child: _buildMetricTile(
                    'Remaining',
                    '${currencyInfo.symbol}${(summary.remainingBudgetMinor / 100).toStringAsFixed(0)}',
                    color: isOverBudget ? AppColors.expense : AppColors.income,
                  ),
                ),
                Expanded(
                  child: _buildMetricTile(
                    'Daily Allowance',
                    '${currencyInfo.symbol}${(trip.dailyAllowanceMinor / 100).toStringAsFixed(0)}/day',
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: summary.budgetUsagePercentage,
                minHeight: 8,
                backgroundColor: Colors.grey.withValues(alpha: 0.2),
                color: isOverBudget ? AppColors.expense : AppColors.income,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(summary.budgetUsagePercentage * 100).toInt()}% budget utilized',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  'Total Budget: ${currencyInfo.symbol}${(trip.totalBudgetMinor / 100).toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const Divider(height: 24),

            // Today's Expense & Action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Today's Spend: ${currencyInfo.symbol}${(summary.todaySpentMinor / 100).toStringAsFixed(0)}",
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                OutlinedButton.icon(
                  onPressed: () => _showAddTripExpenseDialog(context, trip),
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('+ Trip Expense', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),

            if (summary.expenses.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Recent Trip Expenses:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
              ),
              const SizedBox(height: 6),
              ...summary.expenses.take(3).map((exp) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(exp.title, style: const TextStyle(fontSize: 13)),
                      Text(
                        '-${currencyInfo.symbol}${(exp.amountMinor / 100).toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.expense,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, {required Color color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  void _showCreateTripDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final destCtrl = TextEditingController();
    final budgetCtrl = TextEditingController();
    final dailyCtrl = TextEditingController();
    String selectedCurrency = 'EUR';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return AlertDialog(
              title: const Text('Create Travel Container'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Trip Name (e.g. Europe 2026)'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: destCtrl,
                      decoration: const InputDecoration(labelText: 'Destination (e.g. Paris & Rome)'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCurrency,
                      decoration: const InputDecoration(labelText: 'Local Currency'),
                      items: CurrencyService.supportedCurrencies.keys.map((c) {
                        return DropdownMenuItem(value: c, child: Text(c));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setDlgState(() => selectedCurrency = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: budgetCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Total Trip Budget'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: dailyCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Daily Allowance Target'),
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
                    final b = double.tryParse(budgetCtrl.text) ?? 1000.0;
                    final d = double.tryParse(dailyCtrl.text) ?? (b / 7);

                    ref.read(travelModeProvider.notifier).addTrip(
                          name: nameCtrl.text.isEmpty ? 'Vacation Trip' : nameCtrl.text,
                          destination: destCtrl.text.isEmpty ? 'Travel Destination' : destCtrl.text,
                          currencyCode: selectedCurrency,
                          totalBudgetMinor: (b * 100).toInt(),
                          dailyAllowanceMinor: (d * 100).toInt(),
                          startDate: DateTime.now(),
                          endDate: DateTime.now().add(const Duration(days: 7)),
                        );
                    Navigator.pop(ctx);
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddTripExpenseDialog(BuildContext context, Trip trip) {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Add Expense to ${trip.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Expense Title (e.g. Hotel / Museum)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount in ${trip.currencyCode}',
                  prefixText: '${CurrencyService.instance.getCurrency(trip.currencyCode).symbol} ',
                ),
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
                  ref.read(travelModeProvider.notifier).addTripExpense(
                        tripId: trip.id,
                        title: titleCtrl.text,
                        amountMinor: (amt * 100).toInt(),
                        categoryName: 'Travel',
                      );
                }
                Navigator.pop(ctx);
              },
              child: const Text('Save Expense'),
            ),
          ],
        );
      },
    );
  }

  void _showCurrencyConverterDialog(BuildContext context) {
    String from = 'USD';
    String to = 'JPY';
    final amountCtrl = TextEditingController(text: '100');
    double converted = 0.0;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            final amt = double.tryParse(amountCtrl.text) ?? 0.0;
            converted = CurrencyService.instance.convert(
              amount: amt,
              fromCurrency: from,
              toCurrency: to,
            );

            return AlertDialog(
              title: const Text('Live Currency Converter 💱'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Source Amount'),
                    onChanged: (_) => setDlgState(() {}),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: from,
                          decoration: const InputDecoration(labelText: 'From'),
                          items: CurrencyService.supportedCurrencies.keys.map((c) {
                            return DropdownMenuItem(value: c, child: Text(c));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setDlgState(() => from = val);
                          },
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.arrow_forward),
                      ),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: to,
                          decoration: const InputDecoration(labelText: 'To'),
                          items: CurrencyService.supportedCurrencies.keys.map((c) {
                            return DropdownMenuItem(value: c, child: Text(c));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setDlgState(() => to = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Text('Converted Estimate', style: TextStyle(fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                          '${CurrencyService.instance.getCurrency(to).symbol}${converted.toStringAsFixed(2)} $to',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
