import 'package:al_noor_gallery/data/models/category_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../data/models/product_model.dart';
import '../logic/inventory_cubit.dart';
import '../logic/inventory_state.dart';
import 'widget/product_form_content.dart';

class EditProductScreen extends StatefulWidget {
  // هذا المتغير إلزامي لأننا في شاشة تعديل
  final ProductModel product;
  const EditProductScreen({Key? key, required this.product}) : super(key: key);

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();

  // قائمة الشهور العربية
  final List<String> _arabicMonths = [
    "يناير",
    "فبراير",
    "مارس",
    "أبريل",
    "مايو",
    "يونيو",
    "يوليو",
    "أغسطس",
    "سبتمبر",
    "أكتوبر",
    "نوفمبر",
    "ديسمبر",
  ];

  // تهيئة الكنترولرز
  late final Map<String, TextEditingController> _controllers;
  bool _isScanning = false;
  DateTime? _selectedExpiryDate;
  String? _selectedCategoryId;

  // متغيرات الصلاحية
  bool _isCalculatedExpiryMode = false;
  DateTime? _productionDate;

  // دالة مساعدة لتحويل DateTime لنص عربي
  String _formatDateToArabic(DateTime date) {
    return "${_arabicMonths[date.month - 1]} ${date.year}";
  }

  @override
  void initState() {
    super.initState();
    // تحميل التصنيفات للتأكد من وجودها
    context.read<InventoryCubit>().loadCategories();
    _initControllers();

    // الاستماع لتغيير مدة الصلاحية
    _controllers['validityMonths']!.addListener(_calculateExpiry);
  }

  void _calculateExpiry() {
    if (!_isCalculatedExpiryMode || _productionDate == null) return;

    final monthsStr = _controllers['validityMonths']!.text;
    final months = int.tryParse(monthsStr);

    if (months != null && months > 0) {
      final newDate = DateTime(
        _productionDate!.year,
        _productionDate!.month + months,
        _productionDate!.day,
      );

      setState(() {
        _selectedExpiryDate = newDate;
        _controllers['expiryDate']!.text = _formatDateToArabic(newDate);
      });
    }
  }

  // تعبئة البيانات من المنتج الموجود
  void _initControllers() {
    final p = widget.product;
    _selectedExpiryDate = p.expiryDate;
    _selectedCategoryId = p.categoryId;

    _controllers = {
      'name': TextEditingController(text: p.name),
      'barcode': TextEditingController(text: p.barcode),
      'brand': TextEditingController(text: p.brandCompany ?? ''),
      'stock': TextEditingController(text: p.stockQuantity.toString()),
      'minStock': TextEditingController(text: p.minStockLevel.toString()),
      'purchasePrice': TextEditingController(text: p.purchasePrice.toString()),
      'retailPrice': TextEditingController(text: p.retailPrice.toString()),
      'wholesalePrice': TextEditingController(
        text: p.wholesalePrice.toString(),
      ),
      'expiryAlert': TextEditingController(
        text: p.expiryAlertDays?.toString() ?? '',
      ),
      'expiryDate': TextEditingController(
        text: p.expiryDate != null
            ? _formatDateToArabic(p.expiryDate!) // استخدام الصيغة العربية
            : '',
      ),
      'productionDate': TextEditingController(),
      'validityMonths': TextEditingController(),
    };
  }

