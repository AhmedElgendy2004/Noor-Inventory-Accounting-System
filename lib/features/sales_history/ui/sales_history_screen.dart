import 'package:al_noor_gallery/core/utils/tap_effect.dart';
import 'package:al_noor_gallery/core/widgets/custom_error_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/models/sales_invoice_model.dart';
import '../logic/sales_history_cubit.dart';
import '../logic/sales_history_state.dart';

class SalesHistoryScreen extends StatelessWidget {
  const SalesHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SalesHistoryView();
  }
}

class _SalesHistoryView extends StatefulWidget {
  const _SalesHistoryView();

  @override
  State<_SalesHistoryView> createState() => _SalesHistoryViewState();
}

class _SalesHistoryViewState extends State<_SalesHistoryView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Fetch data if not already loaded (Safe fetch)
    context.read<SalesHistoryCubit>().fetchInvoices();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // نطلب المزيد عندما نصل إلى 90% من القائمة
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      context.read<SalesHistoryCubit>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("سجل الفواتير"),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: () async {
              final pickedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2026, 2, 5),
                lastDate: DateTime.now(),
              );
              if (pickedDate != null && context.mounted) {
                context.read<SalesHistoryCubit>().setDateFilter(pickedDate);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Status Header
          BlocBuilder<SalesHistoryCubit, SalesHistoryState>(
            buildWhen: (previous, current) =>
                current is SalesHistoryLoaded || current is SalesHistoryLoading,
            builder: (context, state) {
              if (state is SalesHistoryLoaded && state.filterDate != null) {
                return Container(
                  width: double.infinity,
                  color: Colors.blue.shade50,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Text(
                        "بحث في: ${DateFormat('yyyy/MM/dd').format(state.filterDate!)}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        icon: const Icon(Icons.clear, size: 16),
                        label: const Text("مسح الفلتر"),
                        onPressed: () =>
                            context.read<SalesHistoryCubit>().clearFilter(),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Main List
          Expanded(
            child: BlocBuilder<SalesHistoryCubit, SalesHistoryState>(
              builder: (context, state) {
                if (state is SalesHistoryLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is SalesHistoryError) {
                  return CustomErrorScreen(
                    message: "",
                    onRetry: () => context
                        .read<SalesHistoryCubit>()
                        .fetchInvoices(isRefresh: true),
                  );
                } else if (state is SalesHistoryLoaded) {
                  if (state.invoices.isEmpty) {
                    return const Center(
                      child: Text(
                        "لا توجد فواتير",
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async => context
                        .read<SalesHistoryCubit>()
                        .fetchInvoices(isRefresh: true),
                    child: ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: state.isLoadingMore
                          ? state.invoices.length + 1
                          : state.invoices.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        // Loading Indicator at bottom
                        if (index >= state.invoices.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.blue,
                              ),
                            ),
                          );
                        }

                        // Invoice Item
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
        ],
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
