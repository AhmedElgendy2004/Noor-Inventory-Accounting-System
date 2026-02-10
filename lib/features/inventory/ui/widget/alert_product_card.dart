import 'package:flutter/material.dart';
import '../../../../data/models/product_model.dart';

class AlertProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onTap;

  const AlertProductCard({super.key, required this.product, this.onTap});

  @override
  Widget build(BuildContext context) {

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.red.shade300, width: 1.5),
      ),
      color: Colors.red.shade50,
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: Colors.red.shade100,

          child: Icon(Icons.warning_amber_rounded, color: Colors.red),
        ),
        //name
        title: Text(
          product.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.red.shade900,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "الباركود:  ${product.barcode}",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                //color: Colors.red.shade900,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildBadge(
                  label: 'الكمية: ${product.stockQuantity}',
                  color: Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'الحد الأدنى: ${product.minStockLevel}',
                  style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildBadge({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
