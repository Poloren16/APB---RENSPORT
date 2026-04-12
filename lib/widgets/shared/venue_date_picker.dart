import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Widget kalender horizontal yang dapat digunakan ulang di berbagai halaman.
/// Menampilkan 14 hari dari awal minggu ini secara dinamis.
class VenueDatePicker extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const VenueDatePicker({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  static List<DateTime> getWeekDates() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
    return List.generate(14, (i) => startOfWeek.add(Duration(days: i)));
  }

  static String getDayName(DateTime date) {
    const days = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
    return days[date.weekday % 7];
  }

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final dates = getWeekDates();
    return SizedBox(
      height: 70,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: dates.length,
        itemBuilder: (context, index) {
          final date = dates[index];
          final isSelected = isSameDay(date, selectedDate);
          return GestureDetector(
            onTap: () => onDateSelected(date),
            child: Container(
              width: 55,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(15),
                border: isSelected
                    ? Border.all(color: AppColors.primary, width: 2)
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    getDayName(date),
                    style: TextStyle(
                      color: isSelected ? AppColors.primary : Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      color: isSelected ? AppColors.primary : Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
