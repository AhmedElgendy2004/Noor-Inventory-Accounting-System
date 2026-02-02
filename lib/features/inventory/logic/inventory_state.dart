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

  const InventoryLoaded(this.products);

  @override
  List<Object?> get props => [products];
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
