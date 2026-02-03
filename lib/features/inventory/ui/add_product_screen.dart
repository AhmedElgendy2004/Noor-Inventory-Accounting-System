import 'package:al_noor_gallery/features/inventory/ui/widget/custom_text_field.dart';
import 'package:al_noor_gallery/features/inventory/ui/widget/form_sections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/inline_barcode_scanner.dart';
import '../../../data/models/product_model.dart';
import '../logic/inventory_cubit.dart';
import '../logic/inventory_state.dart';

class AddProductScreen extends StatefulWidget {
  final ProductModel? productToEdit;
  const AddProductScreen({Key? key, this.productToEdit}) : super(key: key);

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  // خدعة برمجية: تجميع كل الكنترولرز في Map لسهولة الإدارة
  final Map<String, TextEditingController> _controllers = {
    'name': TextEditingController(),
    'barcode': TextEditingController(),
    'brand': TextEditingController(),
    'size': TextEditingController(),
    'color': TextEditingController(),
    'stock': TextEditingController(),
    'minStock': TextEditingController(), // ده اللي كان عامل مشكلة معاك
    'purchasePrice': TextEditingController(),
    'retailPrice': TextEditingController(),
    'wholesalePrice': TextEditingController(),
    'expiryDate': TextEditingController(),
    'expiryAlert': TextEditingController(),
  };

  bool _isScanning = false;
  DateTime? _selectedExpiryDate;

  @override
  void initState() {
    super.initState();
    if (widget.productToEdit != null) {
      _fillFormForEdit();
    }
  }

  // دالة لتعبئة البيانات عند التعديل
  void _fillFormForEdit() {
    final p = widget.productToEdit!;
    _controllers['name']!.text = p.name;
    _controllers['barcode']!.text = p.barcode;
    _controllers['brand']!.text = p.brandCompany ?? '';
    _controllers['size']!.text = p.sizeVolume ?? '';
    _controllers['color']!.text = p.color ?? '';
    _controllers['stock']!.text = p.stockQuantity.toString();
    _controllers['minStock']!.text = p.minStockLevel.toString();
    _controllers['purchasePrice']!.text = p.purchasePrice.toString();
    _controllers['retailPrice']!.text = p.retailPrice.toString();
    _controllers['wholesalePrice']!.text = p.wholesalePrice.toString();
    _controllers['expiryAlert']!.text = p.expiryAlertDays?.toString() ?? '';

    if (p.expiryDate != null) {
      _selectedExpiryDate = p.expiryDate;
      _controllers['expiryDate']!.text = p.expiryDate!.toIso8601String().split(
        'T',
      )[0];
    }
  }

