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
  final int lowStockCount; // New field for summary
  final String? selectedCategoryId;
  final bool isProductView;
  final bool isLowStockView; // New flag
  final bool isSearching;

  const InventoryLoaded(
    this.products, {
    this.categories = const [],
    this.hasReachedMax = false,
    this.isLoadingMore = false,
    this.totalProductCount = 0,
    this.globalProductCount = 0,
    this.lowStockCount = 0,
    this.selectedCategoryId,
    this.isProductView = false,
    this.isLowStockView = false,
    this.isSearching = false,
  });

  InventoryLoaded copyWith({
    List<ProductModel>? products,
    List<CategoryModel>? categories,
    bool? hasReachedMax,
    bool? isLoadingMore,
    int? totalProductCount,
    int? globalProductCount,
    int? lowStockCount,
    String? selectedCategoryId,
    bool? isProductView,
    bool? isLowStockView,
    bool? isSearching,
  }) {
    return InventoryLoaded(
      products ?? this.products,
      categories: categories ?? this.categories,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      totalProductCount: totalProductCount ?? this.totalProductCount,
      globalProductCount: globalProductCount ?? this.globalProductCount,
      lowStockCount: lowStockCount ?? this.lowStockCount,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      isProductView: isProductView ?? this.isProductView,
      isLowStockView: isLowStockView ?? this.isLowStockView,
      isSearching: isSearching ?? this.isSearching,
    );
  }

  @override
  List<Object?> get props => [
    products,
    categories,
    hasReachedMax,
    isLoadingMore,
    totalProductCount,
    globalProductCount,
    lowStockCount,
    isLowStockView,
    selectedCategoryId,
    isProductView,
    isSearching,
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
