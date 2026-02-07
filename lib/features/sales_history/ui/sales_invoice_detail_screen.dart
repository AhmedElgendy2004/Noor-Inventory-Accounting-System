import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/sales_invoice_model.dart';

class SalesInvoiceDetailScreen extends StatelessWidget {
  final SalesInvoiceModel invoice;

  const SalesInvoiceDetailScreen({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("تفاصيل الفاتورة \n${invoice.invoiceNumber ?? ''}"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header Info
            _buildInfoCard(),
            const SizedBox(height: 16),

            // Items List
            _buildItemsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _row(
              "التاريخ",
              DateFormat('yyyy/MM/dd hh:mm a').format(invoice.date),
            ),
            const Divider(),
            _row("العميل", invoice.customerName ?? "زبون عام"),
            const Divider(),
            _row(
              "نوع الدفع",
              invoice.paymentType == PaymentType.cash ? "نقدي" : "آجل",
            ),
            const Divider(),
            _row(
              "نوع الفاتورة",
              invoice.isWholesale ? "جملة" : "قطاعي",
              color: invoice.isWholesale ? Colors.purple : Colors.blue,
              isBold: true,
            ),
            const Divider(),
            _row("الإجمالي", "${invoice.totalAmount} ج.م", isBold: true),
            if (invoice.paymentType == PaymentType.credit) ...[
              const Divider(),
              _row("المدفوع", "${invoice.paidAmount} ج.م"),
              _row(
                "المتبقي",
                "${invoice.totalAmount - invoice.paidAmount} ج.م",
                color: Colors.red,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList() {
    return Card(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.blue.withOpacity(0.1),
            width: double.infinity,
            child: const Text(
              "المنتجات المباعة",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: invoice.items?.length ?? 0,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = invoice.items![index];
              return ListTile(
                title: Text(
                  item.productName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(" ${item.priceAtSale}  ${item.quantity}x  ج.م"),
                trailing: Text(
                  "${(item.quantity * item.priceAtSale).toStringAsFixed(1)} ج.م",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
              color: color ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
