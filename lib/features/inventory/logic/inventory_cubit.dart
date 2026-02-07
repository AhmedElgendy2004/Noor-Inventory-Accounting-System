import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/category_model.dart';
import '../../../data/services/product_service.dart';
import 'inventory_state.dart';

class InventoryCubit extends Cubit<InventoryState> {
  final ProductService _productService;

  InventoryCubit(this._productService) : super(InventoryInitial());

  static const int _pageSize = 10;
  List<CategoryModel> _cachedCategories = [];
  int _cachedGlobalCount = 0; // تخزين العدد الإجمالي

  // تحميل التصنيفات والعدد الإجمالي عند الدخول (للشاشة الرئيسية)
  Future<void> loadInitialData() async {
    emit(InventoryLoading());
    try {
      await loadCategories();
      final totalCount = await _productService.getTotalProductsCount();
      _cachedGlobalCount = totalCount; // تحديث الكاش

      emit(
        InventoryLoaded(
          const [], // لا نحتاج منتجات في شبكة التصنيفات
          categories: List.of(_cachedCategories),
          totalProductCount: totalCount,
          globalProductCount: _cachedGlobalCount,
          isProductView: false,
        ),
      );
    } catch (e) {
      emit(InventoryError(e.toString()));
    }
  }

  Future<void> loadCategories() async {
    try {
      _cachedCategories = await _productService.getCategories();

      if (state is InventoryLoaded) {
        emit(
          (state as InventoryLoaded).copyWith(
            categories: List.of(_cachedCategories),
          ),
        );
      }
    } catch (e) {
      // Must rethrow to allow caller (loadInitialData) to handle the error state
      rethrow;
    }
  }

  // الدالة الأساسية لجلب المنتجات (تدعم التصنيف، البحث، والتحميل الإضافي)
  Future<void> fetchProducts({
    String? categoryId,
    String? query,
    bool isLoadMore = false,
  }) async {
    // التأكد من وجود Categories (احتياط)
    if (_cachedCategories.isEmpty) await loadCategories();

    // التعامل مع الحالة الحالية
    if (state is InventoryLoaded) {
      final currentState = state as InventoryLoaded;

      // 1. التحميل الإضافي (Pagination)
      if (isLoadMore) {
        if (currentState.hasReachedMax) return;

        try {
          final offset = currentState.products.length;
          final newProducts = await _productService.getProducts(
            searchQuery: query,
            categoryId: categoryId,
            limit: _pageSize,
            offset: offset,
          );

          // منع التكرار
          final allProducts = List.of(currentState.products)
            ..addAll(newProducts);
          // (اختياري) يمكن إضافة منطق لإزالة التكرار بواسطة ID إذا كانت قاعدة البيانات غير مستقرة في الترتيب

          emit(
            currentState.copyWith(
              products: allProducts,
              hasReachedMax: newProducts.length < _pageSize,
            ),
          );
        } catch (e) {
          // Error in pagination can remain ignored or shown as a snackbar separately
          // But main thread shouldn't crash
        }
        return;
      }
    }

    // 2. تحميل جديد (أول صفحة)
    emit(InventoryLoading());
    try {
      // جلب العدد المتوافق مع الفلتر الحالي (يدعم البحث والتصنيف)
      final totalCount = await _productService.getTotalProductsCount(
        categoryId: categoryId,
        searchQuery: query,
      );

      final products = await _productService.getProducts(
        searchQuery: query,
        categoryId: categoryId,
        limit: _pageSize,
        offset: 0,
      );

      // Maintain global count from cache
      int globalCount = _cachedGlobalCount;

      emit(
        InventoryLoaded(
          products,
          categories: List.of(_cachedCategories),
          hasReachedMax: products.length < _pageSize,
          totalProductCount: totalCount, // Filtered count
          globalProductCount: globalCount, // Keep dashboard count
          selectedCategoryId: categoryId,
          isProductView: true,
        ),
      );
    } catch (e) {
      emit(InventoryError(e.toString()));
    }
  }

  void backToCategories() {
    if (state is InventoryLoaded) {
      final currentState = state as InventoryLoaded;
      emit(
        currentState.copyWith(
          isProductView: false,
          selectedCategoryId: null,
          products: [], // تفريغ المنتجات لتوفير الذاكرة
          hasReachedMax: false,
        ),
      );
    } else {
      // Fallback
      loadInitialData();
    }
  }

