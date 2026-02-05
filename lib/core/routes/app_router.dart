import 'package:go_router/go_router.dart';
import '../../features/inventory/ui/inventory_screen.dart';
import '../../features/inventory/ui/product_list_screen.dart';
import '../../features/inventory/ui/add_product_screen.dart';
import '../../features/inventory/ui/edit_product_screen.dart';
import '../../data/models/product_model.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      // الشاشة الرئيسية (المخزن - التصنيفات)
      GoRoute(
        path: '/',
        name: 'inventory',
        builder: (context, state) => const InventoryScreen(),
      ),

      // شاشة المنتجات (تستقبل معرف التصنيف)
      GoRoute(
        path: '/products/:categoryId',
        name: 'products',
        builder: (context, state) {
          final categoryId = state.pathParameters['categoryId'];
          return ProductListScreen(categoryId: categoryId);
        },
      ),

      // شاشة إضافة منتج
      GoRoute(
        path: '/add-product',
        name: 'add_product',
        builder: (context, state) => const AddProductScreen(),
      ),

      // شاشة تعديل منتج (تمرير ProductModel عبر extra)
      GoRoute(
        path: '/edit-product',
        name: 'edit_product',
        builder: (context, state) {
          final product = state.extra as ProductModel;
          return EditProductScreen(product: product);
        },
      ),
    ],
  );
}
