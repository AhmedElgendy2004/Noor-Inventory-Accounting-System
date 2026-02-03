import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/product_model.dart';
import '../../../data/services/product_service.dart';
import 'inventory_state.dart';

class InventoryCubit extends Cubit<InventoryState> {
  final ProductService _productService;

  InventoryCubit(this._productService) : super(InventoryInitial());

  static const int _pageSize = 20;

  Future<void> loadInventory({String? query, bool loadMore = false}) async {
    if (loadMore) {
      if (state is InventoryLoaded) {
        final currentState = state as InventoryLoaded;
        if (currentState.hasReachedMax) return;

        try {
          // Pagination Logic for Load More
          // Don't emit Loading here to avoid rebuilding the whole list,
          // we rely on the list view showing a spinner at bottom.
          // Or we can emit the same state but maybe with a 'loadingMore' flag if needed.
          // For now, we just fetch and emit the new list.

          final offset = currentState.products.length;
          final newProducts = await _productService.getProducts(
            limit: _pageSize,
            offset: offset,
          );

          emit(
            currentState.copyWith(
              products: List.of(currentState.products)..addAll(newProducts),
              hasReachedMax: newProducts.length < _pageSize,
            ),
          );
        } catch (e) {
          // Optional: emit error or snackbar, but maybe don't replace the whole list with error screen
          // For simplicity, we keep current state or could emit a dedicated minor error event
        }
      }
      return;
    }

    // Initial Load or Search
    emit(InventoryLoading());
    try {
      if (query != null && query.isNotEmpty) {
        // Search Mode: Ignore pagination, fetch all relevant
        final products = await _productService.getProducts(searchQuery: query);
        emit(
          InventoryLoaded(
            products,
            hasReachedMax:
                true, // No more to load for search results in this simplistic approach
            totalProductCount:
                products.length, // Or 0 if we only want total DB count
          ),
        );
      } else {
        // Normal Mode: Fetch first page + Total Count
        // Run in parallel for performance
        final results = await Future.wait([
          _productService.getProducts(limit: _pageSize, offset: 0),
          _productService.getTotalProductsCount(),
        ]);

        final products = results[0] as List<ProductModel>;
        final totalCount = results[1] as int;

        emit(
          InventoryLoaded(
            products,
            hasReachedMax: products.length < _pageSize,
            totalProductCount: totalCount,
          ),
        );
      }
    } catch (e) {
      emit(InventoryError(e.toString()));
    }
  }

  Future<void> addProduct(ProductModel product) async {
    emit(InventoryLoading());
    try {
      await _productService.addProduct(product);
      emit(const InventorySuccess('تم إضافة المنتج بنجاح'));
      // Reload inventory after success if needed, or let UI handle it
    } catch (e) {
      emit(InventoryError(e.toString()));
    }
  }

  Future<void> updateProduct(ProductModel product) async {
    emit(InventoryLoading());
    try {
      await _productService.updateProduct(product);
      emit(const InventorySuccess('تم تحديث المنتج بنجاح'));
    } catch (e) {
      emit(InventoryError(e.toString()));
    }
  }

  Future<void> deleteProduct(String id) async {
    // Note: We might want to keep the current list visible while deleting,
    // but for simplicity we will verify deletion by reloading.
    // Or we could emit Loading -> Success -> Reload.
    // Given the prompt: "Call _productService.deleteProduct(id). Then call loadInventory() to refresh."
    try {
      await _productService.deleteProduct(id);
      await loadInventory();
    } catch (e) {
      emit(InventoryError(e.toString()));
    }
  }
}
