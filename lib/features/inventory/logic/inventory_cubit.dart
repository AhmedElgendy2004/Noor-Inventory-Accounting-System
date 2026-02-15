import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/category_model.dart';
import '../../../data/services/product_service.dart';
import 'inventory_state.dart';

class InventoryCubit extends Cubit<InventoryState> {
  final ProductService _productService;

  InventoryCubit(this._productService) : super(InventoryInitial());

  static const int _pageSize = 15;
  Timer? _searchTimer;
  List<CategoryModel> _cachedCategories = [];
  int _cachedGlobalCount = 0;

  // Cache for deduplication of products in the main list
  final Set<String> _productIds = {};

  @override
  Future<void> close() {
    _searchTimer?.cancel();
    return super.close();
  }

  /// Loads initial data (Categories + First Page of Products)
  /// Uses "Silent Refresh" if data already exists in memory.
  Future<void> loadInitialData({bool isRefresh = false}) async {
    // 1. Check if we have data to show immediately
    final hasData =
        _cachedCategories.isNotEmpty ||
        (state is InventoryLoaded &&
            (state as InventoryLoaded).products.isNotEmpty);

    // Only emit loading if we have absolutely nothing and it's not a background refresh
    if (!hasData && !isRefresh) {
      emit(InventoryLoading());
    }

    try {
      // 2. Fetch Global Count & Categories
      final results = await Future.wait([
        _productService.getCategories(),
        _productService.getTotalProductsCount(),
        _productService.getProducts(limit: _pageSize, offset: 0),
        // Fetch low stock count
        _productService.getTotalProductsCount(lowStockOnly: true),
      ]);

      final categories = results[0] as List<CategoryModel>;
      final globalCount = results[1] as int;
      final recentProducts = results[2] as List<ProductModel>;
      final lowStockCount = results[3] as int;

      // Update local caches
      _cachedCategories = categories;
      _cachedGlobalCount = globalCount;

      // ... existing deduplication logic ...

      if (isRefresh || !hasData) {
        _productIds.clear();
      }

      // Deduplication Logic
      final uniqueProducts = <ProductModel>[];
      for (var product in recentProducts) {
        if (product.id != null) {
          _productIds.add(product.id!);
          uniqueProducts.add(product);
        }
      }

      emit(
        InventoryLoaded(
          uniqueProducts,
          categories: _cachedCategories,
          totalProductCount: globalCount,
          globalProductCount: _cachedGlobalCount,
          lowStockCount: lowStockCount, // Added
          hasReachedMax: recentProducts.length < _pageSize,
          isLoadingMore: false,
          isProductView: false,
        ),
      );
    } catch (e) {
      if (state is InventoryLoaded) {
        // If we have data, just show error as snackbar (handled in UI listener)
        // Don't change state to Error to avoid losing UI
        emit(state); // Re-emit current state or custom side-effect if needed
        // Ideally we emit a side effect, but for now we keep state.
        // We could emit InventoryError string in a field, but usually Bloc listener handles 'Error' state.
        // If we emit InventoryError, we lose the data.
        // Strategy: Emit error only if no data.
        if (!hasData) emit(InventoryError(e.toString()));
      } else {
        emit(InventoryError(e.toString()));
      }
    }
  }

  /// Refreshes everything (Categories + Products).
  /// call this when a product is added/edited or category added.
  Future<void> refreshInventory() async {
    await loadInitialData(isRefresh: true);
  }

