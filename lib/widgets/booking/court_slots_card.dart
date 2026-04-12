import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class CourtSlotsCard extends StatelessWidget {
  final List<Map<String, dynamic>> courts;
  final List<Map<String, dynamic>> timeSlots;
  final Set<String> selectedSlots;
  final Function(String) onSlotSelected;
  final String Function(int) formatCurrency;
  final Function(Map<String, dynamic>)? onCourtTap;

  const CourtSlotsCard({
    super.key,
    required this.courts,
    required this.timeSlots,
    required this.selectedSlots,
    required this.onSlotSelected,
    required this.formatCurrency,
    this.onCourtTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: courts.asMap().entries.map((ce) {
            final courtIdx = ce.key;
            final court = ce.value;
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(
                  right: courtIdx == 0 ? 8 : 0,
                  left: courtIdx == 1 ? 8 : 0,
                ),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Court header inside card (clickable → Court Detail)
                    GestureDetector(
                      onTap: onCourtTap != null ? () => onCourtTap!(court) : null,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              const BorderRadius.vertical(top: Radius.circular(14)),
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.shade200,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    court['name'],
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.sports_tennis,
                                          size: 11, color: AppColors.textSecondary),
                                      const SizedBox(width: 3),
                                      Text(
                                        court['type'],
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right,
                                size: 16, color: AppColors.textSecondary),
                          ],
                        ),
                      ),
                    ),
                    // Time slots inside the card
                    ...timeSlots.asMap().entries.map((entry) {
                      final slotIdx = entry.key;
                      final slot = entry.value;
                      final slotKey = '${slotIdx}_$courtIdx';
                      final isSelected = selectedSlots.contains(slotKey);
                      final isBooked = slot['booked'] as bool;
                      return GestureDetector(
                        onTap: isBooked ? null : () => onSlotSelected(slotKey),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isBooked
                                ? Colors.white
                                : isSelected
                                    ? AppColors.primary.withOpacity(0.1)
                                    : Colors.white,
                            border: Border(
                              top: BorderSide(
                                  color: Colors.grey.shade100, width: 1),
                              left: isSelected
                                  ? const BorderSide(
                                      color: AppColors.primary, width: 3)
                                  : BorderSide.none,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                slot['time'],
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isBooked
                                      ? Colors.grey.shade400
                                      : isSelected
                                          ? AppColors.primary
                                          : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              if (isBooked)
                                Text(
                                  'Booked',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade400,
                                  ),
                                )
                              else ...[
                                Text(
                                  formatCurrency(slot['price'] as int),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ]
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
