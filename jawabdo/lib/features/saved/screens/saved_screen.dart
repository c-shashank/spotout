import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jawabdo/core/constants/app_colors.dart';
import 'package:jawabdo/core/constants/app_strings.dart';
import 'package:jawabdo/core/services/db_service.dart';
import 'package:jawabdo/features/feed/widgets/issue_card.dart';
import 'package:jawabdo/features/issue_detail/screens/issue_detail_screen.dart';
import 'package:jawabdo/models/issue.dart';
import 'package:jawabdo/widgets/empty_state.dart';
import 'package:jawabdo/widgets/skeleton_card.dart';

class SavedScreen extends StatefulWidget {
  final String userId;

  const SavedScreen({super.key, required this.userId});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  final _db = DbService();
  List<Issue> _bookmarked = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final issues = await _db.fetchBookmarkedIssues(widget.userId);
      setState(() {
        _bookmarked = issues;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _navigateToDetail(Issue issue) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IssueDetailScreen(
          issueId: issue.id,
          userId: widget.userId,
        ),
      ),
    );
  }

  Future<void> _removeBookmark(Issue issue) async {
    setState(() =>
        _bookmarked = _bookmarked.where((i) => i.id != issue.id).toList());
    try {
      await _db.toggleBookmark(issue.id, widget.userId);
    } catch (_) {
      // Re-insert at original position on failure
      setState(() => _bookmarked = [..._bookmarked, issue]);
    }
  }

  Future<void> _handleVote(Issue issue, String type) async {
    final idx = _bookmarked.indexWhere((i) => i.id == issue.id);
    if (idx == -1) return;
    final current = _bookmarked[idx];
    final wasUp = current.userHasUpvoted == true;
    final wasDown = current.userHasDownvoted == true;

    Issue updated;
    if (type == 'up') {
      updated = current.copyWith(
        upvoteCount: wasUp ? current.upvoteCount - 1 : current.upvoteCount + 1,
        userHasUpvoted: !wasUp,
        userHasDownvoted: false,
        downvoteCount:
            wasDown ? current.downvoteCount - 1 : current.downvoteCount,
      );
    } else {
      updated = current.copyWith(
        downvoteCount:
            wasDown ? current.downvoteCount - 1 : current.downvoteCount + 1,
        userHasDownvoted: !wasDown,
        userHasUpvoted: false,
        upvoteCount: wasUp ? current.upvoteCount - 1 : current.upvoteCount,
      );
    }
    setState(() => _bookmarked[idx] = updated);

    try {
      if (type == 'up') {
        if (wasUp) {
          await _db.removeVote(issueId: issue.id, userId: widget.userId);
        } else {
          await _db.upsertVote(
              issueId: issue.id, userId: widget.userId, voteType: 'up');
        }
      } else {
        if (wasDown) {
          await _db.removeVote(issueId: issue.id, userId: widget.userId);
        } else {
          await _db.upsertVote(
              issueId: issue.id, userId: widget.userId, voteType: 'down');
        }
      }
    } catch (_) {
      setState(() => _bookmarked[idx] = current);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: Text(
          AppStrings.saved,
          style: GoogleFonts.sourceCodePro(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryText,
          ),
        ),
      ),
      body: _loading
          ? ListView.builder(
              itemCount: 4,
              itemBuilder: (_, __) => const SkeletonCard(),
            )
          : RefreshIndicator(
              color: AppColors.accent,
              onRefresh: _load,
              child: _bookmarked.isEmpty
                  ? LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: constraints.maxHeight,
                            child: const EmptyState(
                              icon: Icons.bookmark_border,
                              title: AppStrings.savedEmpty,
                              subtitle: AppStrings.savedEmptySub,
                            ),
                          ),
                        );
                      },
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _bookmarked.length,
                      itemBuilder: (_, i) {
                        final issue = _bookmarked[i];
                        return Dismissible(
                          key: Key('bookmark_${issue.id}'),
                          direction: DismissDirection.endToStart,
                          background: _SwipeBackground(),
                          confirmDismiss: (_) async {
                            return true;
                          },
                          onDismissed: (_) => _removeBookmark(issue),
                          child: IssueCard(
                            issue: issue.copyWith(userHasBookmarked: true),
                            onTap: () => _navigateToDetail(issue),
                            onUpvote: () => _handleVote(issue, 'up'),
                            onDownvote: () => _handleVote(issue, 'down'),
                            onBookmark: () => _removeBookmark(issue),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

// ── Swipe Background ──────────────────────────────────────────────────────────

class _SwipeBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      color: AppColors.accent.withOpacity(0.12),
      padding: const EdgeInsets.only(right: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bookmark_remove, color: AppColors.accent, size: 24),
          const SizedBox(height: 4),
          Text(
            'Remove',
            style: GoogleFonts.sourceCodePro(
              fontSize: 10,
              color: AppColors.accent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
