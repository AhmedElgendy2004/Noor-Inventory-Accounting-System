import 'package:al_noor_gallery/core/utils/tap_effect.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/models/sales_invoice_model.dart';
import '../../../../data/services/sales_service.dart';
import '../logic/sales_history_cubit.dart';

class SalesHistoryScreen extends StatelessWidget {
  const SalesHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SalesHistoryCubit(SalesService())..loadInvoices(),
      child: Scaffold(
        appBar: AppBar(title: const Text("سجل الفواتير")),
        body: BlocBuilder<SalesHistoryCubit, SalesHistoryState>(
          builder: (context, state) {
            if (state is SalesHistoryLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is SalesHistoryError) {
              return Center(child: Text("خطأ: ${state.message}"));
            } else if (state is SalesHistoryLoaded) {
              if (state.invoices.isEmpty) {
                return const Center(child: Text("لا توجد فواتير سابقة"));
              }
              return SafeArea(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.invoices.length,
                  itemBuilder: (context, index) {
                    final invoice = state.invoices[index];
                    return _InvoiceCard(invoice: invoice);
                  },
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final SalesInvoiceModel invoice;

  const _InvoiceCard({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy/MM/dd hh:mm a');
    final isCash = invoice.paymentType == PaymentType.cash;
    final isWholesale = invoice.isWholesale;

    return TapEffect(
      onClick: () {
        context.push('/sales-history/details', extra: invoice);
      },
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 12),
        surfaceTintColor: isWholesale
            ? Colors.purple.shade50
            : Colors.blue.shade50,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: isWholesale ? Colors.purple.shade200 : Colors.transparent,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: isCash
                ? Colors.green.shade100
                : Colors.orange.shade100,
            child: Icon(
              isCash ? Icons.attach_money : Icons.credit_card,
              color: isCash ? Colors.green : Colors.orange,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  "فاتورة \n${invoice.invoiceNumber ?? '---'}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("العميل: ${invoice.customerName ?? 'زبون نقدي'}"),
              Text(
                dateFormat.format(invoice.date),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${invoice.totalAmount.toStringAsFixed(1)} ج.م",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.blue,
                ),
              ),
              if (!isCash)
                Text(
                  "متبقي: ${(invoice.totalAmount - invoice.paidAmount).toStringAsFixed(1)}",
                  style: const TextStyle(fontSize: 10, color: Colors.red),
                ),
              SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isWholesale ? Colors.purple : Colors.blue,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isWholesale ? "جملة" : "قطاعي",
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
