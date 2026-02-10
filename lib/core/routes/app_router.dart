import 'package:go_router/go_router.dart';
import '../../features/home/ui/home_screen.dart'; 
import '../../features/sales/ui/sales_screen.dart'; 
import '../../features/inventory/ui/inventory_screen.dart';
import '../../features/inventory/ui/product_list_screen.dart';
import '../../features/inventory/ui/add_product_screen.dart';
import '../../features/inventory/ui/edit_product_screen.dart';
import '../../features/sales_history/ui/sales_history_screen.dart';
import '../../features/sales_history/ui/sales_invoice_detail_screen.dart';
import '../../data/models/product_model.dart';
import '../../data/models/sales_invoice_model.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      // الشاشة الرئيسية (لوحة التحكم)
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),

      // سجل المبيعات
      GoRoute(
        path: '/sales-history',
        builder: (context, state) => const SalesHistoryScreen(),
        routes: [
          GoRoute(
            path: 'details',
            builder: (context, state) {
              final invoice = state.extra as SalesInvoiceModel;
              return SalesInvoiceDetailScreen(invoice: invoice);
            },
          ),
        ],
      ),

      // نقطة البيع
      GoRoute(
        path: '/pos',
        name: 'pos',
        builder: (context, state) => const SalesScreen(),
      ),

      // إدارة المخزن (التصنيفات) - تم تغيير المسار
      GoRoute(
        path: '/inventory',
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
