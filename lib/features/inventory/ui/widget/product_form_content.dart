import 'package:flutter/material.dart';
import '../../../../core/utils/inline_barcode_scanner.dart';
import '../../../../data/models/category_model.dart';
import 'custom_text_field.dart';
import 'form_sections.dart';

// هذا الملف يحتوي على واجهة المستخدم للنموذج فقط (Stateless)
// الهدف: استخدامه في شاشتي الإضافة والتعديل لمنع تكرار كود التصميم
class ProductFormContent extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final Map<String, TextEditingController> controllers;

  // حالات التحكم في الواجهة
  final bool isScanning;
  final VoidCallback onToggleScanner;
  final ValueChanged<String> onBarcodeDetected;

  // دوال الإجراءات
  final VoidCallback onPickDate;
  final VoidCallback onSave;
  final String saveButtonText;

  // التصنيفات
  final List<CategoryModel> categories;
  final String? selectedCategoryId;
  final ValueChanged<String?> onCategoryChanged;
  final VoidCallback onAddCategory;

  // متغيرات الصلاحية الجديدة
  final bool isCalculatedExpiryMode;
  final ValueChanged<bool> onExpiryModeChanged;
  final VoidCallback onPickProductionDate;

  const ProductFormContent({
    super.key,
    required this.formKey,
    required this.controllers,
    required this.isScanning,
    required this.onToggleScanner,
    required this.onBarcodeDetected,
    required this.onPickDate,
    required this.onSave,
    required this.saveButtonText,
    this.categories = const [],
    this.selectedCategoryId,
    required this.onCategoryChanged,
    required this.onAddCategory,
    this.isCalculatedExpiryMode = false,
    required this.onExpiryModeChanged,
    required this.onPickProductionDate,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const Key('productFormScrollView'), // Added Key for Testing
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: formKey,
        child: Column(
          children: [
            // 1. قسم البيانات الأساسية
            const SectionTitle('البيانات الأساسية'),

            // عرض تاريخ الشراء (للقراءة فقط) إن وجد
            if (controllers.containsKey('lastPurchaseDate') &&
                controllers['lastPurchaseDate']!.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: CustomTextField(
                  controller: controllers['lastPurchaseDate']!,
                  label: 'آخر تاريخ شراء',
                  icon: Icons.history, // أيقونة معبرة أكثر
                  readOnly: true,
                ),
              ),

            CustomTextField(
              controller: controllers['name']!,
              label: 'اسم المنتج',
              isRequired: true,
            ),

            // ماسح الباركود يظهر فقط عند تفعيله
            if (isScanning)
              InlineBarcodeScanner(
                onBarcodeDetected: onBarcodeDetected,
                onClose: onToggleScanner,
              ),

            CustomTextField(
              controller: controllers['barcode']!,
              label: 'الباركود',
              icon: Icons.qr_code,
              isRequired: true,
              // inputFormatters: [
              //   FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
              // ],
              suffixIcon: IconButton(
                icon: Icon(
                  isScanning ? Icons.stop_circle : Icons.qr_code_scanner,
                ),
                color: isScanning ? Colors.red : null,
                onPressed: onToggleScanner,
              ),
            ),

            CustomTextField(
              controller: controllers['brand']!,
              label: 'الشركة المصنعة',
            ),

            // خانة التصنيف مع زر الإضافة
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: selectedCategoryId,
                      decoration: const InputDecoration(
                        labelText: 'التصنيف',
                        border: OutlineInputBorder(),
                        // prefixIcon: Icon(Icons.category),
                      ),
                      items: categories.map((cat) {
                        return DropdownMenuItem(
                          value: cat.id,
                          child: Text(cat.name),
                        );
                      }).toList(),
                      onChanged: onCategoryChanged,
                      validator: (value) =>
                          value == null ? 'يرجى اختيار تصنيف' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.add, color: Colors.white),
                      onPressed: onAddCategory,
                      tooltip: 'إضافة تصنيف جديد',
                    ),
                  ),
                ],
              ),
            ),

            // 2. قسم الأسعار
            const SectionTitle('الأسعار'),
            RowFields(
              field1: CustomTextField(
                controller: controllers['purchasePrice']!,
                label: 'سعر الشراء',
                isNumber: true,
                isRequired: true,
              ),
              field2: CustomTextField(
                controller: controllers['retailPrice']!,
                label: 'سعر القطاعي',
                isNumber: true,
                isRequired: true,
                validator: (val) {
                  final purchase =
                      double.tryParse(controllers['purchasePrice']!.text) ?? 0;
                  final retail = double.tryParse(val ?? '') ?? 0;
                  if (retail <= purchase) {
                    return 'يجب أن يكون أكبر من سعر الشراء';
                  }
                  return null;
                },
              ),
            ),
            CustomTextField(
              controller: controllers['wholesalePrice']!,
              label: 'سعر الجملة',
              isNumber: true,
              validator: (val) {
                if (val == null || val.isEmpty) return null;
                final purchase =
                    double.tryParse(controllers['purchasePrice']!.text) ?? 0;
                final retail =
                    double.tryParse(controllers['retailPrice']!.text) ?? 0;
                final wholesale = double.tryParse(val) ?? 0;

                if (wholesale <= purchase) {
                  return 'يجب أن يكون أكبر من سعر الشراء';
                }
                if (retail > 0 && wholesale > retail) {
                  return 'يجب أن يكون أقل من (أو يساوي) سعر القطاعي';
                }
                return null;
              },
            ),

            // 3. قسم المخزن
            const SectionTitle('المخزن'),
            RowFields(
              field1: CustomTextField(
                controller: controllers['stock']!,
                label: 'الكمية الحالية',
                isNumber: true,
                isRequired: true,
              ),
              field2: CustomTextField(
                controller: controllers['minStock']!,
                label: 'حد التنبيه (الأدنى)',
                isNumber: true,
              ),
            ),

            // 4. قسم الخصائص والصلاحية
            const SectionTitle('تفاصيل إضافية'),

            // مفتاح التبديل بين الوضعين
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SwitchListTile(
                title: const Text('حساب الصلاحية تلقائياً'),
                subtitle: const Text('إدخال تاريخ الإنتاج + المدة'),
                value: isCalculatedExpiryMode,
                onChanged: onExpiryModeChanged,
              ),
            ),

            // حقول الوضع المحسوب
            if (isCalculatedExpiryMode)
              RowFields(
                field1: CustomTextField(
                  controller: controllers['productionDate']!,
                  label: 'تاريخ الإنتاج',
                  icon: Icons.history,
                  readOnly: true,
                  onTap: onPickProductionDate,
                ),
                field2: CustomTextField(
                  controller: controllers['validityMonths']!,
                  label: 'المدة (شهور)',
                  isNumber: true,
                ),
              ),

            CustomTextField(
              controller: controllers['expiryDate']!,
              label: 'تاريخ الانتهاء',
              icon: Icons.calendar_today,
              readOnly: true,
              onTap: isCalculatedExpiryMode ? null : onPickDate,
            ),

            CustomTextField(
              controller: controllers['expiryAlert']!,
              label: 'تنبيه قبل (أيام)',
              isNumber: true,
            ),

            const SizedBox(height: 20),

            // زر الحفظ (يتغير نصه حسب الشاشة)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: onSave,
                child: Text(
                  saveButtonText,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(height: 50), // مسافة في الأسفل
          ],
        ),
      ),
    );
  }
}
