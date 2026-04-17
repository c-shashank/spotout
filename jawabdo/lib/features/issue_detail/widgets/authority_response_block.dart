import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../models/authority_action.dart';

class AuthorityResponseBlock extends StatelessWidget {
  final List<AuthorityAction> actions;

  const AuthorityResponseBlock({super.key, required this.actions});

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();

    return Column(
      children: actions.map((action) => _ResponseCard(action: action)).toList(),
    );
  }
}

class _ResponseCard extends StatelessWidget {
  final AuthorityAction action;

  const _ResponseCard({required this.action});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: const BoxDecoration(
        color: AppColors.authorityResponseBg,
        border: Border(
          left: BorderSide(color: AppColors.authorityResponseBorder, width: 4),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.officialResponse,
            style: GoogleFonts.sourceCodePro(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText,
            ),
          ),
          if (action.authorityDepartment != null || action.authorityWard != null) ...[
            const SizedBox(height: 2),
            Text(
              [action.authorityDepartment, action.authorityWard]
                  .where((e) => e != null && e.isNotEmpty)
                  .join(' · '),
              style: GoogleFonts.sourceCodePro(
                fontSize: 12,
                color: AppColors.secondaryText,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _statusColor(action.actionType).withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Status: ${action.actionLabel}',
              style: GoogleFonts.sourceCodePro(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _statusColor(action.actionType),
              ),
            ),
          ),
          if (action.note != null && action.note!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '"${action.note}"',
              style: GoogleFonts.sourceCodePro(
                fontSize: 12,
                color: AppColors.primaryText,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (action.mediaUrl != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                action.mediaUrl!,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            timeago.format(action.createdAt),
            style: GoogleFonts.sourceCodePro(
              fontSize: 11,
              color: AppColors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(AuthorityActionType type) {
    switch (type) {
      case AuthorityActionType.resolved:
        return AppColors.statusResolved;
      case AuthorityActionType.rejected:
        return AppColors.statusRejected;
      case AuthorityActionType.inProgress:
        return AppColors.statusInProgress;
      default:
        return AppColors.tierMunicipal;
    }
  }
}
