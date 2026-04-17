import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../core/constants/app_colors.dart';

class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFEEEEEE),
      highlightColor: const Color(0xFFF5F5F5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _box(80, 24, radius: 20),
                    const SizedBox(width: 8),
                    _box(60, 24, radius: 20),
                    const Spacer(),
                    _box(70, 20, radius: 4),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _box(double.infinity, 14),
                          const SizedBox(height: 6),
                          _box(double.infinity, 14),
                          const SizedBox(height: 6),
                          _box(160, 14),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _box(80, 80, radius: 4),
                  ],
                ),
                const SizedBox(height: 10),
                _box(200, 12),
                const SizedBox(height: 6),
                _box(80, 12),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.cardDivider),
        ],
      ),
    );
  }

  Widget _box(double width, double height, {double radius = 2}) {
    return Container(
      width: width == double.infinity ? null : width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
