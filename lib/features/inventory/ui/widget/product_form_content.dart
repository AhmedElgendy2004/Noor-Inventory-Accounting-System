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

  const ProductFormContent({
    Key? key,
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
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: formKey,
        child: Column(
          children: [
            // 1. قسم البيانات الأساسية
            const SectionTitle('البيانات الأساسية'),

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
                      value: selectedCategoryId,
                      decoration: const InputDecoration(
                        labelText: 'التصنيف',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
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
              ),
            ),
            CustomTextField(
              controller: controllers['wholesalePrice']!,
              label: 'سعر الجملة',
              isNumber: true,
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

            CustomTextField(
              controller: controllers['expiryDate']!,
              label: 'تاريخ الصلاحية',
              icon: Icons.calendar_today,
              readOnly: true,
              onTap: onPickDate,
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