  /// Fetches products that are low on stock
  Future<void> fetchLowStockProducts() async {
    emit(InventoryLoading());
    try {
      // Forced Refresh: Ignore cache, fetch fresh from DB
      final products = await _productService.getProducts(
        limit: _pageSize,
        offset: 0,
        lowStockOnly: true,
      );

      // Update low stock count as well to be accurate
      final count = await _productService.getTotalProductsCount(
        lowStockOnly: true,
      );

      emit(
        InventoryLoaded(
          products,
          categories: _cachedCategories,
          hasReachedMax: products.length < _pageSize,
          totalProductCount: count,
          globalProductCount: _cachedGlobalCount,
          lowStockCount: count,
          isProductView: true,
          isLowStockView: true,
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
      // If called individually, we might not want to break the whole state
      // But typically this is called within loadInitialData
    }
  }

  // دالة لجلب المزيد من المنتجات (Pagination) للصفحة الرئيسية
  Future<void> loadMoreProducts() async {
    if (state is! InventoryLoaded) return;
    final currentState = state as InventoryLoaded;

    if (currentState.hasReachedMax || currentState.isLoadingMore) return;

    // Show loading spinner at bottom
    emit(currentState.copyWith(isLoadingMore: true));

    try {
      final currentList = currentState.products;
      final offset = currentList.length;

      final newProducts = await _productService.getProducts(
        limit: _pageSize,
        offset: offset,
        lowStockOnly:
            currentState.isLowStockView, // Support pagination for low stock
      );

      // Deduplication
      final uniqueNewProducts = <ProductModel>[];
      for (var product in newProducts) {
        if (product.id != null && !_productIds.contains(product.id)) {
          _productIds.add(product.id!);
          uniqueNewProducts.add(product);
        }
      }

      emit(
        currentState.copyWith(
          products: List.of(currentList)..addAll(uniqueNewProducts),
          hasReachedMax: newProducts.length < _pageSize,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      // Stop loading spinner, keep data
      emit(currentState.copyWith(isLoadingMore: false));
    }
  }

  /// Search with Debounce
  void searchProducts(String query) {
    _searchTimer?.cancel();

    if (query.isEmpty) {
      loadInitialData(); // Return to full list immediately
      return;
    }

    _searchTimer = Timer(const Duration(milliseconds: 500), () {
      fetchProducts(query: query);
    });
  }

  // Note: Old fetchProducts logic is still here for searching/filtering in separate screens
  // But we might need to adapt it if it conflicts.
  // The user asked to update "InventoryCubit logic".
  // I will leave fetchProducts or update it to be compatible if used by ProductListScreen.
  // ProductListScreen uses fetchProducts with categoryId.
  // We need to ensure fetchProducts doesn't conflict with our dashboard state management.
  // Ideally, ProductListScreen should have its own Cubit, but if shared, we handle it carefully.
  // For now, let's keep fetchProducts for ProductListScreen usage,
  // but ensure loadInitialData sets up the DASHBOARD state.

  Future<void> fetchProducts({
    String? categoryId,
    String? query,
    bool isLoadMore = false,
  }) async {
    // Legacy/Search/Filter usage
    // This might override the dashboard state if called.
    // ... implementation similar to before but enabling products list ...
    // For simplicity and safety, I will let the dashboard have its own flow.
    // If ProductListScreen calls this, it will replace the state with filtered products.
    // That is acceptable behavior (Switching from Dashboard View to Product View).

    if (_cachedCategories.isEmpty) await loadCategories();

    if (state is InventoryLoaded) {
      final currentState = state as InventoryLoaded;
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

          final allProducts = List.of(currentState.products)
            ..addAll(newProducts);
          emit(
            currentState.copyWith(
              products: allProducts,
              hasReachedMax: newProducts.length < _pageSize,
            ),
          );
        } catch (e) {
          // 1. نوقف لودنج الـ Pagination عشان الـ Spinner اللي تحت يختفي
          emit(currentState.copyWith(isLoadingMore: false));

          // 2. (اختياري) ممكن تطبع الخطأ في الـ Console للمتابعة أثناء البرمجة
          //  debugPrint('Error loading more products: $e');

          // 3. (احترافي) إرسال إشعار للمستخدم بدون تغيير حالة الشاشة
          // بما إن الكيوبيت ملوش واجهة، بنكتفي بإيقاف اللودنج
          // والـ UI هيفهم إن مفيش بيانات جديدة جت.
        }
        return;
      }
    }

    // Initial fetch for filtered view
    emit(InventoryLoading());
    try {
      final results = await Future.wait([
        _productService.getProducts(
          searchQuery: query,
          categoryId: categoryId,
          limit: _pageSize,
          offset: 0,
        ),
        _productService.getTotalProductsCount(
          categoryId: categoryId,
          searchQuery: query,
        ),
      ]);

      final products = results[0] as List<ProductModel>;
      final totalCount = results[1] as int;

      emit(
        InventoryLoaded(
          products,
          categories: _cachedCategories,
          hasReachedMax: products.length < _pageSize,
          isProductView: true,
          selectedCategoryId: categoryId,
          totalProductCount: totalCount,
          globalProductCount:
              _cachedGlobalCount, // Ensure global count is preserved
          isSearching: query != null && query.isNotEmpty,
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
          products: [], // Consider if we want to clear or keep recent
          hasReachedMax: false,
        ),
      );
      // Reload initial data to refresh logic dashboard
      loadInitialData(); // This will re-fetch everything
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

  Future<void> addProduct(
    ProductModel product, {
    List<Map<String, dynamic>>? pricingTiers,
  }) async {
    emit(InventoryLoading());
    try {
      // 1. إضافة المنتج واستلام النسخة المخزنة التي تحتوي على ID
      final createdProduct = await _productService.addProduct(product);
      _cachedGlobalCount++;

      // 2. إذا كان هناك عروض، نقوم بحفظها
      if (pricingTiers != null &&
          pricingTiers.isNotEmpty &&
          createdProduct.id != null) {
        // إضافة product_id لكل عرض
        final tiersWithId = pricingTiers.map((tier) {
          final Map<String, dynamic> newTier = Map.from(tier);
          newTier['product_id'] = createdProduct.id;
          return newTier;
        }).toList();

        await _productService.addPricingTiers(tiersWithId);
      }

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
      debugPrint('Error adding product: $e');
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
    // التأكد من وجود تصنيفات قبل التوليد
    if (_cachedCategories.isEmpty) {
      try {
        // محاولة تحميل التصنيفات
        final cats = await _productService.getCategories();
        if (cats.isEmpty) {
          // إنشاء تصنيفات افتراضية إذا لم توجد أي تصنيفات
          emit(InventoryLoading()); // إظهار تحميل مؤقت
          await _productService.addCategory('تصنيف عام', Colors.blue.value);
          await _productService.addCategory('ملابس', Colors.red.value);
          await _productService.addCategory('إلكترونيات', Colors.green.value);

          // إعادة تحميل التصنيفات بعد الإضافة
          _cachedCategories = await _productService.getCategories();
        } else {
          _cachedCategories = cats;
        }
      } catch (e) {
        emit(InventoryError("فشل تحميل أو إنشاء التصنيفات: $e"));
        return;
      }
    }

    if (_cachedCategories.isEmpty) {
      emit(const InventoryError("تعذر الحصول على تصنيفات لتوليد البيانات."));
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
            brandCompany: ' شركة تجريبية',
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
