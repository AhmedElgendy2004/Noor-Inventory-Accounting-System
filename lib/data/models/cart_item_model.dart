import 'product_model.dart';

class CartItemModel {
  final ProductModel product;
  final int quantity;

  // السعر لحظة البيع
  final double priceAtSale;

  // نوع السعر (retail / wholesale)
  final String priceType;

  CartItemModel({
    required this.product,
    required this.quantity,
    required this.priceAtSale,
    required this.priceType,
  });

  // حساب الإجمالي للصنف الواحد
  double get total => double.parse((priceAtSale * quantity).toStringAsFixed(2));

  // تحويل لـ JSON مطابق لجدول sale_items
  Map<String, dynamic> toJson() {
    return {
      'product_id': product.id,
      'quantity': quantity,
      'price_at_sale': priceAtSale,
      'price_type': priceType,
    };
  }

  CartItemModel copyWith({
    ProductModel? product,
    int? quantity,
    double? priceAtSale,
    String? priceType,
  }) {
    return CartItemModel(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      priceAtSale: priceAtSale ?? this.priceAtSale,
      priceType: priceType ?? this.priceType,
    );
  }
}
