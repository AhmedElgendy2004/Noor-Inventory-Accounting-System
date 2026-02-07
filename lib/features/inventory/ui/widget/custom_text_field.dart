import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final Widget? suffixIcon;
  final bool isNumber;
  final bool isRequired;
  final bool readOnly;
  final VoidCallback? onTap;
  final bool enabled;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    this.icon,
    this.suffixIcon,
    this.isNumber = false,
    this.isRequired = false,
    this.readOnly = false,
    this.onTap,
    this.enabled = true,
    this.validator,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, child) {
          return TextFormField(
            controller: controller,
            enabled: enabled,
            readOnly: readOnly,
            onTap: onTap,
            inputFormatters: inputFormatters,
            // لو رقم بنظهر كيبورد الأرقام، لو نص بنظهر العادي
            keyboardType: isNumber
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: icon != null ? Icon(icon) : null,
              suffixIcon: _buildSuffixIcon(value.text.isNotEmpty),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: readOnly ? Colors.grey[100] : Colors.white,
            ),
            validator: (value) {
              if (isRequired && (value == null || value.isEmpty)) {
                return 'هذا الحقل مطلوب';
              }
              if (validator != null) {
                return validator!(value);
              }
              return null;
            },
          );
        },
      ),
    );
  }

  Widget? _buildSuffixIcon(bool hasText) {
    // Only show clear button if not readOnly (e.g. avoid interfering with DatePicker)
    final bool showClear = hasText && !readOnly;

    if (!showClear && suffixIcon == null) return null;

    if (showClear && suffixIcon == null) {
      return IconButton(
        icon: const Icon(Icons.close, color: Colors.grey),
        onPressed: () => controller.clear(),
      );
    }

    if (!showClear && suffixIcon != null) {
      return suffixIcon;
    }

    // Both
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.close, color: Colors.grey),
          onPressed: () => controller.clear(),
        ),
        suffixIcon!,
      ],
    );
  }
}
