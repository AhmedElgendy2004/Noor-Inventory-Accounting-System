class PricingTierModel {
  final String? id;
  final String productId;
  final int minQuantity;
  final double totalPrice;
  final String? tierName;

  PricingTierModel({
    this.id,
    required this.productId,
    required this.minQuantity,
    required this.totalPrice,
    this.tierName,
  });

  factory PricingTierModel.fromJson(Map<String, dynamic> json) {
    return PricingTierModel(
      id: json['id'] as String?,
      productId: json['product_id'] as String,
      minQuantity: json['min_quantity'] as int,
      totalPrice: (json['total_price'] as num).toDouble(),
      tierName: json['tier_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'product_id': productId,
      'min_quantity': minQuantity,
      'total_price': totalPrice,
      'tier_name': tierName,
    };
  }
}
