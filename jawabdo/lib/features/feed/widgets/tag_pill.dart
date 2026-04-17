import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';

class TagPill extends StatelessWidget {
  final String label;
  final Color? dotColor;

  const TagPill({super.key, required this.label, this.dotColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.tagPillBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dotColor != null) ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: GoogleFonts.sourceCodePro(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.tagPillText,
            ),
          ),
        ],
      ),
    );
  }
}
