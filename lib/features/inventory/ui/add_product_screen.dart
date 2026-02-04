import 'package:al_noor_gallery/core/constants/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../data/models/product_model.dart';
import '../logic/inventory_cubit.dart';
import '../logic/inventory_state.dart';
import 'widget/product_form_content.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({Key? key}) : super(key: key);

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
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

  late final Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
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
    };
  }

  bool _isScanning = false;
  DateTime? _selectedExpiryDate;

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // دالة اختيار التاريخ (سنة وشهر فقط - عربي)
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

  void _clearForm() {
    for (var c in _controllers.values) {
      c.clear();
    }
    _controllers['minStock']!.text = kDefaultMinStock;
    _controllers['expiryAlert']!.text = kDefaultExpiryAlert;
    setState(() {
      _selectedExpiryDate = null;
      _isScanning = false;
    });
  }

  void _handleAdd(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      final product = ProductModel(
        name: _controllers['name']!.text,
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
      body: BlocConsumer<InventoryCubit, InventoryState>(
        listener: (context, state) {
          if (state is InventorySuccess) {
            SnackBarUtils.showSuccess(context, 'تمت الإضافة بنجاح');
            _clearForm();
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
            saveButtonText: 'حفظ المنتج',
            onToggleScanner: () => setState(() => _isScanning = !_isScanning),
            onBarcodeDetected: (code) {
              setState(() {
                _controllers['barcode']!.text = code;
                _isScanning = false;
              });
            },
            onPickDate: _pickDate,
            onSave: () => _handleAdd(context),
          );
        },
      ),
    );
  }
}
