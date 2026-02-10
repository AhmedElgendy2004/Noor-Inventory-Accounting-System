import 'package:al_noor_gallery/core/constants/constants.dart';
import 'package:al_noor_gallery/features/inventory/ui/widget/custom_floating_action_button.dart';
import 'package:al_noor_gallery/features/inventory/ui/widget/product_search_bar.dart';
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
    var scaffold = Scaffold(
      appBar: AppBar(
        title: const Text('المخزن'),
        actions: [
          // زر مؤقت للتوليد
          IconButton(
            icon: const Icon(Icons.playlist_add),
            tooltip: 'توليد بيانات اختبار',
            onPressed: _generateMockData,
          ),
        ],
      ),

      // زر الإضافة العائم يذهب لشاشة إضافة منتج مباشرةً
      floatingActionButton: CustomFloatingActionButton(),

      body: SafeArea(
        child: Column(
          children: [
            // شريط البحث الموحد
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ProductSearchBar(
                controller: _searchController,
                // عند الضغط على البحث في لوحة المعلومات، نذهب فوراً
                onChanged: (val) {},
                onSubmitted: (val) {
                  // الانتقال لصفحة البحث مع التركيز
                  context.push('/products/all?focus=true');
                },
                // نجعل الـ TextField مجرد زر للانتقال لصفحة البحث
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
                  }
                  if (state is InventoryLoaded) {
                    return _buildCategoryGrid(state);
                  }
                  if (state is InventoryError) {
                    return CustomErrorScreen(
                      message: "",
                      onRetry: () =>
                          context.read<InventoryCubit>().loadInitialData(),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
    );
    return scaffold;
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // بطاقة إجمالي المنتجات
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(5),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'إجمالي المنتجات في المخزن',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${state.globalProductCount}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

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
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                ),
              ),
            ),

            // زر إضافة تصنيف جديد
            const SizedBox(height: 10),

            // شبكة التصنيفات
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 1.1,
              ),
              itemCount: state.categories.length,
              itemBuilder: (context, index) {
                final category = state.categories[index];
                final color = category.color != null
                    ? Color(category.color!)
                    : KlistCategoryColors[index % KlistCategoryColors.length];

                return InkWell(
                  onTap: () {
                    context.push('/products/${category.id}');
                  },
                  onLongPress: () => _deleteCategory(category),
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${category.productCount} منتج',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: SizedBox(
                width: 170,
                height: 100,
                child: OutlinedButton.icon(
                  onPressed: () => _showAddCategoryDialog(context),
                  icon: const Icon(Icons.add_circle_outline, size: 35),
                  label: const Text(
                    ' تصنيف جديد',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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
