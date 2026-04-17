import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';

class PriorityBadge extends StatelessWidget {
  const PriorityBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.priorityBadgeBg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        AppStrings.priority,
        style: GoogleFonts.sourceCodePro(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.priorityBadgeText,
        ),
      ),
    );
  }
}
