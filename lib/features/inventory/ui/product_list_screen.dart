// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/inline_barcode_scanner.dart';
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
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    // جلب البيانات عند بدء الشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final categoryId = widget.categoryId == 'all' ? null : widget.categoryId;
      context.read<InventoryCubit>().fetchProducts(categoryId: categoryId);
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
    final state = context.read<InventoryCubit>().state;
    if (state is InventoryLoaded) {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent * 0.9) {
        final categoryId = widget.categoryId == 'all'
            ? null
            : widget.categoryId;
        context.read<InventoryCubit>().fetchProducts(
          categoryId: categoryId,
          query: _searchController.text,
          isLoadMore: true,
        );
      }
    }
  }

  void _onSearchChanged(String value) {
    if (value.isNotEmpty) {
      final categoryId = widget.categoryId == 'all' ? null : widget.categoryId;
      context.read<InventoryCubit>().fetchProducts(
        categoryId: categoryId,
        query: value,
      );
    } else {
      final categoryId = widget.categoryId == 'all' ? null : widget.categoryId;
      context.read<InventoryCubit>().fetchProducts(
        categoryId: categoryId,
        query: null,
      );
    }
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
        title: const Text('المنتجات'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // العودة للتصنيفات وإعادة تحميلها لضمان التزامن
            context.read<InventoryCubit>().loadInitialData();
            context.go('/');
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // استخدام navigation عبر GoRouter
          await context.push('/add-product');
          // عند العودة، قم بتحديث القائمة الحالية (result قد يكون مفيداً للتحقق من الإضافة)
          if (mounted) {
            final categoryId = widget.categoryId == 'all'
                ? null
                : widget.categoryId;
            context.read<InventoryCubit>().fetchProducts(
              categoryId: categoryId,
              query: _searchController.text,
            );
          }
        },
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
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
                  // اسم التصنيف أو العدد
                  BlocBuilder<InventoryCubit, InventoryState>(
                    builder: (context, state) {
                      if (state is InventoryLoaded &&
                          state.selectedCategoryId != null) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
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
                ],
              ),
            ),

            // Product List
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
                        final categoryId = widget.categoryId == 'all'
                            ? null
                            : widget.categoryId;
                        await context.read<InventoryCubit>().fetchProducts(
                          categoryId: categoryId,
                          query: _searchController.text,
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
                              title: Text(
                                product.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('الباركود: ${product.barcode}'),
                                  Text(
                                    'السعر: ${product.retailPrice} | الكمية: ${product.stockQuantity}',
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () async {
                                      // الانتقال لصفحة التعديل مع تمرير المنتج
                                      context.push(
                                        '/edit-product',
                                        extra: product,
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _deleteProduct(product),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  } else if (state is InventoryError) {
                    return Center(
                      child: ElevatedButton(
                        onPressed: () {
                          final categoryId = widget.categoryId == 'all'
                              ? null
                              : widget.categoryId;
                          context.read<InventoryCubit>().fetchProducts(
                            categoryId: categoryId,
                          );
                        },
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
    );
  }
}
