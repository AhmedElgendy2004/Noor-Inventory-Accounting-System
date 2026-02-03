import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/inline_barcode_scanner.dart';
import '../../../../data/models/product_model.dart';
import '../logic/inventory_cubit.dart';
import '../logic/inventory_state.dart';
import 'add_product_screen.dart';

import '../../../core/utils/snackbar_utils.dart'; // Add import

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({Key? key}) : super(key: key);

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryCubit>().loadInventory();
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
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      context.read<InventoryCubit>().loadInventory(loadMore: true);
    }
  }

  void _onSearchChanged(String value) {
    context.read<InventoryCubit>().loadInventory(query: value);
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
      // Assuming product.id is not null as it comes from DB
      if (product.id != null) {
        context.read<InventoryCubit>().deleteProduct(product.id!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المخزن')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddProductScreen()),
          ).then((_) {
            // Reload when coming back, just in case
            if (mounted) {
              context.read<InventoryCubit>().loadInventory();
            }
          });
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
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
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _searchController,
                  builder: (context, value, child) {
                    return TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: 'بحث عن منتج (اسم أو باركود)',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (value.text.isNotEmpty)
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
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocConsumer<InventoryCubit, InventoryState>(
              listener: (context, state) {
                if (state is InventoryError) {
                  SnackBarUtils.showError(context, state.message);
                }
              },
              builder: (context, state) {
                if (state is InventoryLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is InventoryLoaded) {
                  final products = state.products;

                  if (products.isEmpty) {
                    return const Center(child: Text('لا يوجد منتجات'));
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<InventoryCubit>().loadInventory(
                        query: _searchController.text,
                      );
                    },
                    child: Column(
                      children: [
                        // Total Count Widget (Visible only when not searching)
                        if (_searchController.text.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8.0,
                              horizontal: 16.0,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.inventory_2_outlined,
                                  size: 20,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'إجمالي الأصناف: ${state.totalProductCount}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        Expanded(
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
                                  child: Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  AddProductScreen(
                                                    productToEdit: product,
                                                  ),
                                            ),
                                          ).then((_) {
                                            if (mounted) {
                                              context
                                                  .read<InventoryCubit>()
                                                  .loadInventory();
                                            }
                                          });
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () =>
                                            _deleteProduct(product),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                } else if (state is InventoryError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        //   Text(state.message),
                        Icon(
                          Icons.signal_wifi_connected_no_internet_4,
                          size: 48,
                        ),
                        Text("لا يوجد اتصال بالإنترنت"),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            context.read<InventoryCubit>().loadInventory();
                          },
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  );
                }

                // Initial state or unexpected
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
        ],
      ),
    );
  }
}
