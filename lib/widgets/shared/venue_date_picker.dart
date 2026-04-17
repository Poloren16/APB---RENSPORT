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
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
    return List.generate(14, (i) => startOfWeek.add(Duration(days: i)));
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected(isAnimated: false));
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
      // Center of item: (index * 67) + (55 / 2) = index * 67 + 27.5
      final offset = (index * 67.0 + 27.5) - (viewportWidth / 2);

      if (isAnimated) {
        _scrollController.animateTo(
          offset.clamp(0.0, _scrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
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

