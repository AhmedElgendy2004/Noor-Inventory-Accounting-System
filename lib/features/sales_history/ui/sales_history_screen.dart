import 'package:al_noor_gallery/core/widgets/custom_error_screen.dart';
import 'package:al_noor_gallery/features/sales_history/ui/widgets/invoice_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
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
        actions: [FilteringWithDate()],
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
                        return InvoiceCard(invoice: invoice);
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

class FilteringWithDate extends StatelessWidget {
  const FilteringWithDate({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
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
    );
  }
}