  @override
  void dispose() {
    // إغلاق جميع الكنترولرز بلمسة واحدة
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.productToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'تعديل المنتج' : 'إضافة منتج جديد'),
      ),
      body: BlocConsumer<InventoryCubit, InventoryState>(
        listener: (context, state) {
          if (state is InventorySuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            if (!isEditing) {
              _clearForm();
            } else {
              Navigator.pop(context);
            }
          } else if (state is InventoryError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is InventoryLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // 1. البيانات الأساسية
                  const SectionTitle('البيانات الأساسية'),
                  CustomTextField(
                    controller: _controllers['name']!,
                    label: 'اسم المنتج',
                    isRequired: true,
                  ),

                  // Scanner Widget
                  if (_isScanning)
                    InlineBarcodeScanner(
                      onBarcodeDetected: (code) {
                        setState(() {
                          _controllers['barcode']!.text = code;
                          _isScanning = false;
                        });
                      },
                      onClose: () => setState(() => _isScanning = false),
                    ),

                  CustomTextField(
                    controller: _controllers['barcode']!,
                    label: 'الباركود',
                    icon: Icons.qr_code,
                    isRequired: true,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isScanning ? Icons.stop_circle : Icons.qr_code_scanner,
                      ),
                      color: _isScanning ? Colors.red : null,
                      onPressed: () {
                        setState(() {
                          _isScanning = !_isScanning;
                        });
                      },
                    ),
                  ),

                  CustomTextField(
                    controller: _controllers['brand']!,
                    label: 'الشركة المصنعة',
                  ),

                  // 2. الأسعار
                  const SectionTitle('الأسعار'),
                  RowFields(
                    field1: CustomTextField(
                      controller: _controllers['purchasePrice']!,
                      label: 'شراء',
                      isNumber: true,
                      isRequired: true,
                    ),
                    field2: CustomTextField(
                      controller: _controllers['retailPrice']!,
                      label: 'قطاعي',
                      isNumber: true,
                      isRequired: true,
                    ),
                  ),
                  CustomTextField(
                    controller: _controllers['wholesalePrice']!,
                    label: 'سعر الجملة',
                    isNumber: true,
                  ),

                  // 3. المخزن
                  const SectionTitle('المخزن'),
                  RowFields(
                    field1: CustomTextField(
                      controller: _controllers['stock']!,
                      label: 'الكمية',
                      isNumber: true,
                      isRequired: true,
                    ),
                    field2: CustomTextField(
                      controller: _controllers['minStock']!,
                      label: 'الحد الأدنى',
                      isNumber: true,
                    ),
                  ),

                  // 4. الخصائص والصلاحية
                  const SectionTitle('تفاصيل إضافية'),
                  RowFields(
                    field1: CustomTextField(
                      controller: _controllers['size']!,
                      label: 'الحجم/الوزن',
                    ),
                    field2: CustomTextField(
                      controller: _controllers['color']!,
                      label: 'اللون',
                    ),
                  ),
                  CustomTextField(
                    controller: _controllers['expiryDate']!,
                    label: 'تاريخ الصلاحية',
                    icon: Icons.calendar_today,
                    readOnly: true,
                    onTap: () => _pickDate(context),
                  ),
                  CustomTextField(
                    controller: _controllers['expiryAlert']!,
                    label: 'أيام التنبيه',
                    isNumber: true,
                  ),

                  const SizedBox(height: 20),
                  // زر الحفظ
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => _handleSave(context),
                      child: Text(
                        isEditing ? 'حفظ التعديلات' : 'حفظ المنتج',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- Logic Functions ---

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _selectedExpiryDate = picked;
        _controllers['expiryDate']!.text = picked.toIso8601String().split(
          'T',
        )[0];
      });
    }
  }

  void _handleSave(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      final product = ProductModel(
        id: widget.productToEdit?.id,
        name: _controllers['name']!.text,
        barcode: _controllers['barcode']!.text,
        brandCompany: _controllers['brand']!.text.isEmpty
            ? null
            : _controllers['brand']!.text,
        sizeVolume: _controllers['size']!.text.isEmpty
            ? null
            : _controllers['size']!.text,
        color: _controllers['color']!.text.isEmpty
            ? null
            : _controllers['color']!.text,

        // تحويل الأرقام بأمان
        stockQuantity: int.tryParse(_controllers['stock']!.text) ?? 0,
        minStockLevel:
            int.tryParse(_controllers['minStock']!.text) ??
            0, // تم الحل: يقرأ من الكنترولر
        purchasePrice:
            double.tryParse(_controllers['purchasePrice']!.text) ?? 0.0,
        retailPrice: double.tryParse(_controllers['retailPrice']!.text) ?? 0.0,
        wholesalePrice:
            double.tryParse(_controllers['wholesalePrice']!.text) ?? 0.0,
        expiryAlertDays: int.tryParse(_controllers['expiryAlert']!.text),
        expiryDate: _selectedExpiryDate,
      );

      if (widget.productToEdit != null) {
        context.read<InventoryCubit>().updateProduct(product);
      } else {
        context.read<InventoryCubit>().addProduct(product);
      }
    }
  }

  void _clearForm() {
    // تنظيف كل الحقول بلمسة واحدة
    for (var c in _controllers.values) c.clear();
    setState(() {
      _selectedExpiryDate = null;
    });
  }
}
