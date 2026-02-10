import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/models/sales_invoice_model.dart';
import '../../../../data/services/sales_service.dart';
import 'sales_history_state.dart';

class SalesHistoryCubit extends Cubit<SalesHistoryState> {
  final SalesService _salesService;

  static const int _limit = 10;
  DateTime? _currentDateFilter;

  // Cache for deduplication
  final Set<String> _invoiceIds = {};

  SalesHistoryCubit(this._salesService) : super(SalesHistoryInitial());

  /// الجلب الأولي أو عند تغيير الفلتر/التحديث
  Future<void> fetchInvoices({bool isRefresh = false, DateTime? date}) async {
    final isDateChanged = date != _currentDateFilter;

    // 1. إدارة الفلتر وتفريغ الكاش إذا لزم الأمر
    if (isDateChanged) {
      _currentDateFilter = date;
      _invoiceIds.clear(); // Reset cache on filter change
      emit(SalesHistoryLoading());
    } else if (isRefresh) {
      // Refresh Logic: في حالة التحديث، لا نحذف الكاش فوراً ولكن سنقوم بتحديثه لاحقاً
      // ولا نطلق Loading لنحتفظ بالعرض الحالي (Silent Refresh)
    } else if (state is SalesHistoryLoaded) {
      // إذا لم يكن تحديث ولم يتغير التاريخ، ولديك بيانات، لا تفعل شيئاً
      return;
    } else {
      // أول مرة تحميل
      emit(SalesHistoryLoading());
    }

    try {
      // دائماً نجلب الصفحة الأولى (أحدث 10 فواتير)
      final newInvoices = await _salesService.getSalesInvoices(
        limit: _limit,
        offset: 0,
        filterDate: _currentDateFilter,
      );

      if (isRefresh && state is SalesHistoryLoaded) {
        // --- منطق التحديث الذكي (Merge & Dedup) ---
        final currentState = state as SalesHistoryLoaded;
        final currentInvoices = currentState.invoices;

        // خريطة لدمج البيانات (جديد + قديم) مع منع التكرار
        final Map<String, SalesInvoiceModel> invoiceMap = {};

        // 1. إضافة الفواتير الجديدة (ستحل محل القديمة إذا تشابهت ال IDs)
        for (var inv in newInvoices) {
          if (inv.id != null) invoiceMap[inv.id!] = inv;
        }

        // 2. إضافة الفواتير الحالية التي لم يتم شملها
        // هذا يحافظ على البيانات المحملة سابقاً (Pagination) مع تحديث أول 10 عناصر
        for (var inv in currentInvoices) {
          if (inv.id != null && !invoiceMap.containsKey(inv.id)) {
            invoiceMap[inv.id!] = inv;
          }
        }

        // تحويل الماب لقائمة
        final mergedList = invoiceMap.values.toList();
        // إعادة الترتيب زمنياً (الأحدث أولاً)
        mergedList.sort((a, b) => b.date.compareTo(a.date));

        _updateCache(mergedList);

        emit(
          currentState.copyWith(
            invoices: mergedList,
            hasReachedMax:
                currentState.hasReachedMax, // الاحتفاظ بحالة الوصول للنهاية
            isLoadingMore: false,
            filterDate: _currentDateFilter,
          ),
        );
      } else {
        // التحميل العادي (Initial or Date Changed)
        _updateCache(newInvoices);
        emit(
          SalesHistoryLoaded(
            invoices: newInvoices,
            hasReachedMax: newInvoices.length < _limit,
            isLoadingMore: false,
            filterDate: _currentDateFilter,
          ),
        );
      }
    } catch (e) {
      // في حالة الخطأ أثناء التحديث الصامت، نعرض رسالة خطأ دون مسح البيانات
      if (state is SalesHistoryLoaded) {
        emit(SalesHistoryError(e.toString())); // يمكن تحسينه ليكون SnackBar فقط
      } else {
        emit(SalesHistoryError(e.toString()));
      }
    }
  }

  /// تحميل المزيد (Pagination)
  Future<void> loadMore() async {
    if (state is! SalesHistoryLoaded) return;
    final currentState = state as SalesHistoryLoaded;

    if (currentState.hasReachedMax || currentState.isLoadingMore) return;

    emit(currentState.copyWith(isLoadingMore: true));

    try {
      final currentList = currentState.invoices;
      final newInvoices = await _salesService.getSalesInvoices(
        limit: _limit,
        offset: currentList.length,
        filterDate: _currentDateFilter,
      );

      // فلترة التكرار (لضمان سلامة القائمة)
      final uniqueNewInvoices = newInvoices
          .where((inv) => !_invoiceIds.contains(inv.id))
          .toList();

      final updatedList = List.of(currentList)..addAll(uniqueNewInvoices);
      _updateCache(updatedList);

      emit(
        currentState.copyWith(
          invoices: updatedList,
          hasReachedMax: newInvoices.length < _limit,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      emit(SalesHistoryError("فشل تحميل المزيد: $e"));
      // استعادة الحالة بدون لودينج للحفاظ على البيانات
      emit(currentState.copyWith(isLoadingMore: false));
    }
  }

  void _updateCache(List<SalesInvoiceModel> invoices) {
    _invoiceIds.clear();
    _invoiceIds.addAll(invoices.map((e) => e.id!).whereType<String>());
  }

  void setDateFilter(DateTime? date) {
    fetchInvoices(date: date);
  }

  void clearFilter() {
    setDateFilter(null);
  }
}
