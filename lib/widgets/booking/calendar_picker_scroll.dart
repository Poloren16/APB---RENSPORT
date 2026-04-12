import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class CalendarPickerScroll extends StatelessWidget {
  final DateTime selectedDate;
  final List<DateTime> weekDates;
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback onReset;

  const CalendarPickerScroll({
    super.key,
    required this.selectedDate,
    required this.weekDates,
    required this.onDateSelected,
    required this.onReset,
  });

  String _getDayName(DateTime date) {
    const days = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
    return days[date.weekday % 7];
  }

  String _getMonthName(DateTime date) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return months[date.month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 60)),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: AppColors.primary,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    onDateSelected(picked);
                  }
                },
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month,
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      _getMonthName(selectedDate),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down,
                        color: AppColors.primary),
                  ],
                ),
              ),
              TextButton(
                onPressed: onReset,
                child: const Text(
                  'Reset & Mulai Ulang',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Horizontal Date Scroller
          SizedBox(
            height: 72,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: weekDates.length,
              itemBuilder: (context, index) {
                final date = weekDates[index];
                final isSelected = date.day == selectedDate.day &&
                                   date.month == selectedDate.month &&
                                   date.year == selectedDate.year;
                final isToday = date.day == DateTime.now().day &&
                                date.month == DateTime.now().month &&
                                date.year == DateTime.now().year;

                return GestureDetector(
                  onTap: () => onDateSelected(date),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 52,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      border: isToday && !isSelected
                          ? Border.all(
                              color: AppColors.primary, width: 1.5)
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _getDayName(date),
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          date.day.toString(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
