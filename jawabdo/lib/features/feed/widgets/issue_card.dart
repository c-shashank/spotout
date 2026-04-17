import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/ghmc_wards.dart';
import '../../../core/constants/issue_categories.dart';
import '../../../models/issue.dart';
import 'engagement_row.dart';
import 'priority_badge.dart';
import 'tag_pill.dart';

class IssueCard extends StatelessWidget {
  final Issue issue;
  final VoidCallback onTap;
  final VoidCallback onUpvote;
  final VoidCallback onDownvote;
  final VoidCallback onBookmark;
  final VoidCallback? onUsernameTab;
  final VoidCallback? onVisible;

  const IssueCard({
    super.key,
    required this.issue,
    required this.onTap,
    required this.onUpvote,
    required this.onDownvote,
    required this.onBookmark,
    this.onUsernameTab,
    this.onVisible,
  });

  @override
  Widget build(BuildContext context) {
    final category = categoryFromValue(issue.category);
    final ward = ghmcWards.firstWhere(
      (w) => w.code == issue.wardId,
      orElse: () => GhmcWard(code: issue.wardId, name: issue.wardId, circle: ''),
    );

    return VisibilityDetector(
      key: Key('issue_card_${issue.id}'),
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0.5) onVisible?.call();
      },
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Tags + Priority
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      TagPill(
                        label: category.label.length > 18
                            ? '${category.label.substring(0, 16)}…'
                            : category.label,
                        dotColor: category.color,
                      ),
                      const SizedBox(width: 6),
                      TagPill(label: ward.name),
                      const Spacer(),
                      if (issue.priorityFlag) const PriorityBadge(),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Row 2: Content (title + image)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 68,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              issue.title,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.sourceCodePro(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryText,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Row 2: Thumbnail
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: issue.mediaUrls.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: issue.mediaUrls.first,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Container(
                                    color: category.color.withOpacity(0.15),
                                    child: Center(
                                      child: Icon(
                                        category.icon,
                                        color: category.color,
                                        size: 28,
                                      ),
                                    ),
                                  ),
                                  errorWidget: (_, __, ___) => _CategoryThumb(category: category),
                                )
                              : _CategoryThumb(category: category),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Row 3: Description
                  Text(
                    issue.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.sourceCodePro(
                      fontSize: 12,
                      color: AppColors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Row 4: Username
                  GestureDetector(
                    onTap: onUsernameTab,
                    child: Text(
                      '@${(issue.createdByName ?? 'unknown').replaceAll(' ', '').toLowerCase()}',
                      style: GoogleFonts.sourceCodePro(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Row 5: Engagement
            EngagementRow(
              issue: issue,
              onUpvote: onUpvote,
              onDownvote: onDownvote,
              onBookmark: onBookmark,
            ),

            const Divider(height: 1, thickness: 1, color: AppColors.cardDivider),
          ],
        ),
      ),
    );
  }
}

class _CategoryThumb extends StatelessWidget {
  final IssueCategoryInfo category;

  const _CategoryThumb({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: category.color.withOpacity(0.15),
      child: Center(
        child: Icon(category.icon, color: category.color, size: 32),
      ),
    );
  }
}
