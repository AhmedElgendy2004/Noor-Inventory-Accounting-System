import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final bool isNumber;
  final bool isRequired;
  final bool readOnly;
  final VoidCallback? onTap;

  const CustomTextField({
    Key? key,
    required this.controller,
    required this.label,
    this.icon,
    this.isNumber = false,
    this.isRequired = false,
    this.readOnly = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        // لو رقم بنظهر كيبورد الأرقام، لو نص بنظهر العادي
        keyboardType: isNumber 
            ? const TextInputType.numberWithOptions(decimal: true) 
            : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon) : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: readOnly ? Colors.grey[100] : Colors.white,
        ),
        validator: isRequired 
            ? (value) => (value == null || value.isEmpty) ? 'هذا الحقل مطلوب' : null 
            : null,
      ),
    );
  }
}