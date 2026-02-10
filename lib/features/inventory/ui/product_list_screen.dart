import 'package:al_noor_gallery/core/widgets/action_icon_button.dart';
import 'package:al_noor_gallery/features/inventory/ui/widget/custom_floating_action_button.dart';
import 'package:al_noor_gallery/features/inventory/ui/widget/product_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/custom_error_screen.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../../data/models/product_model.dart';
import '../../../../data/models/category_model.dart';
import '../logic/inventory_cubit.dart';
import '../logic/inventory_state.dart';

class ProductListScreen extends StatefulWidget {
  final String? categoryId;

  const ProductListScreen({super.key, required this.categoryId});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // جلب البيانات عند بدء الشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final categoryId = widget.categoryId == 'all' ? null : widget.categoryId;
      context.read<InventoryCubit>().fetchProducts(categoryId: categoryId);

      // Check if we should focus search
      final uri = GoRouterState.of(context).uri;
      if (uri.queryParameters['focus'] == 'true') {
        _searchFocusNode.requestFocus();
      }
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    final state = context.read<InventoryCubit>().state;
    if (state is InventoryLoaded) {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent * 0.9) {
        // إذا كان هناك بحث، لا نستخدم categoryId لأنه بحث شامل
        // إذا لم يكن هناك بحث، نستخدم categoryId الحالي
        final isSearching = _searchController.text.isNotEmpty;
        final categoryId = isSearching
            ? null
            : (widget.categoryId == 'all' ? null : widget.categoryId);

        context.read<InventoryCubit>().fetchProducts(
          categoryId: categoryId,
          query: _searchController.text,
          isLoadMore: true,
        );
      }
    }
  }

  void _onSearchChanged(String value) {
    // التنفيذ الفوري للبحث الشامل
    final categoryId = value.isNotEmpty
        ? null
        : (widget.categoryId == 'all' ? null : widget.categoryId);

    context.read<InventoryCubit>().fetchProducts(
      categoryId: categoryId,
      query: value.isEmpty ? null : value,
    );
  }

  Future<void> _deleteProduct(ProductModel product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المنتج'),
        content: Text('هل أنت متأكد من حذف ${product.name}؟'),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => context.pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      if (product.id != null) {
        context.read<InventoryCubit>().deleteProduct(product.id!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<InventoryCubit, InventoryState>(
          builder: (context, state) {
            String title = 'عدد المنتجات';
            if (state is InventoryLoaded) {
              title += ' ( ${state.totalProductCount} )';
            }
            return Text(title);
          },
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // العودة للتصنيفات وإعادة تحميلها لضمان التزامن
            context.read<InventoryCubit>().loadInitialData();
            context.go('/');
          },
        ),
      ),
      floatingActionButton: CustomFloatingActionButtonProductScreen(
        widget: widget,
        searchController: _searchController,
      ),
      //-------------------------------------------------------------------------
      body: SafeArea(
        child: Column(
          children: [
            // شريط البحث الموحد
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ProductSearchBar(
                controller: _searchController,
                onChanged: _onSearchChanged,
                onSubmitted: _onSearchChanged,
                focusNode: _searchFocusNode,
              ),
            ),

            // اسم التصنيف أو العدد
            BlocBuilder<InventoryCubit, InventoryState>(
              builder: (context, state) {
                if (state is InventoryLoaded &&
                    state.selectedCategoryId != null) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'التصنيف: ${state.categories.firstWhere((c) => c.id == state.selectedCategoryId, orElse: () => state.categories.isEmpty ? CategoryModel(name: '') : state.categories.first).name}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.blue.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            // Product List
            Expanded(
              child: BlocConsumer<InventoryCubit, InventoryState>(
                listener: (context, state) {
                  if (state is InventoryError) {
                    SnackBarUtils.showError(
                      context,
                      'حدث خطأ:/n --------/n ${state.message}',
                    );
                  }
                },
                builder: (context, state) {
                  if (state is InventoryLoading &&
                      (state is! InventoryLoaded ||
                          !(state as InventoryLoaded).hasReachedMax)) {
                    // Check strictly for initial loading
                    if (state is! InventoryLoaded) {
                      return const Center(child: CircularProgressIndicator());
                    }
                  }

                  if (state is InventoryLoaded) {
                    final products = state.products;

                    if (products.isEmpty) {
                      return const Center(child: Text('لا يوجد منتجات'));
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        final isSearching = _searchController.text.isNotEmpty;
                        final categoryId = isSearching
                            ? null
                            : (widget.categoryId == 'all'
                                  ? null
                                  : widget.categoryId);

                        await context.read<InventoryCubit>().fetchProducts(
                          categoryId: categoryId,
                          query: _searchController.text.isEmpty
                              ? null
                              : _searchController.text,
                        );
                      },
                      child: ListView.builder(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: state.hasReachedMax
                            ? products.length
                            : products.length + 1,
                        itemBuilder: (context, index) {
                          if (index >= products.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          final product = products[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ListTile(
                              //name
                              title: Text(
                                product.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('الباركود:  ${product.barcode}'),
                                  Divider(
                                    color: Colors.grey.shade300, // لون الخط
                                    thickness: 1, // سُمك الخط
                                    indent: 16, // مسافة فاضية من اليمين
                                    endIndent: 16, // مسافة فاضية من اليسار
                                  ),
                                  //سعر الشراء
                                  Row(
                                    children: [
                                      Text(
                                        "سعر الشراء:  ",
                                        style: TextStyle(
                                          color: Colors.brown.shade500,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        product.purchasePrice % 1 == 0
                                            ? product.purchasePrice
                                                  .toInt()
                                                  .toString() // لو صحيح يظهر بدون كسور
                                            : product.purchasePrice.toString(),
                                        style: TextStyle(
                                          color: Colors.brown.shade500,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  //  سعر البيع قطاعي
                                  Row(
                                    children: [
                                      Text(
                                        "البيع قطاعي:  ",
                                        style: TextStyle(
                                          color: Colors.green.shade700,

                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        product.retailPrice % 1 == 0
                                            ? product.retailPrice
                                                  .toInt()
                                                  .toString() // لو صحيح يظهر بدون كسور
                                            : product.retailPrice
                                                  .toString(), // لو كسر يظهر كما هو
                                        style: TextStyle(
                                          color: Colors.green.shade700,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  //  سعر البيع جمله
                                  Row(
                                    children: [
                                      Text(
                                        "البيع جمله:   ",
                                        style: TextStyle(
                                          color: Colors.orange.shade900,

                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        product.wholesalePrice % 1 == 0
                                            ? product.wholesalePrice
                                                  .toInt()
                                                  .toString() // لو صحيح يظهر بدون كسور
                                            : product.wholesalePrice
                                                  .toString(), // لو كسر يظهر كما هو
                                        style: TextStyle(
                                          color: Colors.orange.shade900,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),

                                  //  الكمية
                                  Align(
                                    alignment: AlignmentGeometry.bottomLeft,
                                    child: countProduct(
                                      label: 'الكمية: ${product.stockQuantity}',
                                      color:
                                          product.stockQuantity <=
                                              product.minStockLevel
                                          ? Colors.red.shade100
                                          : Colors.green.shade100,
                                      textColor:
                                          product.stockQuantity <=
                                              product.minStockLevel
                                          ? Colors.red.shade800
                                          : Colors.green.shade800,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ActionIconButton(
                                    icon: Icons.edit,
                                    backgroundColor: Colors.blue.shade300,
                                    onTap: () async {
                                      context.push(
                                        '/edit-product',
                                        extra: product,
                                      );
                                    },
                                  ),
                                  SizedBox(width: 8),
                                  ActionIconButton(
                                    icon: Icons.delete,
                                    backgroundColor: Colors.red.shade300,
                                    onTap: () => _deleteProduct(product),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  } else if (state is InventoryError) {
                    return CustomErrorScreen(
                      onRetry: () {
                        final isSearching = _searchController.text.isNotEmpty;
                        final categoryId = isSearching
                            ? null
                            : (widget.categoryId == 'all'
                                  ? null
                                  : widget.categoryId);

                        context.read<InventoryCubit>().fetchProducts(
                          categoryId: categoryId,
                          query: isSearching ? _searchController.text : null,
                        );
                      },
                    );
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -----------------------------Widgets-----------------------------

  Widget countProduct({
    required String label,
    required Color color,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
