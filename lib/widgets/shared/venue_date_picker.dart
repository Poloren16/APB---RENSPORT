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

  static List<DateTime> getWeekDates(DateTime selectedDate) {
    final baseDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final startDate = baseDate.subtract(const Duration(days: 4));
    return List.generate(30, (i) => startDate.add(Duration(days: i)));
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
  List<DateTime>? _dates;

  List<DateTime> get dates {
    _dates ??= VenueDatePicker.getWeekDates(widget.selectedDate);
    return _dates!;
  }

  @override
  void initState() {
    super.initState();
    _dates = VenueDatePicker.getWeekDates(widget.selectedDate);
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelected(isAnimated: false);
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          _scrollToSelected(isAnimated: true);
        }
      });
    });
  }

  @override
  void didUpdateWidget(VenueDatePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!VenueDatePicker.isSameDay(oldWidget.selectedDate, widget.selectedDate)) {
      final hasNewDate = dates.any((d) => VenueDatePicker.isSameDay(d, widget.selectedDate));
      
      if (!hasNewDate) {
        setState(() {
          _dates = VenueDatePicker.getWeekDates(widget.selectedDate);
        });
      }
      
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSelected({bool isAnimated = true}) {
    if (!_scrollController.hasClients) return;

    final index = dates.indexWhere((date) => VenueDatePicker.isSameDay(date, widget.selectedDate));

    if (index != -1) {
      final viewportWidth = _scrollController.position.viewportDimension;
      // Item width (55) + margin (12) = 67
      // Center of item: (index * 67) + (55 / 2) = index * 67 + 27.5
      final offset = (index * 67.0 + 27.5) - (viewportWidth / 2);

      if (isAnimated) {
        _scrollController.animateTo(
          offset.clamp(0.0, _scrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 300),
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
    final datesList = dates;
    return SizedBox(
      height: 70,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: datesList.length,
        itemBuilder: (context, index) {
          final date = datesList[index];
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

