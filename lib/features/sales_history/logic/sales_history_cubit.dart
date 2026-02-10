import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/models/sales_invoice_model.dart';
import '../../../../data/services/sales_service.dart';
import 'sales_history_state.dart';

class SalesHistoryCubit extends Cubit<SalesHistoryState> {
  final SalesService _salesService;

  static const int _limit = 10;
  DateTime? _currentDateFilter;

  SalesHistoryCubit(this._salesService) : super(SalesHistoryInitial());

  /// الجلب الأولي أو عند تغيير الفلتر/التحديث
  Future<void> fetchInvoices({bool isRefresh = false, DateTime? date}) async {
    // 1. إعداد المتغيرات
    if (isRefresh || date != _currentDateFilter) {
      // إذا كان تحديث أو تغيير تاريخ، نبدأ من الصفر
      _currentDateFilter = date;
      emit(SalesHistoryLoading());
    } else if (state is SalesHistoryLoaded) {
      // إذا كنا بالفعل محملين للبيانات ولا يوجد تغيير، لا نعيد التحميل
      // (إلا إذا طلبنا LoadMore - دالة منفصلة)
      return;
    }

    try {
      final invoices = await _salesService.getSalesInvoices(
        limit: _limit,
        offset: 0,
        filterDate: _currentDateFilter,
      );

      emit(
        SalesHistoryLoaded(
          invoices: invoices,
          hasReachedMax: invoices.length < _limit,
          isLoadingMore: false,
          filterDate: _currentDateFilter,
        ),
      );
    } catch (e) {
      emit(SalesHistoryError(e.toString()));
    }
  }

  /// تحميل المزيد (Pagination)
  Future<void> loadMore() async {
    if (state is! SalesHistoryLoaded) return;
    final currentState = state as SalesHistoryLoaded;

    // منع الطلب إذا وصلنا للنهاية أو جاري التحميل بالفعل
    if (currentState.hasReachedMax || currentState.isLoadingMore) return;

    // تفعيل مؤشر التحميل السفلي
    emit(currentState.copyWith(isLoadingMore: true));

    try {
      final currentList = currentState.invoices;
      final newInvoices = await _salesService.getSalesInvoices(
        limit: _limit,
        offset: currentList.length,
        filterDate: _currentDateFilter,
      );

      emit(
        currentState.copyWith(
          invoices: List.of(currentList)..addAll(newInvoices),
          hasReachedMax: newInvoices.length < _limit,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      // في حالة الخطأ، نعود للحالة السابقة ونلغي التحميل
      emit(SalesHistoryError("فشل تحميل المزيد: $e"));
      // نعيد الحالة القديمة عشان البيانات متضيعش
      emit(currentState.copyWith(isLoadingMore: false));
    }
  }

  /// تغيير فلتر التاريخ
  void setDateFilter(DateTime? date) {
    if (date == _currentDateFilter) return; // لا تغيير
    fetchInvoices(isRefresh: true, date: date);
  }

  /// مسح الفلتر
  void clearFilter() {
    setDateFilter(null);
  }
}
