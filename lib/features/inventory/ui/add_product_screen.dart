import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/date_picker_utils.dart';
import '../../../core/constants/constants.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/category_model.dart';
import '../logic/inventory_cubit.dart';
import '../logic/inventory_state.dart';
import 'widget/product_form_content.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  late final Map<String, TextEditingController> _controllers;
  String? _selectedCategoryId;

  // متغيرات الصلاحية
  bool _isCalculatedExpiryMode = false;
  DateTime? _productionDate;
  
  // متغيرات الباركود والتاريخ
  bool _isScanning = false;
  DateTime? _selectedExpiryDate;

  @override
  void initState() {
    super.initState();
    context.read<InventoryCubit>().loadCategories(); // تحميل التصنيفات

    _controllers = {
      'name': TextEditingController(),
      'barcode': TextEditingController(),
      'brand': TextEditingController(),
      'stock': TextEditingController(),
      'minStock': TextEditingController(text: kDefaultMinStock),
      'purchasePrice': TextEditingController(),
      'retailPrice': TextEditingController(),
      'wholesalePrice': TextEditingController(),
      'expiryDate': TextEditingController(),
      'expiryAlert': TextEditingController(text: kDefaultExpiryAlert),
      'productionDate': TextEditingController(),
      'validityMonths': TextEditingController(),
    };

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

  // ✅ دالة الحساب (تم التعديل لاستخدام Utils)
  void _calculateExpiryDate() {
    if (!_isCalculatedExpiryMode || _productionDate == null) return;

    final monthsStr = _controllers['validityMonths']!.text;
    final months = int.tryParse(monthsStr);

    if (months != null && months > 0) {
      // حساب التاريخ باستخدام الـ Utility Class
      final newDate = DatePickerUtils.calculateExpiryDate(
        productionDate: _productionDate!,
        validityMonths: months,
      );

      setState(() {
        _selectedExpiryDate = newDate;
        // تنسيق النص باستخدام الـ Utility Class
        _controllers['expiryDate']!.text = DatePickerUtils.formatDateToArabic(newDate);
      });
    }
  }

  // ✅ اختيار تاريخ الانتهاء المباشر (تم التعديل لاستخدام Utils)
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
          _controllers['expiryDate']!.text = DatePickerUtils.formatDateToArabic(date);
        });
      },
    );
  }

  // ✅ اختيار تاريخ الإنتاج (تم التعديل لاستخدام Utils)
  Future<void> _pickProductionDate() async {
    final now = DateTime.now();

    await DatePickerUtils.showMonthYearPicker(
      context,
      initialDate: _productionDate,
      startYear: now.year - 10,
      endYear: now.year, // الإنتاج لا يتعدى السنة الحالية
      onConfirm: (date) {
        setState(() {
          _productionDate = date;
          _controllers['productionDate']!.text = DatePickerUtils.formatDateToArabic(date);
          
          // تحديث تاريخ الانتهاء تلقائياً لو فيه شهور مكتوبة
          _calculateExpiryDate();
        });
      },
    );
  }

  void _clearForm() {
    for (var c in _controllers.values) {
      c.clear();
    }
    _controllers['minStock']!.text = kDefaultMinStock;
    _controllers['expiryAlert']!.text = kDefaultExpiryAlert;
    setState(() {
      _selectedExpiryDate = null;
      _productionDate = null;
      _isScanning = false;
      _selectedCategoryId = null;
    });
  }

  // عرض نافذة إضافة تصنيف
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
                      // ✅ تم إصلاح مقارنة الألوان هنا أيضاً
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
                              ? const Icon(Icons.check, color: Colors.blueAccent)
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
                        .addNewCategory(name, selectedColor.value) // هنا بنبعت الـ int
                        .then((_) {
                          if (!context.mounted) return; // ✅ الحماية من Async Gap
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

  void _handleAdd(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      final product = ProductModel(
        // تسجيل تاريخ الشراء تلقائياً
        lastPurchaseDate: DateTime.now(),
        
        name: _controllers['name']!.text,
        categoryId: _selectedCategoryId,
        barcode: _controllers['barcode']!.text,
        brandCompany: _controllers['brand']!.text.isEmpty
            ? null
            : _controllers['brand']!.text,
        unit: 'piece',
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

      context.read<InventoryCubit>().addProduct(product);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إضافة منتج جديد')),
      body: SafeArea(
        child: BlocConsumer<InventoryCubit, InventoryState>(
          listener: (context, state) {
            if (state is InventorySuccess) {
              SnackBarUtils.showSuccess(context, 'تمت الإضافة بنجاح');
              _clearForm();
            } else if (state is InventoryError) {
              SnackBarUtils.showError(context, 'فشل الإضافة');
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

            return ProductFormContent(
              formKey: _formKey,
              controllers: _controllers,
              isScanning: _isScanning,
              saveButtonText: 'حفظ المنتج',
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
                  // تصفير التواريخ لتجنب الخلط
                  _selectedExpiryDate = null;
                  _controllers['expiryDate']!.clear();
                  if (!val) {
                    _productionDate = null;
                    _controllers['productionDate']!.clear();
                    _controllers['validityMonths']!.clear();
                  }
                });
              },
              // ✅ هنا تم الربط بالدوال المعدلة
              onPickProductionDate: _pickProductionDate,
              onToggleScanner: () => setState(() => _isScanning = !_isScanning),
              onBarcodeDetected: (code) {
                setState(() {
                  _controllers['barcode']!.text = code;
                  _isScanning = false;
                });
              },
              // ✅ وهنا كمان
              onPickDate: _pickDate,
              onSave: () => _handleAdd(context),
            );
          },
        ),
      ),
    );
  }
}