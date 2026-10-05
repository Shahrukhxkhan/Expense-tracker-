
class CurrencyInfo {
  final String code;
  final String symbol;
  final String name;
  final double rateToUsd; // cached conversion rate against base USD

  const CurrencyInfo({
    required this.code,
    required this.symbol,
    required this.name,
    this.rateToUsd = 1.0,
  });
}

class CurrencyService {
  CurrencyService._();
  static final CurrencyService instance = CurrencyService._();

  static const Map<String, CurrencyInfo> supportedCurrencies = {
    'USD': CurrencyInfo(code: 'USD', symbol: '\$', name: 'US Dollar', rateToUsd: 1.0),
    'EUR': CurrencyInfo(code: 'EUR', symbol: '€', name: 'Euro', rateToUsd: 0.92),
    'GBP': CurrencyInfo(code: 'GBP', symbol: '£', name: 'British Pound', rateToUsd: 0.78),
    'JPY': CurrencyInfo(code: 'JPY', symbol: '¥', name: 'Japanese Yen', rateToUsd: 154.5),
    'CAD': CurrencyInfo(code: 'CAD', symbol: 'CA\$', name: 'Canadian Dollar', rateToUsd: 1.36),
    'AUD': CurrencyInfo(code: 'AUD', symbol: 'A\$', name: 'Australian Dollar', rateToUsd: 1.52),
    'PKR': CurrencyInfo(code: 'PKR', symbol: 'Rs', name: 'Pakistani Rupee', rateToUsd: 278.0),
    'INR': CurrencyInfo(code: 'INR', symbol: '₹', name: 'Indian Rupee', rateToUsd: 83.5),
    'AED': CurrencyInfo(code: 'AED', symbol: 'AED', name: 'UAE Dirham', rateToUsd: 3.67),
  };

  /// Convert amount between any two currencies using cached rates
  double convert({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
  }) {
    if (fromCurrency == toCurrency) return amount;
    final fromRate = supportedCurrencies[fromCurrency]?.rateToUsd ?? 1.0;
    final toRate = supportedCurrencies[toCurrency]?.rateToUsd ?? 1.0;

    // Convert from source to USD then USD to target
    final inUsd = amount / fromRate;
    return inUsd * toRate;
  }

  CurrencyInfo getCurrency(String code) {
    return supportedCurrencies[code] ??
        CurrencyInfo(code: code, symbol: code, name: code);
  }
}
