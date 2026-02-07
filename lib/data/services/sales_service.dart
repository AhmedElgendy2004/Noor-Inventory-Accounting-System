import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/supabase_constants.dart';
import '../models/product_model.dart';
import '../models/customer_model.dart';
import '../models/sales_invoice_model.dart';
import '../models/cart_item_model.dart';

class SalesService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// البحث عن المنتجات بالاسم أو الباركود
  Future<List<ProductModel>> searchProducts(String query) async {
    try {
      final response = await _supabase
          .from(SupabaseConstants.productsTable)
          .select()
          .or('name.ilike.%$query%,barcode.eq.$query')
          .limit(20);

      final data = response as List<dynamic>;
      return data.map((e) => ProductModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Search failed: $e');
    }
  }

  /// جلب قائمة العملاء
  Future<List<CustomerModel>> getCustomers() async {
    try {
      final response = await _supabase
          .from('customers')
          .select()
          .order('name', ascending: true);

      return (response as List).map((e) => CustomerModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to fetch customers: $e');
    }
  }

  /// تنفيذ عملية البيع كـ Transaction واحدة (Atomic)
  /// تستخدم دالة RPC `create_sale_transaction`
  Future<String> processSaleTransaction({
    required SalesInvoiceModel invoice,
    required List<CartItemModel> items,
  }) async {
    try {
      final params = {
        'p_invoice': invoice.toJson(),
        'p_items': items.map((e) => e.toJson()).toList(),
      };

      final response = await _supabase.rpc(
        'create_sale_transaction',
        params: params,
      );

      return response.toString();
    } catch (e) {
      throw Exception('Transaction failed: $e');
    }
  }

  /// جلب سجل الفواتير مع التفاصيل (العميل والمنتجات)
  Future<List<SalesInvoiceModel>> getSalesInvoices() async {
    try {
      final response = await _supabase
          .from('sales_invoices')
          .select('*, customers(name), sale_items(*, products(name))')
          .order('created_at', ascending: false);

      final data = response as List<dynamic>;
      return data.map((e) => SalesInvoiceModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to load invoices: $e');
    }
  }
}
