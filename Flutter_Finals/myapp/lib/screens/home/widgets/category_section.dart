import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';
import '../../../services/product_service.dart';

class CategorySection extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  const CategorySection({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final categories = ProductService.categories;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SizedBox(
        height: 80,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: categories.length,
          itemBuilder: (_, i) {
            final cat = categories[i];
            final name = cat['name'] as String;
            final icon = cat['icon'] as String;
            final isSelected = selectedCategory == name;
            return GestureDetector(
              onTap: () => onCategorySelected(name),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                width: 72,
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.navyBlue
                            : AppColors.veryLightBlue,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? null
                            : Border.all(
                                color: AppColors.lightBlue, width: 1),
                      ),
                      child: Center(
                        child: Text(icon, style: const TextStyle(fontSize: 22)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name == 'Washing Machine'
                          ? 'Washer'
                          : name == 'Vacuum Cleaner'
                              ? 'Vacuum'
                              : name == 'Air Conditioner'
                                  ? 'AC'
                                  : name,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected
                            ? AppColors.navyBlue
                            : AppColors.darkGrey,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
