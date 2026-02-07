class CategoryModel {
  final String? id;
  final String name;
  final int? color;
  final int productCount;

  CategoryModel({
    this.id,
    required this.name,
    this.color,
    this.productCount = 0,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    int count = 0;
    // Supabase query with count (select *, products(count)) typically returns
    // "products": [{"count": N}] or similar structure depending on API version.
    // If using .count(), it's separate. If using relation count in select:
    if (json['products'] != null && json['products'] is List) {
      final list = json['products'] as List;
      if (list.isNotEmpty && list.first is Map && list.first['count'] != null) {
        count = list.first['count'] as int;
      }
    }

    return CategoryModel(
      id: json['id'] as String?,
      name: json['name'] as String,
      color: json['color'] != null ? json['color'] as int : null,
      productCount: count,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (id != null) 'id': id,
      if (color != null) 'color': color,
      // productCount is usually read-only from DB
    };
  }
}
