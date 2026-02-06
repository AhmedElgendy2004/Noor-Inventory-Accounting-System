import 'package:al_noor_gallery/core/constants/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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
  // لا نحتاج للبحث هنا إذا كان في شاشة المنتجات، لكن المستخدم قد يرغب بالبحث العام
  // سنقوم، عند البحث، بالانتقال لشاشة "كل المنتجات" مع تمرير نص البحث
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryCubit>().loadInitialData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
                onPressed: () {
                  final name = categoryController.text.trim();
                  if (name.isNotEmpty) {
                    context
                        .read<InventoryCubit>()
                        .addNewCategory(name, selectedColor.value)
                        .then((_) {
                          context.pop();
                          SnackBarUtils.showSuccess(
                            context,
                            'تمت إضافة التصنيف بنجاح',
                          );
                        })
                        .catchError((e) {
                          context.pop();
                          SnackBarUtils.showError(context, 'فشل الإضافة');
                        });
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
      appBar: AppBar(title: const Text('المخزن')),

      // زر الإضافة العائم يذهب لشاشة إضافة منتج مباشرةً
      floatingActionButton: FloatingActionButton.large(
        onPressed: () {
          context.push('/add-product');
        },
        child: const Text(
          "   اضافه\nمنتج جديد",
          style: TextStyle(fontWeight: .bold),
        ),
      ),

      body: SafeArea(
        child: Column(
          children: [
            // شريط البحث العام (عند كتابة أي شيء والضغط يمكن الذهاب لمنتجات عامة)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'بحث عن منتج (اسم أو باركود)',
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    // الانتقال لشاشة المنتجات (الكل) مع تصفية لاحقة (يمكنك تحسين ذلك بتمرير queryParams)
                    // هنا سننتقل لشاشة categoryId='all' ثم هناك نقوم بالبحث
                    // لكن ال Cubit مشترك، لذا يمكننا عمل التالي:
                    context.read<InventoryCubit>().fetchProducts(query: value);
                    context.push('/products/all');
                    _searchController.clear();
                  }
                },
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
                  }
                  if (state is InventoryLoaded) {
                    return _buildCategoryGrid(state);
                  }
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
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
            // زر "كل المنتجات"
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
                  context.push('/products/all');
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

            // زر إضافة تصنيف جديد
            const SizedBox(height: 20),

            // شبكة التصنيفات
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
                final color = category.color != null
                    ? Color(category.color!)
                    : KlistCategoryColors[index % KlistCategoryColors.length];

                return InkWell(
                  onTap: () {
                    // الانتقال لشاشة المنتجات الخاصة بهذا التصنيف
                    context.push('/products/${category.id}');
                  },
                  onLongPress: () => _deleteCategory(category),
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
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: SizedBox(
                width: 180,
                height: 100,
                child: OutlinedButton.icon(
                  onPressed: () => _showAddCategoryDialog(context),
                  icon: const Icon(Icons.add_circle_outline, size: 30),
                  label: const Text(
                    ' تصنيف جديد',
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
          ],
        ),
      ),
    );
  }
}
