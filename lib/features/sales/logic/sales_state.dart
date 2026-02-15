import 'package:equatable/equatable.dart';
import '../../../data/models/cart_item_model.dart';
import '../../../data/models/customer_model.dart';

abstract class SalesState extends Equatable {
  const SalesState();

  @override
  List<Object?> get props => [];
}

class SalesInitial extends SalesState {}

class SalesLoading extends SalesState {}

class SalesUpdated extends SalesState {
  final List<CartItemModel> cartItems;
  final double totalAmount;
  final bool isWholesale;
  final String paymentType; // 'cash' or 'credit'
  final CustomerModel? selectedCustomer;

  const SalesUpdated({
    required this.cartItems,
    required this.totalAmount,
    this.isWholesale = false,
    this.paymentType = 'cash',
    this.selectedCustomer,
  });

  SalesUpdated copyWith({
    List<CartItemModel>? cartItems,
    bool? isWholesale,
    String? paymentType,
    CustomerModel? selectedCustomer,
  }) {
    // Recalculate total whenever items change
    final items = cartItems ?? this.cartItems;
    final total = items.fold(0.0, (sum, item) => sum + item.total);

    return SalesUpdated(
      cartItems: items,
      totalAmount: double.parse(total.toStringAsFixed(2)),
      isWholesale: isWholesale ?? this.isWholesale,
      paymentType: paymentType ?? this.paymentType,
      selectedCustomer:
          selectedCustomer ??
          this.selectedCustomer, // Allow null override logic in cubit if needed, but here simple copy
    );
  }

  @override
  List<Object?> get props => [
    cartItems,
    totalAmount,
    isWholesale,
    paymentType,
    selectedCustomer,
  ];
}

class SalesSuccess extends SalesState {
  final String invoiceId;

  const SalesSuccess(this.invoiceId);

  @override
  List<Object?> get props => [invoiceId];
}

class SalesError extends SalesState {
  final String message;

  const SalesError(this.message);

  @override
  List<Object?> get props => [message];
}
