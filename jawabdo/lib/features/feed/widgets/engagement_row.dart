import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/issue.dart';

class EngagementRow extends StatelessWidget {
  final Issue issue;
  final VoidCallback onUpvote;
  final VoidCallback onDownvote;
  final VoidCallback onBookmark;

  const EngagementRow({
    super.key,
    required this.issue,
    required this.onUpvote,
    required this.onDownvote,
    required this.onBookmark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      child: Row(
        children: [
          // Upvote — fist image
          GestureDetector(
            onTap: onUpvote,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/fist.png',
                  width: 18,
                  height: 18,
                  color: issue.userHasUpvoted == true
                      ? AppColors.accent
                      : AppColors.secondaryText,
                  colorBlendMode: BlendMode.srcIn,
                ),
                const SizedBox(width: 4),
                Text(
                  '${issue.upvoteCount}',
                  style: GoogleFonts.sourceCodePro(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: issue.userHasUpvoted == true
                        ? AppColors.accent
                        : AppColors.primaryText,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Downvote
          _ActionButton(
            icon: Icons.thumb_down_alt_outlined,
            count: issue.downvoteCount,
            active: issue.userHasDownvoted == true,
            activeColor: AppColors.grey,
            onTap: onDownvote,
          ),
          const SizedBox(width: 12),
          // Timestamp
          Text(
            timeago.format(issue.createdAt),
            style: GoogleFonts.sourceCodePro(
              fontSize: 11,
              color: AppColors.grey,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Container(
              width: 1,
              height: 16,
              color: AppColors.cardDivider,
            ),
          ),
          // Share
          GestureDetector(
            onTap: () => Share.share(
              'Check out this civic issue on Jawab Do: ${issue.title}\nhttps://jawabdo.in/issues/${issue.id}',
            ),
            child: const Icon(
              Icons.reply,
              color: AppColors.secondaryText,
              size: 20,
              textDirection: TextDirection.rtl,
            ),
          ),
          const SizedBox(width: 14),
          // Bookmark
          GestureDetector(
            onTap: onBookmark,
            child: Icon(
              issue.userHasBookmarked == true
                  ? Icons.bookmark
                  : Icons.bookmark_border,
              color: issue.userHasBookmarked == true
                  ? AppColors.accent
                  : AppColors.secondaryText,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          // Three dots
          GestureDetector(
            onTap: () => _showMoreSheet(context),
            child: const Icon(
              Icons.more_horiz,
              color: AppColors.secondaryText,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  void _showMoreSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: Text(
                'Report Issue',
                style: GoogleFonts.sourceCodePro(fontSize: 14),
              ),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: Text(
                'Copy Link',
                style: GoogleFonts.sourceCodePro(fontSize: 14),
              ),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline),
              title: Text(
                'Share to WhatsApp',
                style: GoogleFonts.sourceCodePro(fontSize: 14),
              ),
              onTap: () async {
                final url = Uri.parse(
                    'https://wa.me/?text=${Uri.encodeComponent('Check this civic issue: https://jawabdo.in/issues/${issue.id}')}');
                if (await canLaunchUrl(url)) await launchUrl(url);
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final int count;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.count,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: active ? activeColor : AppColors.secondaryText,
          ),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: GoogleFonts.sourceCodePro(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: active ? activeColor : AppColors.primaryText,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
