import 'package:al_noor_gallery/core/constants/constants.dart';
import 'package:al_noor_gallery/features/inventory/ui/widget/custom_floating_action_button.dart';
import 'package:al_noor_gallery/features/inventory/ui/widget/product_search_bar.dart';
import 'package:al_noor_gallery/features/inventory/ui/widget/product_card.dart'; // Import ProductCard
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/custom_error_screen.dart';
import '../../../../data/models/category_model.dart';
import '../logic/inventory_cubit.dart';
import '../logic/inventory_state.dart';
import '../../../core/utils/snackbar_utils.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

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
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      context.read<InventoryCubit>().loadMoreProducts();
    }
  }

  // دالة توليد البيانات الاختبارية
  void _generateMockData() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('توليد بيانات اختبارية'),
        content: const Text(
          'هل تريد إضافة 100 منتج عشوائي؟\n'
          'يستخدم هذا الغرض للاختبار فقط.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<InventoryCubit>().generateMockProducts();
            },
            child: const Text('توليد'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCategory(CategoryModel category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف التصنيف'),
        content: Text(
          'هل أنت متأكد من حذف تصنيف "${category.name}"؟\nسيؤدي هذا لحذف جميع المنتجات بداخله!',
        ),
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

    if (confirm == true && mounted && category.id != null) {
      context.read<InventoryCubit>().deleteCategory(category.id!);
      context.read<InventoryCubit>().loadCategories();
      SnackBarUtils.showSuccess(context, 'تم حذف التصنيف بنجاح');
    }
  }

  void _showAddCategoryDialog(BuildContext context) {
    final TextEditingController categoryController = TextEditingController();
    Color selectedColor = KlistCategoryColors[0];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('إضافة تصنيف جديد'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: categoryController,
                    decoration: const InputDecoration(
                      labelText: 'اسم التصنيف',
                      hintText: 'مثال: مستحضرات تجميل',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'اختر لون التصنيف:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: KlistCategoryColors.map((color) {
                      final isSelected = selectedColor == color;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedColor = color;
                          });
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(color: Colors.blueAccent, width: 3)
                                : Border.all(color: Colors.grey.shade300),
                            boxShadow: [
                              if (isSelected)
                                BoxShadow(
                                  color: color,
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                            ],
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.blueAccent,
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final name = categoryController.text.trim();
                  if (name.isNotEmpty) {
                    // 1. خزن الـ Cubit والـ Navigator قبل البدء (اختياري لكن أفضل)
                    final inventoryCubit = context.read<InventoryCubit>();
                    Navigator.of(
                      context,
                    ); // أو استخدام context.pop مباشرة مع التشيك

                    try {
                      // 2. تنفيذ العملية
                      await inventoryCubit.addNewCategory(
                        name,
                        selectedColor.toARGB32(),
                      );

                      // 3. التحقق من أن الـ context لسه موجود قبل أي أكشن في الـ UI
                      if (!context.mounted) return;

                      // 4. تنفيذ الأكشنز
                      context.pop(); // قفل الـ Dialog
                      SnackBarUtils.showSuccess(
                        context,
                        'تمت إضافة التصنيف بنجاح',
                      );
                      context.read<InventoryCubit>().loadCategories();
                    } catch (e) {
                      // 5. نفس التشيك في حالة الخطأ
                      if (!context.mounted) return;

                      context.pop();
                      SnackBarUtils.showError(context, 'فشل الإضافة');
                    }
                  }
                },
                child: const Text('إضافة'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المخزن'),
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_add),
            tooltip: 'توليد بيانات اختبار',
            onPressed: _generateMockData,
          ),
        ],
      ),
      floatingActionButton: CustomFloatingActionButton(),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await context.read<InventoryCubit>().refreshInventory();
          },
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ProductSearchBar(
                  controller: _searchController,
                  onChanged: (val) {},
                  onSubmitted: (val) {
                    context.push('/products/all?focus=true');
                  },
                  readOnly: true,
                  onTap: () {
                    context.push('/products/all?focus=true');
                  },
                ),
              ),
              Expanded(
                child: BlocConsumer<InventoryCubit, InventoryState>(
                  listener: (context, state) {
                    if (state is InventoryError) {
                      SnackBarUtils.showError(context, "حدث خطا اثناء التحميل");
                    }
                  },
                  builder: (context, state) {
                    if (state is InventoryLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is InventoryError) {
                      return CustomErrorScreen(
                        onRetry: () =>
                            context.read<InventoryCubit>().loadInitialData(),
                      );
                    } else if (state is InventoryLoaded) {
                      return CustomScrollView(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverToBoxAdapter(child: totalItemsCountCard(state)),
                          const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Text(
                                "التصنيفات",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            sliver: categoryGrid(state),
                          ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 16,
                              ),
                              child: SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      _showAddCategoryDialog(context),
                                  icon: const Icon(Icons.add_circle_outline),
                                  label: const Text('إضافة تصنيف جديد'),
                                ),
                              ),
                            ),
                          ),

                          if (state.isLoadingMore)
                            const SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                            ),
                          const SliverPadding(
                            padding: EdgeInsets.only(bottom: 80),
                          ),
                        ],
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //-------------------- Widgets -------------------//

  Widget totalItemsCountCard(InventoryLoaded state) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'إجمالي المنتجات',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Text(
                '${state.globalProductCount}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () => context.push('/products/all'),
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: Colors.blue.shade50,
            ),
            child: const Text('عرض الكل'),
          ),
        ],
      ),
    );
  }

  //-------------------- Widget -------------------//
  Widget categoryGrid(InventoryLoaded state) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.5,
      ),
      delegate: SliverChildBuilderDelegate((context, index) {
        final category = state.categories[index];
        final color = category.color != null
            ? Color(category.color!)
            : KlistCategoryColors[index % KlistCategoryColors.length];

        return InkWell(
          onTap: () => context.push('/products/${category.id}'),
          onLongPress: () => _deleteCategory(category),
          child: Container(
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: color.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  category.name,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white60,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${category.productCount} منتج',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        );
      }, childCount: state.categories.length),
    );
  }
}
