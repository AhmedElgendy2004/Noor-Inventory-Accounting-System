import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DatePickerUtils {
  // 1. قائمة الشهور (ثابتة هنا للاستخدام العام)
  static const List<String> arabicMonths = [
    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
  ];

  // 2. دالة التنسيق (تحويل التاريخ لنص عربي)
  static String formatDateToArabic(DateTime date) {
    return "${arabicMonths[date.month - 1]} ${date.year}";
  }

  // تنسيق كامل (يوم شهر سنة - وقت)
  static String formatFullDateTime(DateTime date) {
    final time = "${date.hour > 12 ? date.hour - 12 : date.hour}:${date.minute.toString().padLeft(2, '0')} ${date.hour >= 12 ? 'م' : 'ص'}";
    return "${date.day} ${arabicMonths[date.month - 1]} ${date.year} | $time";
  }

  // 3. دالة الحساب (حساب تاريخ الانتهاء بناءً على تاريخ الإنتاج والمدة)
  static DateTime calculateExpiryDate({
    required DateTime productionDate,
    required int validityMonths,
  }) {
    return DateTime(
      productionDate.year,
      productionDate.month + validityMonths,
      productionDate.day,
    );
  }

  // 4. دالة عرض الـ Picker
  static Future<void> showMonthYearPicker(
    BuildContext context, {
    DateTime? initialDate,
    required Function(DateTime) onConfirm,
    required int startYear,
    required int endYear,
  }) async {
    final now = DateTime.now();
    int selectedMonth = initialDate?.month ?? now.month;
    int selectedYear = initialDate?.year ?? now.year;

    // ضبط الحدود
    if (selectedYear < startYear) selectedYear = startYear;
    if (selectedYear > endYear) selectedYear = endYear;

    final int count = endYear - startYear + 1;
    final List<int> years = List.generate(count, (index) => startYear + index);

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext builder) {
        return SizedBox(
          height: 300,
          child: Column(
            children: [
              // شريط الأزرار
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text('إلغاء', style: TextStyle(color: Colors.red)),
                    ),
                    const Text(
                      'اختر التاريخ',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    TextButton(
                      onPressed: () {
                        onConfirm(DateTime(selectedYear, selectedMonth));
                        context.pop();
                      },
                      child: const Text('تم', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              // البكرات (Pickers)
              Expanded(
                child: Row(
                  children: [
                    // بكرة الشهور
                    Expanded(
                      child: CupertinoPicker(
                        scrollController:
                            FixedExtentScrollController(initialItem: selectedMonth - 1),
                        itemExtent: 40,
                        onSelectedItemChanged: (index) => selectedMonth = index + 1,
                        children: arabicMonths
                            .map((month) => Center(child: Text(month)))
                            .toList(),
                      ),
                    ),
                    // بكرة السنين
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(
                          initialItem: years.contains(selectedYear)
                              ? years.indexOf(selectedYear)
                              : 0,
                        ),
                        itemExtent: 40,
                        onSelectedItemChanged: (index) => selectedYear = years[index],
                        children: years
                            .map((year) => Center(child: Text(year.toString())))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}