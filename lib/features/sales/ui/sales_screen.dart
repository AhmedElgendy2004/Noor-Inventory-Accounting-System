import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/customer_model.dart';
import '../logic/sales_cubit.dart';
import '../logic/sales_state.dart';
import 'widgets/product_search_delegate.dart';
import 'widgets/cart_item_widget.dart';
import 'widgets/payment_summary_footer.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  // Scanner or Search Controller hooks would go here
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize data
    context.read<SalesCubit>().initSales();
  }

  void _showCustomerDialog(BuildContext context, SalesCubit cubit) async {
    // In a real app this would be nice searchable list or modal
    // For now simple placeholder using the service's future directly?
    // Better to use the cubit's cached customers if we exposed them,
    // or just fetch fresh.
    // For this MVP, let's assume we fetch customers inside a FutureBuilder in the dialog

    // Note: Cubit doesn't expose list yet in state..
    // Let's assume we added a getter or we fetch using service
    // ... Implementing a simple mock dialog for now to demonstrate flow

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('اختيار عميل'),
        content: const SizedBox(
          height: 100,
          child: Center(child: Text('سيتم ربط قائمة العملاء هنا لاحقاً')),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Mock selection
              cubit.selectCustomer(
                CustomerModel(id: 'mock-id', name: 'عميل افتراضي'),
              );
              Navigator.pop(context);
            },
            child: const Text('تجربة عميل افتراضي'),
          ),
        ],
      ),
    );
  }

  void _openSearch(BuildContext context) async {
    final cubit = context.read<SalesCubit>();
    final selectedProduct = await showSearch(
      context: context,
      delegate: ProductSearchDelegate(cubit),
    );

    if (selectedProduct != null && context.mounted) {
      cubit.addProductToCart(selectedProduct);
      SnackBarUtils.showSuccess(
        context,
        'تمت إضافة ${selectedProduct.name} للسلة',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SalesCubit, SalesState>(
      listenWhen: (prev, curr) => curr is SalesSuccess || curr is SalesError,
      listener: (context, state) {
        if (state is SalesError) {
          SnackBarUtils.showError(context, state.message);
        } else if (state is SalesSuccess) {
          SnackBarUtils.showSuccess(context, 'تم حفظ الفاتورة بنجاح!');
          context.read<SalesCubit>().resetAfterSuccess();
        }
      },
      buildWhen: (prev, curr) => curr is SalesUpdated || curr is SalesLoading,
      builder: (context, state) {
        if (state is SalesLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is SalesUpdated) {
          return Scaffold(
            appBar: AppBar(
              title: const Text(' البيع '),
              actions: [
                // Wholesale Toggle
                Row(
                  children: [
                    const Text(
                      'جملة',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Switch(
                      value: state.isWholesale,
                      onChanged: (val) =>
                          context.read<SalesCubit>().toggleWholesale(val),
                      activeColor: Colors.orange,
                    ),
                  ],
                ),
                // Add Product Button
                IconButton(
                  icon: const Icon(Icons.add, size: 30),
                  tooltip: 'إضافة منتج (بحث/باركود)',
                  onPressed: () => _openSearch(context),
                ),
                const SizedBox(width: 8),
              ],
            ),
            body: SafeArea(
              child: Column(
                children: [
                  // Cart List
                  Expanded(
                    child: state.cartItems.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.shopping_cart_outlined,
                                  size: 80,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'السلة فارغة',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(8),
                            itemCount: state.cartItems.length,
                            separatorBuilder: (c, i) => const Divider(),
                            itemBuilder: (context, index) {
                              final item = state.cartItems[index];
                              return CartItemWidget(
                                item: item,
                                onIncrement: () => context
                                    .read<SalesCubit>()
                                    .updateQuantity(item.product.id!, 1),
                                onDecrement: () => context
                                    .read<SalesCubit>()
                                    .updateQuantity(item.product.id!, -1),
                                onRemove: () => context
                                    .read<SalesCubit>()
                                    .removeItem(item.product.id!),
                              );
                            },
                          ),
                  ),

                  // Footer
                  PaymentSummaryFooter(
                    totalAmount: state.totalAmount,
                    paymentType: state.paymentType,
                    isWholesale: state.isWholesale,
                    customerName: state.selectedCustomer?.name,
                    onTogglePaymentType: () {
                      final newType = state.paymentType == 'cash'
                          ? 'credit'
                          : 'cash';
                      context.read<SalesCubit>().togglePaymentType(newType);
                    },
                    onSelectCustomer: () => _showCustomerDialog(
                      context,
                      context.read<SalesCubit>(),
                    ),
                    onCheckout: () => context.read<SalesCubit>().submitSale(),
                  ),
                ],
              ),
            ),
          );
        }

        return const Scaffold(body: Center(child: Text('جاري التهيئة...')));
      },
    );
  }
}
