import 'package:flutter/material.dart';
import '../../../../data/models/cart_item_model.dart';

class CartItemWidget extends StatelessWidget {
  final CartItemModel item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  const CartItemWidget({
    super.key,
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Row 1: Delete Button & Product Name
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: onRemove,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    // Removed maxLines to allow full text wrap
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8), // Spacing between name and controls
            // Row 2: Price details & Controls
            Row(
              children: [
                // Product Price
                Expanded(
                  child: Text(
                    '${item.priceAtSale} ج.م  (${item.priceType == 'wholesale' ? 'جملة' : 'قطاعي'})',
                    style: TextStyle(
                      color: item.priceType == 'wholesale'
                          ? Colors.orange
                          : Colors.grey[700],
                      fontSize: 14,
                    ),
                  ),
                ),

                // Quantity Controls (Fat Finger Friendly)
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildQtyButton(Icons.remove, onDecrement),
                      Container(
                        width: 40,
                        alignment: Alignment.center,
                        child: Text(
                          '${item.quantity}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      _buildQtyButton(Icons.add, onIncrement),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // Total Price
                SizedBox(
                  width: 70,
                  child: Text(
                    '${item.total}\nج.م',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQtyButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        color: Colors.grey.shade100,
        child: Icon(icon, size: 20),
      ),
    );
  }
}
