import 'package:flutter/material.dart';

// ويدجت بسيطة لعمل عنوان لكل قسم
class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle(this.title, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold, 
              fontSize: 18, 
              color: Theme.of(context).primaryColor
            ),
          ),
          const Divider(thickness: 1),
        ],
      ),
    );
  }
}

// ويدجت مساعدة لوضع خانتين بجوار بعض
class RowFields extends StatelessWidget {
  final Widget field1;
  final Widget field2;

  const RowFields({super.key, required this.field1, required this.field2});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: field1),
        const SizedBox(width: 10),
        Expanded(child: field2),
      ],
    );
  }
}