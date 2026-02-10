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
  final bool isLoadingMore; // Indicator for pagination loading
  final int totalProductCount;
  final int globalProductCount;
  final String? selectedCategoryId;
  final bool
  isProductView; // Can be kept for legacy or view switching if needed

  const InventoryLoaded(
    this.products, {
    this.categories = const [],
    this.hasReachedMax = false,
    this.isLoadingMore = false,
    this.totalProductCount = 0,
    this.globalProductCount = 0,
    this.selectedCategoryId,
    this.isProductView = false,
  });

  InventoryLoaded copyWith({
    List<ProductModel>? products,
    List<CategoryModel>? categories,
    bool? hasReachedMax,
    bool? isLoadingMore,
    int? totalProductCount,
    int? globalProductCount,
    String? selectedCategoryId,
    bool? isProductView,
  }) {
    return InventoryLoaded(
      products ?? this.products,
      categories: categories ?? this.categories,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      totalProductCount: totalProductCount ?? this.totalProductCount,
      globalProductCount: globalProductCount ?? this.globalProductCount,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      isProductView: isProductView ?? this.isProductView,
    );
  }

  @override
  List<Object?> get props => [
    products,
    categories,
    hasReachedMax,
    isLoadingMore,
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
