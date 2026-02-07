import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/cart_item_model.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/sales_invoice_model.dart';
import '../../../data/services/sales_service.dart';
import 'sales_state.dart';

class SalesCubit extends Cubit<SalesState> {
  final SalesService _salesService;

  SalesCubit(this._salesService) : super(SalesInitial());

  // === UI Helpers ===

  // Initialize Sales Screen (Load Customers, etc.)
  Future<void> initSales() async {
    try {
      emit(const SalesUpdated(cartItems: [], totalAmount: 0.0));
    } catch (e) {
      emit(SalesError("فشل تحميل البيانات الأولية: $e"));
    }
  }

  // === Cart Management ===

  void togglePaymentType(String type) {
    if (state is SalesUpdated) {
      final currentState = state as SalesUpdated;
      emit(currentState.copyWith(paymentType: type));
    }
  }

  void selectCustomer(CustomerModel? customer) {
    if (state is SalesUpdated) {
      final currentState = state as SalesUpdated;
      emit(currentState.copyWith(selectedCustomer: customer));
    }
  }

  void toggleWholesale(bool isWholesale) {
    if (state is SalesUpdated) {
      final currentState = state as SalesUpdated;

      // Update prices for all items in cart based on new mode
      final updatedItems = currentState.cartItems.map((item) {
        return item.copyWith(
          priceAtSale: isWholesale
              ? item.product.wholesalePrice
              : item.product.retailPrice,
          priceType: isWholesale ? 'wholesale' : 'retail',
        );
      }).toList();

      emit(
        currentState.copyWith(
          isWholesale: isWholesale,
          cartItems: updatedItems,
        ),
      );
    }
  }

  void addProductToCart(ProductModel product) {
    if (state is! SalesUpdated) return;
    final currentState = state as SalesUpdated;

    // 1. Check if product already exists
    final index = currentState.cartItems.indexWhere(
      (i) => i.product.id == product.id,
    );

    List<CartItemModel> newItems = List.from(currentState.cartItems);

    // Determine price based on current mode
    final price = currentState.isWholesale
        ? product.wholesalePrice
        : product.retailPrice;
    final priceType = currentState.isWholesale ? 'wholesale' : 'retail';

    if (index >= 0) {
      // 2. Increment Quantity
      final existingItem = newItems[index];

      // validate stock
      if (existingItem.quantity + 1 > product.stockQuantity) {
        emit(
          SalesError(
            "الكمية المطلوبة غير متوفرة في المخزن. المتاح: ${product.stockQuantity}",
          ),
        );
        emit(currentState);
        return;
      }

      newItems[index] = existingItem.copyWith(
        quantity: existingItem.quantity + 1,
      );
    } else {
      // 3. Add new item
      if (product.stockQuantity < 1) {
        emit(const SalesError("المنتج نفذ من المخزن!"));
        emit(currentState);
        return;
      }

      newItems.add(
        CartItemModel(
          product: product,
          quantity: 1,
          priceAtSale: price,
          priceType: priceType,
        ),
      );
    }

    emit(currentState.copyWith(cartItems: newItems));
  }

  void updateQuantity(String productId, int delta) {
    if (state is! SalesUpdated) return;
    final currentState = state as SalesUpdated;

    final index = currentState.cartItems.indexWhere(
      (i) => i.product.id == productId,
    );
    if (index == -1) return;

    final item = currentState.cartItems[index];
    final newQty = item.quantity + delta;

    List<CartItemModel> newItems = List.from(currentState.cartItems);

    if (newQty <= 0) {
      newItems.removeAt(index);
    } else {
      if (delta > 0 && newQty > item.product.stockQuantity) {
        emit(SalesError("لا يمكن تجاوز الكمية المتاحة"));
        emit(currentState);
        return;
      }
      newItems[index] = item.copyWith(quantity: newQty);
    }

    emit(currentState.copyWith(cartItems: newItems));
  }

  void removeItem(String productId) {
    if (state is! SalesUpdated) return;
    final currentState = state as SalesUpdated;

    final newItems = currentState.cartItems
        .where((i) => i.product.id != productId)
        .toList();
    emit(currentState.copyWith(cartItems: newItems));
  }

  void clearCart() {
    if (state is! SalesUpdated) return;
    emit((state as SalesUpdated).copyWith(cartItems: []));
  }

  // === Search Logic ===
  Future<List<ProductModel>> searchProducts(String query) async {
    if (query.isEmpty) return [];
    return await _salesService.searchProducts(query);
  }

  // === Process Sale ===
  Future<void> submitSale() async {
    if (state is! SalesUpdated) return;
    final currentState = state as SalesUpdated;

    // Validation
    if (currentState.cartItems.isEmpty) {
      emit(const SalesError("السلة فارغة!"));
      emit(currentState);
      return;
    }

    if (currentState.paymentType == 'credit' &&
        currentState.selectedCustomer == null) {
      emit(const SalesError("يجب اختيار عميل للبيع الآجل!"));
      emit(currentState);
      return;
    }

    emit(SalesLoading());

    try {
      final invoice = SalesInvoiceModel(
        customerId: currentState.selectedCustomer?.id,
        totalAmount: currentState.totalAmount,
        paidAmount: currentState.paymentType == 'cash'
            ? currentState.totalAmount
            : 0,
        paymentType: currentState.paymentType == 'cash'
            ? PaymentType.cash
            : PaymentType.credit,
        date: DateTime.now(),
      );

      final invId = await _salesService.processSaleTransaction(
        invoice: invoice,
        items: currentState.cartItems,
      );

      emit(SalesSuccess(invId));
    } catch (e) {
      // طباعة الخطأ في الكونسول للمطور
      debugPrint("❌ Sales Transaction Failed: $e");

      // استخراج رسالة خطأ مفهومة إذا أمكن
      String errorMessage = "فشل تنفيذ البيع";
      if (e.toString().contains("insufficient stock")) {
        errorMessage = "الكمية في المخزن غير كافية لبعض الأصناف";
      } else if (e.toString().contains("create_sale_transaction")) {
        errorMessage = "خطأ في الاتصال بقاعدة البيانات (RPC Error)";
      } else {
        errorMessage = "فشل: $e"; // عرض الخطأ الخام للمساعدة في التشخيص
      }

      emit(SalesError(errorMessage));
      emit(currentState);
    }
  }

  void resetAfterSuccess() {
    emit(const SalesUpdated(cartItems: [], totalAmount: 0.0));
  }
}
