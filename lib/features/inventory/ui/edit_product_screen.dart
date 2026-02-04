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

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  // تعبئة البيانات من المنتج الموجود
  void _initControllers() {
    final p = widget.product;
    _selectedExpiryDate = p.expiryDate;

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
            ? p.expiryDate!.toIso8601String().split('T')[0]
            : '',
      ),
    };
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    int selectedMonth = _selectedExpiryDate?.month ?? now.month;
    int selectedYear = _selectedExpiryDate?.year ?? now.year;

    // توليد قائمة سنين (السنة الحالية + 5)
    final List<int> years = List.generate(6, (index) => now.year + index);

    showModalBottomSheet(
      context: context,
      builder: (BuildContext builder) {
        return Container(
          height: 300,
          color: Colors.white,
          child: Column(
            children: [
              // شريط الأزرار
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
                        setState(() {
                          _selectedExpiryDate = DateTime(
                            selectedYear,
                            selectedMonth,
                          );
                          _controllers['expiryDate']!.text =
                              "${_arabicMonths[selectedMonth - 1]} $selectedYear";
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('تم'),
                    ),
                  ],
                ),
              ),
              // البكرات اليدوية (العربي)
              Expanded(
                child: Row(
                  children: [
                    // بكرة الشهور
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
                    // بكرة السنين
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(
                          initialItem: years.indexOf(selectedYear),
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
            SnackBarUtils.showError(context, state.message);
          }
        },
        builder: (context, state) {
          if (state is InventoryLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return ProductFormContent(
            formKey: _formKey,
            controllers: _controllers,
            isScanning: _isScanning,
            saveButtonText: 'حفظ التعديلات',
            onToggleScanner: () => setState(() => _isScanning = !_isScanning),
            onBarcodeDetected: (code) {
              setState(() {
                _controllers['barcode']!.text = code;
                _isScanning = false;
              });
            },
            onPickDate: _pickDate,
            onSave: () => _handleUpdate(context),
          );
        },
      ),
    );
  }
}
