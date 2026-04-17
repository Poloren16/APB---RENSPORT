import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Model data untuk satu kategori di chip filter.
class CategoryItem {
  final String label;
  final IconData? icon;
  const CategoryItem(this.label, [this.icon]);
}

/// Widget chip kategori horizontal yang dapat digunakan ulang.
/// Can receive a list of [CategoryItem] and calls [onCategorySelected]
/// setiap kali user memilih kategori baru.
class VenueCategoryChips extends StatelessWidget {
  final List<CategoryItem> categories;
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  const VenueCategoryChips({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = cat.label == selectedCategory;
          return GestureDetector(
            onTap: () => onCategorySelected(cat.label),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      isSelected ? AppColors.primary : Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    cat.label,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.primary
                          : Colors.grey[600],
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  if (cat.icon != null) ...[
                    const SizedBox(width: 4),
                    Icon(
                      cat.icon,
                      size: 16,
                      color: isSelected
                          ? AppColors.primary
                          : Colors.grey[600],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
