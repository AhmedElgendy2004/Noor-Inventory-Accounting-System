import 'package:equatable/equatable.dart';
import '../../../data/models/product_model.dart';

abstract class InventoryState extends Equatable {
  const InventoryState();

  @override
  List<Object?> get props => [];
}

class InventoryInitial extends InventoryState {}

class InventoryLoading extends InventoryState {}

class InventoryLoaded extends InventoryState {
  final List<ProductModel> products;
  final bool hasReachedMax;
  final int totalProductCount;

  const InventoryLoaded(
    this.products, {
    this.hasReachedMax = false,
    this.totalProductCount = 0,
  });

  InventoryLoaded copyWith({
    List<ProductModel>? products,
    bool? hasReachedMax,
    int? totalProductCount,
  }) {
    return InventoryLoaded(
      products ?? this.products,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      totalProductCount: totalProductCount ?? this.totalProductCount,
    );
  }

  @override
  List<Object?> get props => [products, hasReachedMax, totalProductCount];
}

class InventorySuccess extends InventoryState {
  final String message;

  const InventorySuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class InventoryError extends InventoryState {
  final String message;

  const InventoryError(this.message);

  @override
  List<Object?> get props => [message];
}
