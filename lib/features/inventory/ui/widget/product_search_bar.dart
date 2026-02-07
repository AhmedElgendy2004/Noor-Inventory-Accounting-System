import 'package:flutter/material.dart';
import '../../../../core/utils/inline_barcode_scanner.dart';

class ProductSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final String hintText;
  final bool readOnly;
  final VoidCallback? onTap;
  final FocusNode? focusNode;

  const ProductSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
    this.hintText = 'بحث عن منتج (اسم أو باركود)',
    this.readOnly = false,
    this.onTap,
    this.focusNode,
  });

  @override
  State<ProductSearchBar> createState() => _ProductSearchBarState();
}

class _ProductSearchBarState extends State<ProductSearchBar> {
  bool _isScanning = false;

  void _handleBarcode(String code) {
    setState(() {
      _isScanning = false;
    });
    widget.controller.text = code;
    widget.onChanged(code);
    widget.onSubmitted(code);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isScanning)
          InlineBarcodeScanner(
            onBarcodeDetected: _handleBarcode,
            onClose: () => setState(() => _isScanning = false),
          ),
        TextField(
          controller: widget.controller,
          textInputAction: TextInputAction.search,
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          readOnly: widget.readOnly,
          onTap: widget.onTap,
          focusNode: widget.focusNode,
          decoration: InputDecoration(
            labelText: widget.hintText,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.controller.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      widget.controller.clear();
                      widget.onChanged('');
                      // Return focus or keep it? existing behavior usually requires clearing
                    },
                  ),
                IconButton(
                  icon: Icon(
                    _isScanning ? Icons.camera_alt : Icons.camera_alt_outlined,
                    color: _isScanning ? Theme.of(context).primaryColor : null,
                  ),
                  tooltip: 'مسح الباركود',
                  onPressed: () {
                    setState(() {
                      _isScanning = !_isScanning;
                    });
                  },
                ),
              ],
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}
