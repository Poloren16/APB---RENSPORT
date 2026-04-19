import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Widget kalender horizontal yang dapat digunakan ulang di berbagai halaman.
/// Menampilkan 14 hari dari awal minggu ini secara dinamis.
class VenueDatePicker extends StatefulWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const VenueDatePicker({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  State<VenueDatePicker> createState() => _VenueDatePickerState();

  static List<DateTime> getWeekDates() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Start from 7 days ago to put "today" in the middle of a 15-day range
    return List.generate(15, (i) => today.subtract(const Duration(days: 7)).add(Duration(days: i)));
  }

  static String getDayName(DateTime date) {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return days[date.weekday % 7];
  }

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _VenueDatePickerState extends State<VenueDatePicker> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    // Use a slightly longer delay to ensure layout is complete
    Future.delayed(const Duration(milliseconds: 100), () => _scrollToSelected(isAnimated: false));
  }

  @override
  void didUpdateWidget(VenueDatePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!VenueDatePicker.isSameDay(oldWidget.selectedDate, widget.selectedDate)) {
      _scrollToSelected();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSelected({bool isAnimated = true}) {
    if (!_scrollController.hasClients) return;

    final dates = VenueDatePicker.getWeekDates();
    final index = dates.indexWhere((date) => VenueDatePicker.isSameDay(date, widget.selectedDate));

    if (index != -1) {
      final viewportWidth = _scrollController.position.viewportDimension;
      // Item width (55) + margin (12) = 67
      // We subtract half viewport to center, then add half item width (55/2 = 27.5)
      final double itemWidth = 55.0;
      final double margin = 12.0;
      final double totalItemWidth = itemWidth + margin;
      
      final offset = (index * totalItemWidth + (itemWidth / 2)) - (viewportWidth / 2);

      if (isAnimated) {
        _scrollController.animateTo(
          offset.clamp(0.0, _scrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
        );
      } else {
        _scrollController.jumpTo(
          offset.clamp(0.0, _scrollController.position.maxScrollExtent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dates = VenueDatePicker.getWeekDates();
    return SizedBox(
      height: 70,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: dates.length,
        itemBuilder: (context, index) {
          final date = dates[index];
          final isSelected = VenueDatePicker.isSameDay(date, widget.selectedDate);
          
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final isPast = date.isBefore(today);

          return GestureDetector(
            onTap: isPast ? null : () => widget.onDateSelected(date),
            child: Opacity(
              opacity: isPast ? 0.4 : 1.0,
              child: Container(
                width: 55,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withOpacity(0.1)
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
                      VenueDatePicker.getDayName(date),
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
            ),
          );
        },
      ),
    );
  }
}

