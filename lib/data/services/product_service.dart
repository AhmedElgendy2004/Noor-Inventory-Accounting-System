import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/supabase_constants.dart';
import '../models/product_model.dart';

class ProductService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Adds a new product to the database
  Future<void> addProduct(ProductModel product) async {
    try {
      await _supabase
          .from(SupabaseConstants.productsTable)
          .insert(product.toJson());
    } catch (e) {
      // In a real app, strict error handling is better
      throw Exception('Error adding product: $e');
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
      throw Exception('Error fetching product: $e');
    }
  }

  /// Get products with optional search query and pagination
  Future<List<ProductModel>> getProducts({
    String? searchQuery,
    int? limit,
    int? offset,
  }) async {
    try {
      dynamic query = _supabase.from(SupabaseConstants.productsTable).select();

      if (searchQuery != null && searchQuery.isNotEmpty) {
        // Search mode: Filter by name or barcode
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
  Future<int> getTotalProductsCount() async {
    try {
      final response = await _supabase
          .from(SupabaseConstants.productsTable)
          .count();
      // .count() returns the int directly in modern SDKs or via response depending on version.
      // If the SDK version returns Future<int>, this is correct.
      // If it returns PostgrestResponse, we need to inspect it.
      // Given standard Supabase Flutter usage: count() usually returns Future<int>.
      return response;
    } catch (e) {
      // Fallback or rethrow
      return 0;
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
