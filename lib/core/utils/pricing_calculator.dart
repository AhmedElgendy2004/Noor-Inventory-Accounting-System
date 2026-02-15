import '../../data/models/product_model.dart';

class PricingCalculator {
  /// Calculates the best price for a given quantity using a Greedy Algorithm.
  /// Returns the total calculated cost, the effective unit price, and a text breakdown.
  static ({double totalPrice, double averageUnitPrice, String breakdown})
  calculateBestPrice({
    required ProductModel product,
    required int quantity,
    required bool isWholesale,
  }) {
    if (quantity <= 0) {
      return (totalPrice: 0.0, averageUnitPrice: 0.0, breakdown: '');
    }

    // Base unit price (Retail or Wholesale)
    final double baseUnitPrice = isWholesale
        ? product.wholesalePrice
        : product.retailPrice;

    // Filter and Sort tiers: Largest quantity first (Greedy Strategy)
    final tiers =
        (product.pricingTiers ?? []).where((t) => t.minQuantity > 0).toList()
          ..sort((a, b) => b.minQuantity.compareTo(a.minQuantity));

    int distinctRemaining = quantity;
    double currentTotal = 0.0;
    List<String> steps = [];

    // 1. Iterate through tiers
    for (var tier in tiers) {
      if (distinctRemaining < tier.minQuantity) continue;

      int numberOfPacks =
          distinctRemaining ~/ tier.minQuantity; // Integer division

      if (numberOfPacks > 0) {
        double costForThesePacks = numberOfPacks * tier.totalPrice;
        currentTotal += costForThesePacks;

        int quantityCovered = numberOfPacks * tier.minQuantity;
        distinctRemaining -= quantityCovered;

        String name = tier.tierName != null && tier.tierName!.isNotEmpty
            ? tier.tierName!
            : 'عرض ${tier.minQuantity}';

        steps.add('$numberOfPacks x $name');
      }
    }

    // 2. Handle Remainder (Individual items)
    if (distinctRemaining > 0) {
      double costForRemainder = distinctRemaining * baseUnitPrice;
      currentTotal += costForRemainder;
      steps.add('$distinctRemaining x قطعة ($baseUnitPrice)');
    }

    return (
      totalPrice: currentTotal.roundToDouble(),
      averageUnitPrice: double.parse(
        (currentTotal / quantity).toStringAsFixed(2),
      ),
      breakdown: steps.join(' + '),
    );
  }
}
