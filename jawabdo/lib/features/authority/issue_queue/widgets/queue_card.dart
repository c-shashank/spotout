import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jawabdo/core/constants/app_colors.dart';
import 'package:jawabdo/core/constants/app_strings.dart';
import 'package:jawabdo/core/constants/ghmc_wards.dart';
import 'package:jawabdo/core/constants/issue_categories.dart';
import 'package:jawabdo/models/issue.dart';
import 'package:jawabdo/features/feed/widgets/priority_badge.dart';
import 'package:jawabdo/features/feed/widgets/tag_pill.dart';
import 'package:jawabdo/features/authority/issue_queue/widgets/take_action_panel.dart';

class QueueCard extends StatefulWidget {
  final Issue issue;
  final VoidCallback onActionSubmitted;
  final String authorityId;

  const QueueCard({
    super.key,
    required this.issue,
    required this.onActionSubmitted,
    required this.authorityId,
  });

  @override
  State<QueueCard> createState() => _QueueCardState();
}

class _QueueCardState extends State<QueueCard> {
  bool _expanded = false;

  int get _daysOld {
    return DateTime.now().difference(widget.issue.createdAt).inDays;
  }

  bool get _isOverdue => _daysOld > 7;

  Color _tierColor(EscalationTier tier) {
    switch (tier) {
      case EscalationTier.ward:
        return AppColors.tierWard;
      case EscalationTier.municipal:
        return AppColors.tierMunicipal;
      case EscalationTier.state:
        return AppColors.tierState;
      case EscalationTier.mediaNgo:
        return AppColors.tierMediaNgo;
    }
  }

  String _tierLabel(EscalationTier tier) {
    switch (tier) {
      case EscalationTier.ward:
        return 'WARD';
      case EscalationTier.municipal:
        return 'MUNICIPAL';
      case EscalationTier.state:
        return 'STATE';
      case EscalationTier.mediaNgo:
        return 'MEDIA/NGO';
    }
  }

  Color _statusColor(IssueStatus status) {
    switch (status) {
      case IssueStatus.open:
        return AppColors.statusOpen;
      case IssueStatus.inProgress:
        return AppColors.statusInProgress;
      case IssueStatus.resolved:
        return AppColors.statusResolved;
      case IssueStatus.rejected:
        return AppColors.statusRejected;
    }
  }

  String _statusLabel(IssueStatus status) {
    switch (status) {
      case IssueStatus.open:
        return 'OPEN';
      case IssueStatus.inProgress:
        return 'IN PROGRESS';
      case IssueStatus.resolved:
        return 'RESOLVED';
      case IssueStatus.rejected:
        return 'REJECTED';
    }
  }

  @override
  Widget build(BuildContext context) {
    final issue = widget.issue;
    final category = categoryFromValue(issue.category);
    final ward = ghmcWards.firstWhere(
      (w) => w.code == issue.wardId,
      orElse: () => GhmcWard(code: issue.wardId, name: issue.wardId, circle: ''),
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        border: _isOverdue
            ? const Border(left: BorderSide(color: AppColors.statusOpen, width: 3))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: Tags + Tier + Status + Priority
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    TagPill(label: category.label, dotColor: category.color),
                    TagPill(label: ward.name),
                    _TierBadge(
                      label: _tierLabel(issue.escalationTier),
                      color: _tierColor(issue.escalationTier),
                    ),
                    _StatusBadge(
                      label: _statusLabel(issue.status),
                      color: _statusColor(issue.status),
                    ),
                    if (issue.priorityFlag) const PriorityBadge(),
                  ],
                ),
                const SizedBox(height: 10),

                // Row 2: Title + Thumbnail
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 68,
                      child: Text(
                        issue.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.sourceCodePro(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryText,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 72,
                      height: 72,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: issue.mediaUrls.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: issue.mediaUrls.first,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => _CategoryThumbSmall(
                                    category: category),
                                errorWidget: (_, __, ___) =>
                                    _CategoryThumbSmall(category: category),
                              )
                            : _CategoryThumbSmall(category: category),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Row 3: @username · age
                Row(
                  children: [
                    Text(
                      '@${(issue.createdByName ?? 'unknown').replaceAll(' ', '').toLowerCase()}',
                      style: GoogleFonts.sourceCodePro(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '·',
                      style: GoogleFonts.sourceCodePro(
                        fontSize: 11,
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _daysOld == 0
                          ? 'Today'
                          : _daysOld == 1
                              ? '1 day ago'
                              : '$_daysOld days ago',
                      style: GoogleFonts.sourceCodePro(
                        fontSize: 11,
                        fontWeight: _isOverdue ? FontWeight.w700 : FontWeight.w400,
                        color: _isOverdue
                            ? AppColors.statusOpen
                            : AppColors.secondaryText,
                      ),
                    ),
                    if (_isOverdue) ...[
                      const SizedBox(width: 6),
                      Text(
                        '⚠ OVERDUE',
                        style: GoogleFonts.sourceCodePro(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.statusOpen,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),

                // Row 4: Upvote + Comment counts
                Row(
                  children: [
                    const Icon(Icons.sports_mma,
                        size: 14, color: AppColors.secondaryText),
                    const SizedBox(width: 4),
                    Text(
                      '${issue.upvoteCount}',
                      style: GoogleFonts.sourceCodePro(
                        fontSize: 11,
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Icon(Icons.comment_outlined,
                        size: 14, color: AppColors.secondaryText),
                    const SizedBox(width: 4),
                    Text(
                      '${issue.commentCount}',
                      style: GoogleFonts.sourceCodePro(
                        fontSize: 11,
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const Spacer(),
                    // Only show Take Action for non-resolved/rejected issues
                    if (!issue.isResolved &&
                        issue.status != IssueStatus.rejected)
                      GestureDetector(
                        onTap: () => setState(() => _expanded = !_expanded),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              AppStrings.takeAction,
                              style: GoogleFonts.sourceCodePro(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.accent,
                              ),
                            ),
                            const SizedBox(width: 4),
                            AnimatedRotation(
                              turns: _expanded ? -0.5 : 0,
                              duration: const Duration(milliseconds: 200),
                              child: const Icon(Icons.keyboard_arrow_down,
                                  size: 16, color: AppColors.accent),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),

          // Expandable Take Action Panel
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            firstCurve: Curves.easeOut,
            secondCurve: Curves.easeIn,
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF9F5EE),
                border: Border(
                  top: BorderSide(color: AppColors.cardDivider),
                  bottom: BorderSide(color: AppColors.cardDivider),
                ),
              ),
              child: TakeActionPanel(
                issueId: issue.id,
                authorityId: widget.authorityId,
                onSubmitted: () {
                  setState(() => _expanded = false);
                  widget.onActionSubmitted();
                },
                onCancel: () => setState(() => _expanded = false),
              ),
            ),
          ),

          const Divider(height: 1, thickness: 1, color: AppColors.cardDivider),
        ],
      ),
    );
  }
}

// ── Tier Badge ───────────────────────────────────────────────────────────────

class _TierBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _TierBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Text(
        label,
        style: GoogleFonts.sourceCodePro(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ── Status Badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: GoogleFonts.sourceCodePro(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

// ── Category Thumb Small ──────────────────────────────────────────────────────

class _CategoryThumbSmall extends StatelessWidget {
  final IssueCategoryInfo category;
  const _CategoryThumbSmall({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: category.color.withOpacity(0.15),
      child: Center(
        child: Icon(category.icon, color: category.color, size: 24),
      ),
    );
  }
}
