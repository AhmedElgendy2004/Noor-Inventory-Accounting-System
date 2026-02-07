import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/supabase_constants.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';

class ProductService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch all categories with product count
  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await _supabase
          .from('categories')
          .select('*, products(count)')
          .order('name', ascending: true);

      final data = response as List<dynamic>;
      return data.map((e) => CategoryModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Error fetching categories:/n --------/n $e');
    }
  }

  /// Add a new category
  Future<CategoryModel> addCategory(String name, int color) async {
    try {
      final response = await _supabase
          .from('categories')
          .insert({'name': name, 'color': color})
          .select()
          .single();
      return CategoryModel.fromJson(response);
    } catch (e) {
      throw Exception('Error adding category:/n --------/n $e');
    }
  }

  /// Delete a category
  Future<void> deleteCategory(String categoryId) async {
    try {
      // 1. Unlink products
      await _supabase
          .from(SupabaseConstants.productsTable)
          .update({'category_id': null})
          .eq('category_id', categoryId);

      // 2. Delete category
      await _supabase.from('categories').delete().eq('id', categoryId);
    } catch (e) {
      throw Exception('Error deleting category:/n --------/n $e');
    }
  }

  /// Adds a new product to the database
  Future<void> addProduct(ProductModel product) async {
    try {
      await _supabase
          .from(SupabaseConstants.productsTable)
          .insert(product.toJson());
    } catch (e) {
      // In a real app, strict error handling is better
      throw Exception('Error adding product:/n --------/n $e');
    }
  }

  /// Adds multiple products to the database (Bulk Insert)
  Future<void> addProducts(List<ProductModel> products) async {
    try {
      final data = products.map((e) => e.toJson()).toList();
      await _supabase.from(SupabaseConstants.productsTable).insert(data);
    } catch (e) {
      throw Exception('Error adding products:/n --------/n $e');
    }
  }

  /// Optional: Check if product exists by barcode (useful for later)
  Future<ProductModel?> getProductByBarcode(String barcode) async {
    try {
      final response = await _supabase
          .from(SupabaseConstants.productsTable)
          .select()
          .eq('barcode', barcode)
          .maybeSingle();

      if (response == null) return null;
      return ProductModel.fromJson(response);
    } catch (e) {
      throw Exception('Error fetching product: /n --------/n $e');
    }
  }

  /// Get products with optional search query, category, and pagination
  Future<List<ProductModel>> getProducts({
    String? searchQuery,
    String? categoryId,
    int? limit,
    int? offset,
  }) async {
    try {
      dynamic query = _supabase.from(SupabaseConstants.productsTable).select();

      // Category Filter
      if (categoryId != null && categoryId.isNotEmpty) {
        query = query.eq('category_id', categoryId);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        // Search mode: Filter by name or barcode
        // Note: If combining with category, 'or' might need to be scoped carefully
        // or applied as a filter on top of the base query.
        // For simplicity with Supabase, .or() at top level acts as OR for the clauses inside,
        // but AND with previous filters.
        query = query.or(
          'name.ilike.%$searchQuery%,barcode.ilike.%$searchQuery%',
        );
      } else {
        // Normal mode: Default ordering
        query = query.order('created_at', ascending: false);
      }

      // Apply pagination if provided
      if (limit != null && offset != null) {
        query = query.range(offset, offset + limit - 1);
      }

      final response = await query;
      return (response as List).map((e) => ProductModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Error fetching products: $e');
    }
  }

  /// Get total count of products
  Future<int> getTotalProductsCount({
    String? categoryId,
    String? searchQuery,
  }) async {
    try {
      var query = _supabase.from(SupabaseConstants.productsTable).count();

      if (categoryId != null && categoryId.isNotEmpty) {
        query = query.eq('category_id', categoryId);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or(
          'name.ilike.%$searchQuery%,barcode.ilike.%$searchQuery%',
        );
      }

      return await query;
    } catch (e) {
      // Rethrow to allow UI to show error screen properly
      rethrow;
    }
  }

  /// Update an existing product
  Future<void> updateProduct(ProductModel product) async {
    try {
      if (product.id == null) {
        throw Exception('Product ID cannot be null for update');
      }
      await _supabase
          .from(SupabaseConstants.productsTable)
          .update(product.toJson())
          .eq('id', product.id!);
    } catch (e) {
      throw Exception('Error updating product: $e');
    }
  }

  /// Delete a product
  Future<void> deleteProduct(String id) async {
    try {
      await _supabase
          .from(SupabaseConstants.productsTable)
          .delete()
          .eq('id', id);
    } catch (e) {
      throw Exception('Error deleting product: $e');
    }
  }
}
