import 'package:equatable/equatable.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/category_model.dart';

abstract class InventoryState extends Equatable {
  const InventoryState();

  @override
  List<Object?> get props => [];
}

class InventoryInitial extends InventoryState {}

class InventoryLoading extends InventoryState {}

class InventoryLoaded extends InventoryState {
  final List<ProductModel> products;
  final List<CategoryModel> categories;
  final bool hasReachedMax;
  final int totalProductCount;
  final String? selectedCategoryId; // null means "All" if in product view
  final bool
  isProductView; // true if showing product list, false if showing category grid

  const InventoryLoaded(
    this.products, {
    this.categories = const [],
    this.hasReachedMax = false,
    this.totalProductCount = 0,
    this.selectedCategoryId,
    this.isProductView = false,
  });

  InventoryLoaded copyWith({
    List<ProductModel>? products,
    List<CategoryModel>? categories,
    bool? hasReachedMax,
    int? totalProductCount,
    String? selectedCategoryId,
    bool? isProductView,
  }) {
    return InventoryLoaded(
      products ?? this.products,
      categories: categories ?? this.categories,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      totalProductCount: totalProductCount ?? this.totalProductCount,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      isProductView: isProductView ?? this.isProductView,
    );
  }

  @override
  List<Object?> get props => [
    products,
    categories,
    hasReachedMax,
    totalProductCount,
    selectedCategoryId,
    isProductView,
  ];
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
