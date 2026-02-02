import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/product_model.dart';
import '../../../data/services/product_service.dart';
import 'inventory_state.dart';

class InventoryCubit extends Cubit<InventoryState> {
  final ProductService _productService;

  InventoryCubit(this._productService) : super(InventoryInitial());

  Future<void> loadInventory({String? query}) async {
    emit(InventoryLoading());
    try {
      final products = await _productService.getProducts(searchQuery: query);
      emit(InventoryLoaded(products));
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
