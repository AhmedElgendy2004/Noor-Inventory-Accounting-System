import 'package:al_noor_gallery/core/utils/inline_barcode_scanner.dart';
import 'package:flutter/material.dart';


class ProductSearchField extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;
  final String hintText;

  const ProductSearchField({
    Key? key,
    required this.controller,
    required this.onChanged,
    this.onSubmitted,
    this.hintText = 'بحث عن منتج (اسم أو باركود)',
  }) : super(key: key);

  @override
  State<ProductSearchField> createState() => _ProductSearchFieldState();
}

class _ProductSearchFieldState extends State<ProductSearchField> {
  bool _isScanning = false;

  void _handleBarcodeDetected(String code) {
    setState(() {
      widget.controller.text = code;
      _isScanning = false; // إغلاق الكاميرا بعد الالتقاط
    });
    // تفعيل البحث فوراً
    widget.onChanged(code);
    
    // لو تم تمرير دالة onSubmitted (زي حالة المخزن) ننفذها كمان
    if (widget.onSubmitted != null) {
      widget.onSubmitted!(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. منطقة الكاميرا (تظهر فقط عند التفعيل)
        if (_isScanning)
          InlineBarcodeScanner(
            onBarcodeDetected: _handleBarcodeDetected,
            onClose: () => setState(() => _isScanning = false),
          ),

        // 2. حقل البحث
        TextField(
          controller: widget.controller,
          onSubmitted: widget.onSubmitted,
          onChanged: widget.onChanged,
          decoration: InputDecoration(
            labelText: widget.hintText,
            prefixIcon: const Icon(Icons.search),
            border: const OutlineInputBorder(),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // زر مسح النص
                if (widget.controller.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      widget.controller.clear();
                      widget.onChanged('');
                      setState(() {}); // لتحديث الأيقونة
                    },
                  ),
                
                // زر تشغيل/إيقاف الاسكانر
                IconButton(
                  icon: Icon(
                    _isScanning ? Icons.stop_circle : Icons.qr_code_scanner,
                    color: _isScanning ? Colors.red : null,
                  ),
                  onPressed: () {
                    setState(() {
                      _isScanning = !_isScanning;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}