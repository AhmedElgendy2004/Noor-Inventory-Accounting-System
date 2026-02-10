import 'package:equatable/equatable.dart';
import '../../../../data/models/sales_invoice_model.dart';

abstract class SalesHistoryState extends Equatable {
  const SalesHistoryState();

  @override
  List<Object?> get props => [];
}

class SalesHistoryInitial extends SalesHistoryState {}

class SalesHistoryLoading extends SalesHistoryState {}

class SalesHistoryLoaded extends SalesHistoryState {
  final List<SalesInvoiceModel> invoices;
  final bool hasReachedMax;
  final bool isLoadingMore;
  final DateTime? filterDate;

  const SalesHistoryLoaded({
    this.invoices = const [],
    this.hasReachedMax = false,
    this.isLoadingMore = false,
    this.filterDate,
  });

  SalesHistoryLoaded copyWith({
    List<SalesInvoiceModel>? invoices,
    bool? hasReachedMax,
    bool? isLoadingMore,
    DateTime? filterDate,
    bool clearDate = false,
  }) {
    return SalesHistoryLoaded(
      invoices: invoices ?? this.invoices,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      filterDate: clearDate ? null : (filterDate ?? this.filterDate),
    );
  }

  @override
  List<Object?> get props => [
    invoices,
    hasReachedMax,
    isLoadingMore,
    filterDate,
  ];
}

class SalesHistoryError extends SalesHistoryState {
  final String message;

  const SalesHistoryError(this.message);

  @override
  List<Object?> get props => [message];
}
