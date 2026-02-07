class ProductModel {
  final String? id;
  final String name;
  final String barcode;
  final String? brandCompany;
  final String? unit;
  final int stockQuantity;
  final int minStockLevel;
  final double purchasePrice;
  final double retailPrice;
  final double wholesalePrice;
  final DateTime? expiryDate;
  final int? expiryAlertDays;
  final DateTime? lastPurchaseDate;
  //lastPurchaseDate
  // عاوز دا يتسجل تلقائي بتاريخ الانشاء ويظهر عند الدخول لشاشه التعديل
  final String? supplierId;
  final String? categoryId;
  final String? categoryName; // للعرض فقط

  ProductModel({
    this.id,
    required this.name,
    required this.barcode,
    this.brandCompany,
    this.unit,
    required this.stockQuantity,
    required this.minStockLevel,
    required this.purchasePrice,
    required this.retailPrice,
    required this.wholesalePrice,
    this.expiryDate,
    this.expiryAlertDays,
    this.lastPurchaseDate,
    this.supplierId,
    this.categoryId,
    this.categoryName,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String?,
      name: json['name'] as String,
      barcode: json['barcode'] as String,
      brandCompany: json['brand_company'] as String?,
      unit: json['unit'] as String?,
      stockQuantity: json['stock_quantity'] as int? ?? 0,
      minStockLevel: json['min_stock_level'] as int? ?? 0,
      purchasePrice: (json['purchase_price'] as num?)?.toDouble() ?? 0.0,
      retailPrice: (json['retail_price'] as num?)?.toDouble() ?? 0.0,
      wholesalePrice: (json['wholesale_price'] as num?)?.toDouble() ?? 0.0,
      expiryDate: json['expiry_date'] != null
          ? DateTime.tryParse(json['expiry_date'] as String)
          : null,
      expiryAlertDays: json['expiry_alert_days'] as int?,
      lastPurchaseDate: json['last_purchase_date'] != null
          ? DateTime.tryParse(json['last_purchase_date'] as String)
          : null,
      supplierId: json['supplier_id'] as String?,
      categoryId: json['category_id'] as String?,
      // نفترض أن Supabase يرجع join بهذا الشكل إذا تم طلبه
      categoryName: json['categories'] != null
          ? json['categories']['name']
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'name': name,
      'barcode': barcode,
      'brand_company': brandCompany,
      'unit': unit,
      'stock_quantity': stockQuantity,
      'min_stock_level': minStockLevel,
      'purchase_price': purchasePrice,
      'retail_price': retailPrice,
      'wholesale_price': wholesalePrice,
      'expiry_date': expiryDate?.toIso8601String(),
      'expiry_alert_days': expiryAlertDays,
      'last_purchase_date': lastPurchaseDate?.toIso8601String(),
      'supplier_id': supplierId,
      'category_id': categoryId,
    };
    if (id != null) {
      data['id'] = id;
    }
    return data;
  }
}