  @override
  void dispose() {
    _controllers['validityMonths']!.removeListener(_calculateExpiry);
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // استخدمنا الدالة العامة التي أضفناها في AddProductScreen كمرجع، ولكن هنا سنعيد كتابتها للتسهيل
  // يمكن نقلها لملف utils لاحقاً
  Future<void> _pickDateGeneral(
    DateTime? initialDate,
    Function(DateTime) onConfirm, {
    required int startYear,
    required int endYear,
  }) async {
    final now = DateTime.now();
    int selectedMonth = initialDate?.month ?? now.month;
    int selectedYear = initialDate?.year ?? now.year;

    // التأكد من أن السنة المختارة تقع ضمن النطاق
    if (selectedYear < startYear) selectedYear = startYear;
    if (selectedYear > endYear) selectedYear = endYear;

    // توليد قائمة السنين بناءً على الحدود المرسلة
    final int count = endYear - startYear + 1;
    final List<int> years = List.generate(count, (index) => startYear + index);

    await showModalBottomSheet(
      context: context,
      builder: (BuildContext builder) {
        return Container(
          height: 300,
          color: Colors.white,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: Colors.grey[100],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'إلغاء',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                    const Text(
                      'اختر التاريخ (عربي)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () {
                        onConfirm(DateTime(selectedYear, selectedMonth));
                        Navigator.pop(context);
                      },
                      child: const Text('تم'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(
                          initialItem: selectedMonth - 1,
                        ),
                        itemExtent: 40,
                        onSelectedItemChanged: (int index) =>
                            selectedMonth = index + 1,
                        children: _arabicMonths
                            .map((month) => Center(child: Text(month)))
                            .toList(),
                      ),
                    ),
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(
                          initialItem: years.indexOf(selectedYear) != -1
                              ? years.indexOf(selectedYear)
                              : 0,
                        ),
                        itemExtent: 40,
                        onSelectedItemChanged: (int index) =>
                            selectedYear = years[index],
                        children: years
                            .map((year) => Center(child: Text(year.toString())))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    await _pickDateGeneral(
      _selectedExpiryDate,
      (date) {
        setState(() {
          _selectedExpiryDate = date;
          _controllers['expiryDate']!.text = _formatDateToArabic(date);
        });
      },
      startYear: now.year,
      endYear: now.year + 10,
    );
  }

  Future<void> _pickProductionDate() async {
    final now = DateTime.now();
    await _pickDateGeneral(
      _productionDate,
      (date) {
        setState(() {
          _productionDate = date;
          _controllers['productionDate']!.text = _formatDateToArabic(date);
          _calculateExpiry();
        });
      },
      startYear: now.year - 20,
      endYear: now.year,
    );
  }

  // عرض نافذة إضافة تصنيف
  void _showAddCategoryDialog(BuildContext context) {
    final TextEditingController _categoryController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة تصنيف جديد'),
        content: TextField(
          controller: _categoryController,
          decoration: const InputDecoration(
            labelText: 'اسم التصنيف',
            hintText: 'مثال: مستحضرات تجميل',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = _categoryController.text.trim();
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
                      // SnackBarUtils.showError(context, 'فشل الإضافة: $e');
                      SnackBarUtils.showError(context, 'فشل الإضافة');
                    });
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  // دالة الحفظ الخاصة بالتعديل
  void _handleUpdate(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      // الحفاظ على البيانات القديمة غير الظاهرة في الفورم
      final updatedProduct = ProductModel(
        id: widget.product.id, // مهم جداً للتحديث
        supplierId: widget.product.supplierId, // الحفاظ على المورد
        lastPurchaseDate:
            widget.product.lastPurchaseDate, // الحفاظ على تاريخ الشراء
        unit: widget.product.unit, // الحفاظ على الوحدة
        categoryId: _selectedCategoryId,
        // البيانات المعدلة
        name: _controllers['name']!.text,
        barcode: _controllers['barcode']!.text,
        brandCompany: _controllers['brand']!.text.isEmpty
            ? null
            : _controllers['brand']!.text,

        stockQuantity: int.tryParse(_controllers['stock']!.text) ?? 0,
        minStockLevel: int.tryParse(_controllers['minStock']!.text) ?? 0,
        purchasePrice:
            double.tryParse(_controllers['purchasePrice']!.text) ?? 0.0,
        retailPrice: double.tryParse(_controllers['retailPrice']!.text) ?? 0.0,
        wholesalePrice:
            double.tryParse(_controllers['wholesalePrice']!.text) ?? 0.0,
        expiryAlertDays: int.tryParse(_controllers['expiryAlert']!.text),
        expiryDate: _selectedExpiryDate,
      );

      // استدعاء دالة التحديث
      context.read<InventoryCubit>().updateProduct(updatedProduct);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تعديل المنتج')),
      body: BlocConsumer<InventoryCubit, InventoryState>(
        listener: (context, state) {
          if (state is InventorySuccess) {
            SnackBarUtils.showSuccess(context, 'تم تعديل المنتج بنجاح');

            // إغلاق الشاشة فوراً عند النجاح كما طلبت
            if (mounted) {
              Navigator.pop(context);
            }
          } else if (state is InventoryError) {
            // SnackBarUtils.showError(context, state.message);
            SnackBarUtils.showError(context, 'فشل التعديل');
          }
        },
        builder: (context, state) {
          if (state is InventoryLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // استخدام الـ Widget المشتركة
          List<CategoryModel> categories = [];
          if (state is InventoryLoaded) {
            categories = state.categories;
          }

          return RefreshIndicator(
            onRefresh: () async {
              await context.read<InventoryCubit>().loadCategories();
            },
            child: ProductFormContent(
              formKey: _formKey,
              controllers: _controllers,
              isScanning: _isScanning,
              saveButtonText: 'حفظ التعديلات',
              categories: categories,
              selectedCategoryId: _selectedCategoryId,
              onCategoryChanged: (val) {
                setState(() {
                  _selectedCategoryId = val;
                });
              },
              onAddCategory: () => _showAddCategoryDialog(context),
              isCalculatedExpiryMode: _isCalculatedExpiryMode,
              onExpiryModeChanged: (val) {
                setState(() {
                  _isCalculatedExpiryMode = val;
                  if (!val) {
                    _productionDate = null;
                    _controllers['productionDate']!.clear();
                    _controllers['validityMonths']!.clear();
                  }
                });
              },
              onPickProductionDate: _pickProductionDate,
              onToggleScanner: () => setState(() => _isScanning = !_isScanning),
              onBarcodeDetected: (code) {
                setState(() {
                  _controllers['barcode']!.text = code;
                  _isScanning = false;
                });
              },
              onPickDate: _pickDate,
              onSave: () => _handleUpdate(context),
            ),
          );
        },
      ),
    );
  }
}