  Future<void> addNewCategory(String name, int color) async {
    try {
      final newCategory = await _productService.addCategory(name, color);

      _cachedCategories.add(newCategory);
      // Sort
      _cachedCategories.sort((a, b) => a.name.compareTo(b.name));

      if (state is InventoryLoaded) {
        emit(
          (state as InventoryLoaded).copyWith(
            categories: List.of(_cachedCategories),
          ),
        );
      } else {
        emit(InventoryLoaded([], categories: List.of(_cachedCategories)));
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    try {
      await _productService.deleteCategory(categoryId);

      // 3. تحديث القائمة المحلية
      _cachedCategories.removeWhere((c) => c.id == categoryId);

      if (state is InventoryLoaded) {
        emit(
          (state as InventoryLoaded).copyWith(
            categories: List.of(_cachedCategories),
          ),
        );
      }
    } catch (e) {
      emit(InventoryError('فشل حذف التصنيف: $e'));
      // إعادة تحميل البيانات لضمان التزامن
      loadInitialData();
    }
  }

  Future<void> addProduct(ProductModel product) async {
    emit(InventoryLoading());
    try {
      await _productService.addProduct(product);
      _cachedGlobalCount++; // زيادة العدد

      emit(const InventorySuccess('تم إضافة المنتج بنجاح'));
      // العودة للحالة الطبيعية مع وجود التصنيفات
      emit(
        InventoryLoaded(
          const [],
          categories: List.of(_cachedCategories),
          isProductView: false, // العودة للشبكة
          globalProductCount: _cachedGlobalCount,
          totalProductCount: _cachedGlobalCount,
        ),
      );
    } catch (e) {
      emit(InventoryError(e.toString()));
    }
  }

  Future<void> updateProduct(ProductModel product) async {
    // Capture current context before loading/success states
    String? currentCategoryId;
    if (state is InventoryLoaded) {
      currentCategoryId = (state as InventoryLoaded).selectedCategoryId;
    }

    emit(InventoryLoading());
    try {
      await _productService.updateProduct(product);
      emit(const InventorySuccess('تم تحديث المنتج بنجاح'));

      // Reload the list to show updated data
      await fetchProducts(categoryId: currentCategoryId);
    } catch (e) {
      emit(InventoryError(e.toString()));
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _productService.deleteProduct(id);
      _cachedGlobalCount--; // نقص العدد

      // Refresh current view logic
      if (state is InventoryLoaded) {
        final currentState = state as InventoryLoaded;
        // Refresh list
        await fetchProducts(
          categoryId: currentState.selectedCategoryId,
          // We can't easily preserve query here without storing it in state,
          // but for simplicity we reload current category or all.
          query: null,
        );
      }
    } catch (e) {
      emit(InventoryError(e.toString()));
    }
  }

  /// ⚠️ دالة مؤقتة لتوليد بيانات اختبارية (نسخة محسنة)
  Future<void> generateMockProducts() async {
    if (_cachedCategories.isEmpty) {
      emit(const InventoryError("يجب إضافة تصنيفات أولاً لتوليد المنتجات!"));
      return;
    }

    emit(InventoryLoading());
    try {
      final random = Random();
      final List<ProductModel> mockProducts = [];

      // توليد 100 منتج
      for (int i = 0; i < 100; i++) {
        final category =
            _cachedCategories[random.nextInt(_cachedCategories.length)];
        final purchasePrice = 10 + random.nextInt(90); // 10 to 100
        final retailPrice =
            purchasePrice + 10 + random.nextInt(50); // purchase + 10 to 60

        mockProducts.add(
          ProductModel(
            name: 'منتج تجريبي ${random.nextInt(10000)}',
            barcode: 'MOCK-${DateTime.now().millisecondsSinceEpoch}-$i',
            categoryId: category.id,
            brandCompany: 'شركة تجريبية',
            purchasePrice: purchasePrice.toDouble(),
            retailPrice: retailPrice.toDouble(),
            wholesalePrice: (purchasePrice + 5).toDouble(),
            stockQuantity: 1 + random.nextInt(100),
            minStockLevel: 5,
          ),
        );
      }

      // إرسال دفعة واحدة (أسرع بكثير)
      await _productService.addProducts(mockProducts);

      // تحديث البيانات وعرضها
      await loadInitialData();
    } catch (e) {
      emit(InventoryError('فشل توليد البيانات: $e'));
      // محاولة العودة للوضع الطبيعي في حال الفشل
      loadInitialData();
    }
  }
}
