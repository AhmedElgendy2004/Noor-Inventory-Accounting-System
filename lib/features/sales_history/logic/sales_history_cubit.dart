import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/models/sales_invoice_model.dart';
import '../../../../data/services/sales_service.dart';

abstract class SalesHistoryState {}

class SalesHistoryInitial extends SalesHistoryState {}

class SalesHistoryLoading extends SalesHistoryState {}

class SalesHistoryLoaded extends SalesHistoryState {
  final List<SalesInvoiceModel> invoices;
  SalesHistoryLoaded(this.invoices);
}

class SalesHistoryError extends SalesHistoryState {
  final String message;
  SalesHistoryError(this.message);
}

class SalesHistoryCubit extends Cubit<SalesHistoryState> {
  final SalesService _salesService;

  SalesHistoryCubit(this._salesService) : super(SalesHistoryInitial());

  Future<void> loadInvoices() async {
    emit(SalesHistoryLoading());
    try {
      final invoices = await _salesService.getSalesInvoices();
      emit(SalesHistoryLoaded(invoices));
    } catch (e) {
      emit(SalesHistoryError(e.toString()));
    }
  }
}
