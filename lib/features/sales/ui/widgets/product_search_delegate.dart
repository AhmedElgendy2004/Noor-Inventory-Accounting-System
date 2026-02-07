import 'package:flutter/material.dart';
import '../../../../core/utils/inline_barcode_scanner.dart';
import '../../../../data/models/product_model.dart';
import '../../logic/sales_cubit.dart';

class ProductSearchDelegate extends SearchDelegate<ProductModel?> {
  final SalesCubit salesCubit;

  ProductSearchDelegate(this.salesCubit);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.qr_code_scanner),
        tooltip: 'مسح الباركود',
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => Scaffold(
                appBar: AppBar(
                  title: const Text('مسح الباركود'),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                body: InlineBarcodeScanner(
                  onBarcodeDetected: (barcode) {
                    Navigator.pop(context);
                    query = barcode;
                    showResults(context);
                  },
                  onClose: () => Navigator.pop(context),
                ),
              ),
            ),
          );
        },
      ),
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.post_add, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'ابدأ الكتابة أو امسح الباركود لإضافة منتج',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    return FutureBuilder<List<ProductModel>>(
      future: salesCubit.searchProducts(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('حدث خطأ: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('لا توجد منتجات مطابقة'));
        }

        final products = snapshot.data!;
        return ListView.separated(
          itemCount: products.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final product = products[index];
            final isOutOfStock = product.stockQuantity <= 0;

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: isOutOfStock
                    ? Colors.red.shade100
                    : Colors.blue.shade100,
                child: Icon(
                  isOutOfStock ? Icons.close : Icons.inventory_2,
                  color: isOutOfStock ? Colors.red : Colors.blue,
                ),
              ),
              title: Text(
                product.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('الباركود: ${product.barcode}'),
                  Text(
                    'المخزون: ${product.stockQuantity}',
                    style: TextStyle(
                      color: isOutOfStock ? Colors.red : Colors.green,
                    ),
                  ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('قطاعي: ${product.retailPrice}'),
                  Text(
                    'جملة: ${product.wholesalePrice}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              enabled: !isOutOfStock,
              onTap: () {
                close(context, product);
              },
            );
          },
        );
      },
    );
  }

  @override
  String get searchFieldLabel => 'اسم المنتج أو الباركود...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: theme.appBarTheme.copyWith(
        backgroundColor: theme.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: const TextStyle(color: Colors.white70),
        border: InputBorder.none,
        filled: true,
        fillColor: Colors.white.withOpacity(0.2),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
      textTheme: theme.textTheme.copyWith(
        titleLarge: const TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }
}
