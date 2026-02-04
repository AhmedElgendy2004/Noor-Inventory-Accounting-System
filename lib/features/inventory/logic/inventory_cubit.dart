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

  static const int _pageSize = 20;

  List<CategoryModel> _cachedCategories = [];

  Future<void> loadCategories() async {
    try {
      final response = await _supabase
          .from('categories')
          .select()
          .order('name', ascending: true);

      final data = response as List<dynamic>;
      _cachedCategories = data.map((e) => CategoryModel.fromJson(e)).toList();

      // تجحديث الحالة الحالية إذا كانت Loaded بإضافة التصنيفات
      if (state is InventoryLoaded) {
        emit(
          (state as InventoryLoaded).copyWith(categories: _cachedCategories),
        );
      }
    } catch (e) {
      // يمكن تجاهل الخطأ هنا أو طباعته، حيث أن فشل تحميل التصنيفات لا يوقف استخدام التطبيق
      print('Error loading categories: $e');
    }
  }

  Future<void> addNewCategory(String name) async {
    try {
      final response = await _supabase
          .from('categories')
          .insert({'name': name})
          .select()
          .single();

      final newCategory = CategoryModel.fromJson(response);
      _cachedCategories.add(newCategory);

      // تحديث الواجهة فوراً
      if (state is InventoryLoaded) {
        final currentCategories = List<CategoryModel>.from(
          (state as InventoryLoaded).categories,
        );
        // تأكد من عدم التكرار إذا تم إعادة الجلب
        if (!currentCategories.any((element) => element.id == newCategory.id)) {
          currentCategories.add(newCategory);
          currentCategories.sort((a, b) => a.name.compareTo(b.name));
          emit(
            (state as InventoryLoaded).copyWith(categories: currentCategories),
          );
        }
      } else {
        // إذا لم تكن الحالة Loaded (نادر الحدوث عند الإضافة)
        emit(InventoryLoaded([], categories: _cachedCategories));
      }
    } catch (e) {
      print('Error adding category: $e');
      throw e; // رمي الخطأ لتمكين الواجهة من إظهار رسالة
    }
  }

  Future<void> loadInventory({String? query, bool loadMore = false}) async {
    // تحميل التصنيفات في البداية إذا لم تكن موجودة
    if (_cachedCategories.isEmpty) {
      await loadCategories();
    }

    if (loadMore) {
      if (state is InventoryLoaded) {
        final currentState = state as InventoryLoaded;
        if (currentState.hasReachedMax) return;

        try {
          final offset = currentState.products.length;
          final newProducts = await _productService.getProducts(
            limit: _pageSize,
            offset: offset,
          );

          emit(
            currentState.copyWith(
              products: List.of(currentState.products)..addAll(newProducts),
              // الحفاظ على التصنيفات عند التحميل الإضافي
              categories: _cachedCategories,
              hasReachedMax: newProducts.length < _pageSize,
            ),
          );
        } catch (e) {
          // ignore error
        }
      }
      return;
    }

    // Initial Load or Search
    emit(InventoryLoading());
    try {
      if (query != null && query.isNotEmpty) {
        final products = await _productService.getProducts(searchQuery: query);
        emit(
          InventoryLoaded(
            products,
            categories: _cachedCategories,
            hasReachedMax: true,
            totalProductCount: products.length,
          ),
        );
      } else {
        final results = await Future.wait([
          _productService.getProducts(limit: _pageSize, offset: 0),
          _productService.getTotalProductsCount(),
        ]);

        final products = results[0] as List<ProductModel>;
        final totalCount = results[1] as int;

        emit(
          InventoryLoaded(
            products,
            categories: _cachedCategories,
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
      // إعادة الحالة إلى Loaded مع التصنيفات المخزنة لضمان استمرار ظهورها في شاشة الإضافة
      emit(InventoryLoaded([], categories: _cachedCategories));
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
