import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/inline_barcode_scanner.dart';
import '../../../../data/models/product_model.dart';
import '../logic/inventory_cubit.dart';
import '../logic/inventory_state.dart';
import 'add_product_screen.dart';
import 'edit_product_screen.dart';
import '../../../core/utils/snackbar_utils.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isScanning = false;

  final List<Color> _categoryColors = [
    Colors.blue.shade100,
    Colors.green.shade100,
    Colors.orange.shade100,
    Colors.purple.shade100,
    Colors.red.shade100,
    Colors.teal.shade100,
    Colors.amber.shade100,
    Colors.pink.shade100,
    Colors.indigo.shade100,
    Colors.brown.shade100,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryCubit>().loadInitialData();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isScanning) return;
    if (!context.read<InventoryCubit>().state.props.contains(true))
      return; // Check if Loaded state implicitly?
    // Better check state type
    final state = context.read<InventoryCubit>().state;
    if (state is InventoryLoaded && state.isProductView) {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent * 0.9) {
        context.read<InventoryCubit>().fetchProducts(
          categoryId: state.selectedCategoryId,
          query: _searchController.text,
          isLoadMore: true,
        );
      }
    }
  }

  void _onSearchChanged(String value) {
    // If not in product view, do nothing until user selects search?
    // Or if user types, switch to "All Products" search view?
    // Prompt says: "If user writes name while in 'Perfumes', search only in perfumes. If in main screen, search all."

    final state = context.read<InventoryCubit>().state;
    if (state is InventoryLoaded) {
      if (value.isNotEmpty) {
        // Trigger search
        context.read<InventoryCubit>().fetchProducts(
          categoryId: state.isProductView ? state.selectedCategoryId : null,
          query: value,
        );
      } else {
        // If clear search, and we were in product view, reload current category without query
        if (state.isProductView) {
          context.read<InventoryCubit>().fetchProducts(
            categoryId: state.selectedCategoryId,
            query: null,
          );
        }
      }
    }
  }

  void _showAddCategoryDialog(BuildContext context) {
    final TextEditingController categoryController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة تصنيف جديد'),
        content: TextField(
          controller: categoryController,
          decoration: const InputDecoration(
            labelText: 'اسم التصنيف',
            hintText: 'مثال: إلكترونيات',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = categoryController.text.trim();
              if (name.isNotEmpty) {
                context
                    .read<InventoryCubit>()
                    .addNewCategory(name)
                    .then((_) {
                      Navigator.pop(context);
                      SnackBarUtils.showSuccess(
                        context,
                        'تمت إضافة التصنيف بنجاح',
                      );
                    })
                    .catchError((e) {
                      Navigator.pop(context);
                      SnackBarUtils.showError(context, 'فشل الإضافة: $e');
                    });
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
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
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
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
    return BlocBuilder<InventoryCubit, InventoryState>(
      builder: (context, state) {
        bool isProductView = false;
        if (state is InventoryLoaded) {
          isProductView = state.isProductView;
        }

        return WillPopScope(
          onWillPop: () async {
            if (isProductView) {
              context.read<InventoryCubit>().backToCategories();
              _searchController.clear();
              return false;
            }
            return true;
          },
          child: Scaffold(
            appBar: AppBar(
              title: const Text('المخزن'),
              leading: isProductView
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        context.read<InventoryCubit>().backToCategories();
                        _searchController.clear();
                      },
                    )
                  : null,
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () async {
                final cubit = context.read<InventoryCubit>();
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddProductScreen(),
                  ),
                );
                // Upon return, usually we want to refresh whatever view we are in
                if (mounted && cubit.state is InventoryLoaded) {
                  final s = cubit.state as InventoryLoaded;
                  if (s.isProductView) {
                    cubit.fetchProducts(
                      categoryId: s.selectedCategoryId,
                      query: _searchController.text,
                    );
                  } else {
                    cubit.loadInitialData();
                  }
                }
              },
              child: const Icon(Icons.add),
            ),
            body: SafeArea(
              child: Column(
                children: [
                  // Search Bar Area
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        if (_isScanning)
                          InlineBarcodeScanner(
                            onBarcodeDetected: (code) {
                              setState(() {
                                _searchController.text = code;
                                _isScanning = false;
                              });
                              _onSearchChanged(code);
                            },
                            onClose: () => setState(() => _isScanning = false),
                          ),
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            labelText: 'بحث عن منتج (اسم أو باركود)',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_searchController.text.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: () {
                                      _searchController.clear();
                                      _onSearchChanged('');
                                    },
                                  ),
                                IconButton(
                                  icon: Icon(
                                    _isScanning
                                        ? Icons.stop_circle
                                        : Icons.qr_code_scanner,
                                  ),
                                  color: _isScanning ? Colors.red : null,
                                  onPressed: () {
                                    setState(() {
                                      _isScanning = !_isScanning;
                                    });
                                  },
                                ),
                              ],
                            ),
                            border: const OutlineInputBorder(),
                          ),
                          onChanged: _onSearchChanged,
                        ),

                        // Total Count Text (Shown in Main View)
                        if (state is InventoryLoaded && !state.isProductView)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'إجمالي عدد المنتجات: ${state.totalProductCount}',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                        // اسم التصنيف عند تصفح المنتجات داخل تصنيف
                        if (state is InventoryLoaded &&
                            state.isProductView &&
                            state.selectedCategoryId != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'التصنيف: ${state.categories.firstWhere((c) => c.id == state.selectedCategoryId, orElse: () => state.categories.first).name}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.blue.shade800,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: BlocConsumer<InventoryCubit, InventoryState>(
                      listener: (context, state) {
                        if (state is InventoryError) {
                          SnackBarUtils.showError(
                            context,
                            'حدث خطأ: ${state.message}',
                          );
                        }
                      },
                      builder: (context, state) {
                        if (state is InventoryLoading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        } else if (state is InventoryLoaded) {
                          if (state.isProductView) {
                            return _buildProductList(state);
                          } else {
                            return _buildCategoryGrid(state);
                          }
                        } else if (state is InventoryError) {
                          return Center(
                            child: ElevatedButton(
                              onPressed: () => context
                                  .read<InventoryCubit>()
                                  .loadInitialData(),
                              child: const Text('إعادة المحاولة'),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryGrid(InventoryLoaded state) {
    return RefreshIndicator(
      onRefresh: () async {
        await context.read<InventoryCubit>().loadCategories();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            // "All Products" Button
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              height: 60,
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blueAccent),
              ),
              child: InkWell(
                onTap: () {
                  _searchController.clear();
                  context.read<InventoryCubit>().fetchProducts();
                },
                borderRadius: BorderRadius.circular(12),
                child: const Center(
                  child: Text(
                    'عرض كل المنتجات',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                ),
              ),
            ),

            // Grid View
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.2,
              ),
              itemCount: state.categories.length,
              itemBuilder: (context, index) {
                final category = state.categories[index];
                final color = _categoryColors[index % _categoryColors.length];

                return InkWell(
                  onTap: () {
                    _searchController.clear();
                    context.read<InventoryCubit>().fetchProducts(
                      categoryId: category.id,
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          category.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            // زر إضافة تصنيف جديد
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton.icon(
                  onPressed: () => _showAddCategoryDialog(context),
                  icon: const Icon(Icons.add_circle_outline, size: 28),
                  label: const Text(
                    'إضافة تصنيف جديد',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue.shade700,
                    side: BorderSide(color: Colors.blue.shade300, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 80), // For FAB space
          ],
        ),
      ),
    );
  }

  Widget _buildProductList(InventoryLoaded state) {
    final products = state.products;

    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(' لا يوجد منتجات'),
            if (state.totalProductCount == 0 &&
                state.selectedCategoryId == null &&
                _searchController.text.isEmpty)
              const Text('قم بإضافة منتجات جديدة'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await context.read<InventoryCubit>().fetchProducts(
          categoryId: state.selectedCategoryId,
          query: _searchController.text,
        );
      },
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: state.hasReachedMax ? products.length : products.length + 1,
        itemBuilder: (context, index) {
          if (index >= products.length) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final product = products[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(
                product.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('الكمية:'),
                      Text(
                        ' ${product.stockQuantity} ',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text("سعر بيع القطاعي :"),
                      Text(
                        ' ${product.retailPrice} ',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text("سعر بيع الجمله :"),
                      Text(
                        ' ${product.wholesalePrice} ',
                        style: TextStyle(
                          color: Colors.brown,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () async {
                      final cubit = context.read<InventoryCubit>();
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              EditProductScreen(product: product),
                        ),
                      );
                      if (mounted) {
                        // Refresh items without resetting view
                        cubit.fetchProducts(
                          categoryId: state.selectedCategoryId,
                          query: _searchController.text,
                        );
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteProduct(product),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
