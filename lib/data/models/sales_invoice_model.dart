enum PaymentType { cash, credit }

class SaleItemModel {
  final String productName;
  final int quantity;
  final double priceAtSale;
  final double total;
  final String priceType; // "retail" or "wholesale"

  SaleItemModel({
    required this.productName,
    required this.quantity,
    required this.priceAtSale,
    required this.priceType,
  }) : total = priceAtSale * quantity;

  factory SaleItemModel.fromJson(Map<String, dynamic> json) {
    return SaleItemModel(
      productName: json['products']?['name'] ?? 'منتج غير معروف',
      quantity: json['quantity'] ?? 0,
      priceAtSale: (json['price_at_sale'] as num).toDouble(),
      priceType: json['price_type'] ?? 'retail',
    );
  }
}

class SalesInvoiceModel {
  final String? id;
  final String? invoiceNumber; // رقم الفاتورة
  final String? customerId;
  final String? customerName; // اسم العميل (للعرض)
  final double totalAmount;
  final double paidAmount;
  final PaymentType paymentType;
  final DateTime date;
  final List<SaleItemModel>? items; // الأصناف (للعرض)

  SalesInvoiceModel({
    this.id,
    this.invoiceNumber,
    this.customerId,
    this.customerName,
    required this.totalAmount,
    required this.paidAmount,
    required this.paymentType,
    required this.date,
    this.items,
  });

  // هل الفاتورة جملة؟ (إذا كان أي صنف فيها جملة)
  bool get isWholesale {
    if (items == null || items!.isEmpty) return false;
    return items!.any((item) => item.priceType == 'wholesale');
  }

  // تحويل لـ JSON مطابق لجدول sales_invoices
  Map<String, dynamic> toJson() {
    return {
      if (invoiceNumber != null) 'invoice_number': invoiceNumber,
      'customer_id': customerId, // يقبل null
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'payment_type': paymentType.name, // "cash" or "credit"
      'created_at': date.toIso8601String(),
    };
  }

  // قراءة من قاعدة البيانات
  factory SalesInvoiceModel.fromJson(Map<String, dynamic> json) {
    var rawItems = json['sale_items'] as List?;
    List<SaleItemModel>? parsedItems;

    if (rawItems != null) {
      parsedItems = rawItems.map((i) => SaleItemModel.fromJson(i)).toList();
    }

    return SalesInvoiceModel(
      id: json['id'],
      invoiceNumber: json['invoice_number']?.toString(),
      customerId: json['customer_id'],
      customerName: json['customers'] != null
          ? json['customers']['name']
          : null,
      totalAmount: (json['total_amount'] as num).toDouble(),
      paidAmount: (json['paid_amount'] as num).toDouble(),
      paymentType: PaymentType.values.firstWhere(
        (e) => e.name == json['payment_type'],
        orElse: () => PaymentType.cash,
      ),
      date: DateTime.parse(json['created_at']),
      items: parsedItems,
    );
  }
}
