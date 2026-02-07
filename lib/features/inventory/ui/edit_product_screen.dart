import 'package:al_noor_gallery/data/models/category_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/date_picker_utils.dart';
import '../../../core/constants/constants.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../data/models/product_model.dart';
import '../logic/inventory_cubit.dart';
import '../logic/inventory_state.dart';
import 'widget/product_form_content.dart';

class EditProductScreen extends StatefulWidget {
  // هذا المتغير إلزامي لأننا في شاشة تعديل
  final ProductModel product;
  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();

  late final Map<String, TextEditingController> _controllers;
  String? _selectedCategoryId;

  // متغيرات الباركود والتاريخ
  bool _isScanning = false;
  DateTime? _selectedExpiryDate;

  // متغيرات الصلاحية
  bool _isCalculatedExpiryMode = false;
  DateTime? _productionDate;

  @override
  void initState() {
    super.initState();
    // تحميل التصنيفات للتأكد من وجودها
    context.read<InventoryCubit>().loadCategories();
    _initControllers();

    // الاستماع لتغيير مدة الصلاحية لحساب التاريخ تلقائياً
    _controllers['validityMonths']!.addListener(_calculateExpiryDate);
  }

  @override
  void dispose() {
    _controllers['validityMonths']?.removeListener(_calculateExpiryDate);
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
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
            ? DatePickerUtils.formatDateToArabic(p.expiryDate!)
            : '',
      ),
      'lastPurchaseDate': TextEditingController(
        text: p.lastPurchaseDate != null
            ? DatePickerUtils.formatDateToArabic(p.lastPurchaseDate!)
            : '',
      ),
      'productionDate': TextEditingController(),
      'validityMonths': TextEditingController(),
    };
  }

  // ✅ دالة الحساب (باستخدام Utils)
  void _calculateExpiryDate() {
    if (!_isCalculatedExpiryMode || _productionDate == null) return;

    final monthsStr = _controllers['validityMonths']!.text;
    final months = int.tryParse(monthsStr);

    if (months != null && months > 0) {
      final newDate = DatePickerUtils.calculateExpiryDate(
        productionDate: _productionDate!,
        validityMonths: months,
      );

      setState(() {
        _selectedExpiryDate = newDate;
        _controllers['expiryDate']!.text = DatePickerUtils.formatDateToArabic(
          newDate,
        );
      });
    }
  }

  // ✅ اختيار تاريخ الانتهاء المباشر (باستخدام Utils)
  Future<void> _pickDate() async {
    final now = DateTime.now();

    await DatePickerUtils.showMonthYearPicker(
      context,
      initialDate: _selectedExpiryDate,
      startYear: now.year,
      endYear: now.year + 10,
      onConfirm: (date) {
        setState(() {
          _selectedExpiryDate = date;
          _controllers['expiryDate']!.text = DatePickerUtils.formatDateToArabic(
            date,
          );
        });
      },
    );
  }

  // ✅ اختيار تاريخ الإنتاج (باستخدام Utils)
  Future<void> _pickProductionDate() async {
    final now = DateTime.now();

    await DatePickerUtils.showMonthYearPicker(
      context,
      initialDate: _productionDate,
      startYear: now.year - 10,
      endYear: now.year,
      onConfirm: (date) {
        setState(() {
          _productionDate = date;
          _controllers['productionDate']!.text =
              DatePickerUtils.formatDateToArabic(date);

          // تحديث تاريخ الانتهاء تلقائياً
          _calculateExpiryDate();
        });
      },
    );
  }

  // عرض نافذة إضافة تصنيف (مطابق لصفحة الإضافة)
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
                                  color: color.withOpacity(0.4),
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
                          if (!context.mounted) return;
                          context.pop();
                          SnackBarUtils.showSuccess(
                            context,
                            'تمت إضافة التصنيف بنجاح',
                          );
                        })
                        .catchError((e) {
                          if (!context.mounted) return;
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

  // دالة الحفظ الخاصة بالتعديل
  void _handleUpdate(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      // الحفاظ على البيانات القديمة غير الظاهرة في الفورم
      final updatedProduct = ProductModel(
        id: widget.product.id, // مهم جداً للتحديث
        supplierId: widget.product.supplierId, // الحفاظ على المورد
        lastPurchaseDate:
            widget.product.lastPurchaseDate, // الحفاظ على تاريخ الشراء القديم
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
      appBar: AppBar(
        title: const Text('تعديل المنتج'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<InventoryCubit, InventoryState>(
          listener: (context, state) {
            if (state is InventorySuccess) {
              SnackBarUtils.showSuccess(context, 'تم تعديل المنتج بنجاح');
              if (mounted) context.pop();
            } else if (state is InventoryError) {
              SnackBarUtils.showError(context, 'فشل التعديل');
            }
          },
          builder: (context, state) {
            if (state is InventoryLoading) {
              return const Center(child: CircularProgressIndicator());
            }

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
                    // تصفير التواريخ إذا تم الخروج من الوضع
                    if (!val) {
                      _productionDate = null;
                      _controllers['productionDate']!.clear();
                      _controllers['validityMonths']!.clear();
                      // لا نصفر تاريخ الانتهاء الموجود أصلاً لأنه قد يكون هو المطلوب
                    } else {
                      // إذا دخلنا الوضع، نصفر التواريخ للبدء من جديد
                      _selectedExpiryDate = null;
                      _controllers['expiryDate']!.clear();
                    }
                  });
                },
                onPickProductionDate: _pickProductionDate,
                onToggleScanner: () =>
                    setState(() => _isScanning = !_isScanning),
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
      ),
    );
  }
}
