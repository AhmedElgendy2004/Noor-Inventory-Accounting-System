import 'package:flutter/material.dart';

class PaymentSummaryFooter extends StatelessWidget {
  final double totalAmount;
  final String paymentType; // 'cash' or 'credit'
  final bool isWholesale;
  final String? customerName;
  final VoidCallback onTogglePaymentType;
  final VoidCallback onSelectCustomer;
  final VoidCallback onCheckout;

  const PaymentSummaryFooter({
    super.key,
    required this.totalAmount,
    required this.paymentType,
    required this.isWholesale,
    this.customerName,
    required this.onTogglePaymentType,
    required this.onSelectCustomer,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Payment Options
          Row(
            children: [
              // Payment Type Toggle
              Expanded(
                child: InkWell(
                  onTap: onTogglePaymentType,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: paymentType == 'cash'
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      border: Border.all(
                        color: paymentType == 'cash'
                            ? Colors.green
                            : Colors.red,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          paymentType == 'cash'
                              ? Icons.money
                              : Icons.credit_card,
                          color: paymentType == 'cash'
                              ? Colors.green
                              : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          paymentType == 'cash'
                              ? 'نقدي (Cash)'
                              : 'آجل (Credit)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: paymentType == 'cash'
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Customer Selection (Required for Credit)
              Expanded(
                child: InkWell(
                  onTap: onSelectCustomer,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            customerName ?? 'اختر عميل...',
                            style: TextStyle(
                              color: customerName == null
                                  ? Colors.grey
                                  : Colors.black,
                              fontWeight: customerName != null
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Checkout Button & Total
          Row(
            children: [
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: totalAmount > 0 ? onCheckout : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade800, // Brand color
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: const Text(
                    'إتمام البيع',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'الإجمالي',
                      style: TextStyle(color: Colors.grey),
                    ),
                    FittedBox(
                      child: Text(
                        '$totalAmount',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
