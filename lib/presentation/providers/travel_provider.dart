import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/services/currency_service.dart';
import '../../data/models/trip_model.dart';

class TravelModeNotifier extends StateNotifier<List<TripSummary>> {
  TravelModeNotifier() : super([]) {
    _initDemoTrips();
  }

  void _initDemoTrips() {
    final now = DateTime.now();
    final demoTrip = Trip(
      id: const Uuid().v4(),
      name: 'Japan Adventure 2026 🌸',
      destination: 'Tokyo & Kyoto, Japan',
      currencyCode: 'JPY',
      totalBudgetMinor: 30000000, // 300,000 JPY
      dailyAllowanceMinor: 2500000, // 25,000 JPY/day
      startDate: now.subtract(const Duration(days: 2)),
      endDate: now.add(const Duration(days: 8)),
      isActive: true,
      createdAt: now.subtract(const Duration(days: 5)),
    );

    final demoExpenses = [
      TripExpenseItem(
        id: const Uuid().v4(),
        tripId: demoTrip.id,
        title: 'Shinkansen Bullet Train Ticket',
        amountMinor: 1400000, // 14,000 JPY
        categoryName: 'Transport',
        date: now.subtract(const Duration(days: 1)),
      ),
      TripExpenseItem(
        id: const Uuid().v4(),
        tripId: demoTrip.id,
        title: 'Authentic Ramen Dinner',
        amountMinor: 180000, // 1,800 JPY
        categoryName: 'Food & Dining',
        date: now,
      ),
      TripExpenseItem(
        id: const Uuid().v4(),
        tripId: demoTrip.id,
        title: 'Ghibli Museum Souvenirs',
        amountMinor: 450000, // 4,500 JPY
        categoryName: 'Shopping',
        date: now,
      ),
    ];

    state = [_calculateSummary(demoTrip, demoExpenses)];
  }

  TripSummary _calculateSummary(Trip trip, List<TripExpenseItem> expenses) {
    int totalSpent = 0;
    int todaySpent = 0;
    final now = DateTime.now();

    for (final exp in expenses) {
      totalSpent += exp.amountMinor;
      if (exp.date.year == now.year &&
          exp.date.month == now.month &&
          exp.date.day == now.day) {
        todaySpent += exp.amountMinor;
      }
    }

    final remaining = trip.totalBudgetMinor - totalSpent;
    final usage = trip.totalBudgetMinor > 0
        ? (totalSpent / trip.totalBudgetMinor).clamp(0.0, 1.0)
        : 0.0;

    return TripSummary(
      trip: trip,
      totalSpentMinor: totalSpent,
      remainingBudgetMinor: remaining,
      todaySpentMinor: todaySpent,
      budgetUsagePercentage: usage,
      expenses: expenses,
    );
  }

  void addTrip({
    required String name,
    required String destination,
    required String currencyCode,
    required int totalBudgetMinor,
    required int dailyAllowanceMinor,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final trip = Trip(
      id: const Uuid().v4(),
      name: name,
      destination: destination,
      currencyCode: currencyCode,
      totalBudgetMinor: totalBudgetMinor,
      dailyAllowanceMinor: dailyAllowanceMinor,
      startDate: startDate,
      endDate: endDate,
      isActive: true,
      createdAt: DateTime.now(),
    );

    final summary = _calculateSummary(trip, []);
    state = [summary, ...state];
  }

  void addTripExpense({
    required String tripId,
    required String title,
    required int amountMinor,
    required String categoryName,
  }) {
    final updated = <TripSummary>[];
    for (final s in state) {
      if (s.trip.id == tripId) {
        final newExpense = TripExpenseItem(
          id: const Uuid().v4(),
          tripId: tripId,
          title: title,
          amountMinor: amountMinor,
          categoryName: categoryName,
          date: DateTime.now(),
        );
        final newExpenses = [newExpense, ...s.expenses];
        updated.add(_calculateSummary(s.trip, newExpenses));
      } else {
        updated.add(s);
      }
    }
    state = updated;
  }
}

final travelModeProvider =
    StateNotifierProvider<TravelModeNotifier, List<TripSummary>>(
  (ref) => TravelModeNotifier(),
);

/// Active selected currency provider
final selectedCurrencyProvider = StateProvider<String>((ref) => 'USD');
