import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/category_model.dart';
import '../../../data/services/product_service.dart';
import 'inventory_state.dart';

class InventoryCubit extends Cubit<InventoryState> {
  final ProductService _productService;
  final SupabaseClient _supabase = Supabase.instance.client;

  InventoryCubit(this._productService) : super(InventoryInitial());

  static const int _pageSize = 10;
  List<CategoryModel> _cachedCategories = [];

  // تحميل التصنيفات والعدد الإجمالي عند الدخول (للشاشة الرئيسية)
  Future<void> loadInitialData() async {
    emit(InventoryLoading());
    try {
      await loadCategories();
      final totalCount = await _productService.getTotalProductsCount();

      emit(
        InventoryLoaded(
          const [], // لا نحتاج منتجات في شبكة التصنيفات
          categories: List.of(_cachedCategories),
          totalProductCount: totalCount,
          isProductView: false,
        ),
      );
    } catch (e) {
      emit(InventoryError(e.toString()));
    }
  }

  Future<void> loadCategories() async {
    try {
      final response = await _supabase
          .from('categories')
          .select()
          .order('name', ascending: true);

      final data = response as List<dynamic>;
      _cachedCategories = data.map((e) => CategoryModel.fromJson(e)).toList();

      if (state is InventoryLoaded) {
        emit(
          (state as InventoryLoaded).copyWith(
            categories: List.of(_cachedCategories),
          ),
        );
      }
    } catch (e) {
      print('Error loading categories: $e');
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
          // يمكن إصدار حالة خطأ خفيفة أو تجاهلها
        }
        return;
      }
    }

    // 2. تحميل جديد (أول صفحة)
    emit(InventoryLoading());
    try {
      // نحافظ على العدد الإجمالي إذا كان موجوداً، أو نحدثه عند عدم البحث
      int totalCount = 0;
      if (state is InventoryLoaded) {
        totalCount = (state as InventoryLoaded).totalProductCount;
      }
      if (totalCount == 0 && (query == null || query.isEmpty)) {
        totalCount = await _productService.getTotalProductsCount();
      }

      final products = await _productService.getProducts(
        searchQuery: query,
        categoryId: categoryId,
        limit: _pageSize,
        offset: 0,
      );

      emit(
        InventoryLoaded(
          products,
          categories: List.of(_cachedCategories),
          hasReachedMax: products.length < _pageSize,
          totalProductCount: totalCount,
          selectedCategoryId: categoryId,
          isProductView: true, // الانتقال لعرض القائمة
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
      final response = await _supabase
          .from('categories')
          .insert({'name': name, 'color': color})
          .select()
          .single();

      final newCategory = CategoryModel.fromJson(response);
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
      // 1. فك ارتباط المنتجات بهذا التصنيف (جعل category_id = null)
      await _supabase
          .from('products')
          .update({'category_id': null})
          .eq('category_id', categoryId);

      // 2. حذف التصنيف
      await _supabase.from('categories').delete().eq('id', categoryId);

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
      emit(const InventorySuccess('تم إضافة المنتج بنجاح'));
      // العودة للحالة الطبيعية مع وجود التصنيفات
      emit(
        InventoryLoaded(
          const [],
          categories: List.of(_cachedCategories),
          isProductView: false, // العودة للشبكة
        ),
      );
    } catch (e) {
      emit(InventoryError(e.toString()));
    }
  }

  Future<void> updateProduct(ProductModel product) async {
    emit(InventoryLoading());
    try {
      await _productService.updateProduct(product);
      emit(const InventorySuccess('تم تحديث المنتج بنجاح'));
      // يمكن إعادة تحميل القائمة الحالية إذا كنا في وضع العرض
    } catch (e) {
      emit(InventoryError(e.toString()));
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _productService.deleteProduct(id);
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
}
