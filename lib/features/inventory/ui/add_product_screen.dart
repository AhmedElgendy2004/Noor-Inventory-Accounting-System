import 'package:al_noor_gallery/features/inventory/ui/widget/custom_text_field.dart';
import 'package:al_noor_gallery/features/inventory/ui/widget/form_sections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/inline_barcode_scanner.dart';
import '../../../data/models/product_model.dart';
import '../logic/inventory_cubit.dart';
import '../logic/inventory_state.dart';

import '../../../core/utils/snackbar_utils.dart'; // Add import

// كلاس مساعد لإدارة كنترولرز كل سطر عرض
class PricingTierDraft {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  void dispose() {
    nameController.dispose();
    quantityController.dispose();
    priceController.dispose();
  }
}

class AddProductScreen extends StatefulWidget {
  final ProductModel? productToEdit;
  const AddProductScreen({super.key, this.productToEdit});

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
    'stock': TextEditingController(),
    'minStock': TextEditingController(), // ده اللي كان عامل مشكلة معاك
    'purchasePrice': TextEditingController(),
    'retailPrice': TextEditingController(),
    'wholesalePrice': TextEditingController(),
    'expiryDate': TextEditingController(),
    'expiryAlert':
        TextEditingController(), // Fixed: removed Context typo from original file
  };

  bool _isScanning = false;
  DateTime? _selectedExpiryDate;

  // متغيرات العروض (Pricing Tiers)
  bool _hasOffers = false;
  final List<PricingTierDraft> _pricingTiers = [];

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
    // تنظيف كنترولرز العروض
    for (var tier in _pricingTiers) {
      tier.dispose();
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
            SnackBarUtils.showSuccess(context, state.message);
            if (!isEditing) {
              _clearForm();
            } else {
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

                  // 5. عروض الكميات (Pricing Tiers)
                  const SizedBox(height: 20),
                  const Divider(thickness: 2),
                  const SectionTitle('عروض الكميات'),

                  // Switch لتفعيل العروض
                  SwitchListTile(
                    title: const Text('هل يوجد عروض جملة/كميات لهذا المنتج؟'),
                    value: _hasOffers,
                    onChanged: (val) {
                      setState(() {
                        _hasOffers = val;
                        // إضافة سطر تلقائي عند التفعيل إذا كانت القائمة فارغة
                        if (val && _pricingTiers.isEmpty) {
                          _pricingTiers.add(PricingTierDraft());
                        }
                      });
                    },
                  ),

                  if (_hasOffers) ...[
                    // قائمة العروض
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _pricingTiers.length,
                      itemBuilder: (context, index) {
                        return _buildPricingTierRow(index);
                      },
                    ),

                    const SizedBox(height: 10),
                    // زر إضافة عرض جديد
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _pricingTiers.add(PricingTierDraft());
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('إضافة عرض جديد'),
                    ),
                  ],

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

  // --- Widgets for Pricing Tiers ---
  Widget _buildPricingTierRow(int index) {
    final tier = _pricingTiers[index];
    return Card(
      key: ObjectKey(tier), // للحفاظ على البيانات عند الحذف
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'عرض ${index + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    // منع حذف آخر صف إذا كان هو الوحيد
                    if (_pricingTiers.length == 1) {
                      SnackBarUtils.showError(
                        context,
                        'يجب أن يحتوي العرض على صف واحد على الأقل أو قم بإلغاء التفعيل',
                      );
                      return;
                    }
                    setState(() {
                      tier.dispose();
                      _pricingTiers.removeAt(index);
                    });
                  },
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: tier.nameController,
                    decoration: const InputDecoration(
                      labelText: 'اسم العرض (اختياري)',
                      hintText: 'مثال: عرض كرتونة',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: tier.quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'الكمية (min)*',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                    ),
                    validator: (val) =>
                        (val == null || val.isEmpty) ? 'مطلوب' : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: tier.priceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'السعر الكلي*',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                    ),
                    validator: (val) =>
                        (val == null || val.isEmpty) ? 'مطلوب' : null,
                  ),
                ),
              ],
            ),
          ],
        ),
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
      // التحقق الإضافي من العروض
      if (_hasOffers) {
        if (_pricingTiers.isEmpty) {
          SnackBarUtils.showError(context, 'يجب إضافة عرض واحد على الأقل');
          return;
        }
        // يمكن إضافة تحقق إضافي هنا إن لزم الأمر
      }

      final product = ProductModel(
        id: widget.productToEdit?.id,
        name: _controllers['name']!.text,
        barcode: _controllers['barcode']!.text,
        brandCompany: _controllers['brand']!.text.isEmpty
            ? null
            : _controllers['brand']!.text,

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

      // تجهيز بيانات العروض
      final List<Map<String, dynamic>> pricingTiersData = [];
      if (_hasOffers) {
        for (var tier in _pricingTiers) {
          pricingTiersData.add({
            'tier_name': tier.nameController.text.isEmpty
                ? 'عرض كمية'
                : tier.nameController.text,
            'min_quantity': int.parse(tier.quantityController.text),
            'total_price': double.parse(tier.priceController.text),
            // سيتم إضافة product_id في الـ Cubit بعد حفظ المنتج
          });
        }
      }

      if (widget.productToEdit != null) {
        // في حالة التعديل، سنحتاج لتحديث المنطق في الـ Service/Cubit لدعم تحديث العروض أيضاً
        // (ملاحظة: الكود الحالي للـ Cubit لا يدعم تحديث Tiers في updateProduct،
        // يمكن تمريرها أيضاً إذا أردت تحديثها، لكن الطلب يركز على الإضافة حالياً)
        context.read<InventoryCubit>().updateProduct(product);
      } else {
        context.read<InventoryCubit>().addProduct(
          product,
          pricingTiers: pricingTiersData,
        );
        // Note: تم تحديث استدعاء الدالة لتمرير العروض
      }
    }
  }

  void _clearForm() {
    // تنظيف كل الحقول بلمسة واحدة
    for (var c in _controllers.values) {
      c.clear();
    }

    // تنظيف العروض
    for (var tier in _pricingTiers) {
      tier.dispose();
    }
    _pricingTiers.clear();

    setState(() {
      _selectedExpiryDate = null;
      _hasOffers = false;
      _isScanning = false;
    });
  }
}
