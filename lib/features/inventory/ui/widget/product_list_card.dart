import 'package:flutter/material.dart';
import '../../../../data/models/product_model.dart';
import '../../../../core/widgets/action_icon_button.dart';

class ProductListCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ProductListCard({
    super.key,
    required this.product,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.blue.shade50,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        onTap: onTap,
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الباركود:  ${product.barcode}'),
            Divider(
              color: Colors.grey.shade400,
              thickness: 1,
              indent: 16,
              endIndent: 16,
            ),
            // سعر الشراء
            _buildPriceRow(
              "سعر الشراء:  ",
              product.purchasePrice,
              Colors.brown.shade500,
              12,
              16,
            ),
            // البيع قطاعي
            _buildPriceRow(
              "البيع قطاعي:  ",
              product.retailPrice,
              Colors.green.shade700,
              16,
              18,
            ),
            // البيع جمله
            _buildPriceRow(
              "البيع جمله:   ",
              product.wholesalePrice,
              Colors.orange.shade900,
              14,
              16,
            ),
            const SizedBox(height: 8),
            // الكمية
            Align(
              alignment: AlignmentGeometry.bottomLeft,
              child: _buildCountBadge(),
            ),
          ],
        ),
        trailing: (onEdit != null || onDelete != null)
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onEdit != null)
                    ActionIconButton(
                      icon: Icons.edit,
                      backgroundColor: Colors.blue.shade300,
                      onTap: onEdit!,
                    ),
                  if (onEdit != null && onDelete != null)
                    const SizedBox(width: 8),
                  if (onDelete != null)
                    ActionIconButton(
                      icon: Icons.delete,
                      backgroundColor: Colors.red.shade300,
                      onTap: onDelete!,
                    ),
                ],
              )
            : const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    double price,
    Color color,
    double labelSize,
    double priceSize,
  ) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: labelSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          price % 1 == 0 ? price.toInt().toString() : price.toString(),
          style: TextStyle(
            color: color,
            fontSize: priceSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCountBadge() {
    final isLowStock = product.stockQuantity <= product.minStockLevel;
    final color = isLowStock ? Colors.red.shade100 : Colors.green.shade100;
    final textColor = isLowStock ? Colors.red.shade800 : Colors.green.shade800;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'الكمية: ${product.stockQuantity}',
        style: TextStyle(
          color: textColor,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
