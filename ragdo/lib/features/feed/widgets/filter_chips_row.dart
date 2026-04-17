import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';

const List<String> feedFilters = [
  'all',
  'near_me',
  'my_ward',
  'trending',
  'escalated',
  'resolved',
];

const Map<String, String> filterLabels = {
  'all': AppStrings.filterAll,
  'near_me': AppStrings.filterNearMe,
  'my_ward': AppStrings.filterMyWard,
  'trending': AppStrings.filterTrending,
  'escalated': AppStrings.filterEscalated,
  'resolved': AppStrings.filterResolved,
};

class FilterChipsRow extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;

  const FilterChipsRow({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: feedFilters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = feedFilters[index];
          final isSelected = filter == selected;
          return GestureDetector(
            onTap: () => onSelect(filter),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accent : AppColors.tagPillBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                filterLabels[filter]!,
                style: GoogleFonts.sourceCodePro(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.tagPillText,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
