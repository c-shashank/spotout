import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/ghmc_wards.dart';
import '../../../core/constants/issue_categories.dart';
import '../../../core/services/db_service.dart';
import '../../../models/authority_action.dart';
import '../../../models/comment.dart';
import '../../../models/issue.dart';
import '../../feed/widgets/priority_badge.dart';
import '../../feed/widgets/tag_pill.dart';
import '../widgets/authority_response_block.dart';
import '../widgets/comment_section.dart';
import '../widgets/escalation_stepper.dart';

class IssueDetailScreen extends StatefulWidget {
  final String issueId;
  final String userId;
  final String? userAvatar;

  const IssueDetailScreen({
    super.key,
    required this.issueId,
    required this.userId,
    this.userAvatar,
  });

  @override
  State<IssueDetailScreen> createState() => _IssueDetailScreenState();
}

class _IssueDetailScreenState extends State<IssueDetailScreen> {
  final _db = DbService();
  final _commentController = TextEditingController();
  final _commentFocusNode = FocusNode();

  Issue? _issue;
  List<Comment> _comments = [];
  List<AuthorityAction> _actions = [];
  bool _loading = true;
  String _commentSort = 'recent';
  String? _replyingToId;
  String? _replyingToName;
  bool _mapExpanded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final issue = await _db.fetchIssue(widget.issueId);
    if (issue == null) {
      setState(() => _loading = false);
      return;
    }
    final userVote = await _db.getUserVote(widget.issueId, widget.userId);
    final bookmarked = await _db.isBookmarked(widget.issueId, widget.userId);
    final comments = await _db.fetchComments(widget.issueId, sort: _commentSort);
    final actions = await _db.fetchAuthorityActions(widget.issueId);
    await _db.incrementViewCount(widget.issueId);

    setState(() {
      _issue = issue.copyWith(
        userHasUpvoted: userVote == 'up',
        userHasDownvoted: userVote == 'down',
        userHasBookmarked: bookmarked,
      );
      _comments = comments;
      _actions = actions;
      _loading = false;
    });
  }

  Future<void> _vote(String type) async {
    if (_issue == null) return;
    final issue = _issue!;

    Issue updated;
    if (type == 'up') {
      updated = issue.copyWith(
        upvoteCount: issue.userHasUpvoted == true
            ? issue.upvoteCount - 1
            : issue.upvoteCount + 1,
        userHasUpvoted: issue.userHasUpvoted != true,
        userHasDownvoted: false,
        downvoteCount: issue.userHasDownvoted == true
            ? issue.downvoteCount - 1
            : issue.downvoteCount,
      );
    } else {
      updated = issue.copyWith(
        downvoteCount: issue.userHasDownvoted == true
            ? issue.downvoteCount - 1
            : issue.downvoteCount + 1,
        userHasDownvoted: issue.userHasDownvoted != true,
        userHasUpvoted: false,
        upvoteCount: issue.userHasUpvoted == true
            ? issue.upvoteCount - 1
            : issue.upvoteCount,
      );
    }
    setState(() => _issue = updated);

    try {
      if (type == 'up') {
        if (issue.userHasUpvoted == true) {
          await _db.removeVote(issueId: widget.issueId, userId: widget.userId);
        } else {
          await _db.upsertVote(
              issueId: widget.issueId, userId: widget.userId, voteType: 'up');
        }
      } else {
        if (issue.userHasDownvoted == true) {
          await _db.removeVote(issueId: widget.issueId, userId: widget.userId);
        } else {
          await _db.upsertVote(
              issueId: widget.issueId, userId: widget.userId, voteType: 'down');
        }
      }
    } catch (_) {
      setState(() => _issue = issue); // revert
    }
  }

  Future<void> _toggleBookmark() async {
    if (_issue == null) return;
    final was = _issue!.userHasBookmarked ?? false;
    setState(() => _issue = _issue!.copyWith(userHasBookmarked: !was));
    try {
      await _db.toggleBookmark(widget.issueId, widget.userId);
    } catch (_) {
      setState(() => _issue = _issue!.copyWith(userHasBookmarked: was));
    }
  }

  Future<void> _addComment(String text, String? parentId) async {
    try {
      final comment = await _db.addComment(
        issueId: widget.issueId,
        userId: widget.userId,
        text: text,
        parentCommentId: parentId,
      );
      setState(() {
        if (parentId == null) {
          _comments = [comment, ..._comments];
        } else {
          final idx = _comments.indexWhere((c) => c.id == parentId);
          if (idx != -1) {
            final parent = _comments[idx];
            _comments[idx] = parent.copyWith(
              replies: [...parent.replies, comment],
            );
          }
        }
        _issue = _issue?.copyWith(commentCount: (_issue?.commentCount ?? 0) + 1);
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.appName), centerTitle: true),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      );
    }
    if (_issue == null) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.appName), centerTitle: true),
        body: const Center(child: Text('Issue not found')),
      );
    }

    final issue = _issue!;
    final category = categoryFromValue(issue.category);
    final ward = ghmcWards.firstWhere(
      (w) => w.code == issue.wardId,
      orElse: () => GhmcWard(code: issue.wardId, name: issue.wardId, circle: ''),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              issue.userHasBookmarked == true ? Icons.bookmark : Icons.bookmark_border,
              color: issue.userHasBookmarked == true
                  ? AppColors.accent
                  : AppColors.primaryText,
            ),
            onPressed: _toggleBookmark,
          ),
          IconButton(
            icon: const Icon(Icons.reply, textDirection: TextDirection.rtl),
            onPressed: () => Share.share(
              'Check this civic issue on Jawab Do: ${issue.title}\nhttps://jawabdo.in/issues/${issue.id}',
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Photo Carousel
                if (issue.mediaUrls.isNotEmpty) _PhotoCarousel(urls: issue.mediaUrls),

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tags + Priority
                      Row(
                        children: [
                          TagPill(label: category.label, dotColor: category.color),
                          const SizedBox(width: 6),
                          TagPill(label: ward.name),
                          const Spacer(),
                          if (issue.priorityFlag) const PriorityBadge(),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Title
                      Text(
                        issue.title,
                        style: GoogleFonts.sourceCodePro(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Description
                      Text(
                        issue.description,
                        style: GoogleFonts.sourceCodePro(
                          fontSize: 13,
                          color: AppColors.secondaryText,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Username + Timestamp
                      Row(
                        children: [
                          Text(
                            '@${(issue.createdByName ?? 'unknown').replaceAll(' ', '').toLowerCase()}',
                            style: GoogleFonts.sourceCodePro(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.accent,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            issue.createdAt.toLocal().toString().substring(0, 16),
                            style: GoogleFonts.sourceCodePro(
                              fontSize: 11,
                              color: AppColors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),
                const Divider(height: 1, thickness: 1, color: AppColors.cardDivider),

                // GPS Mini-Map
                GestureDetector(
                  onTap: () => setState(() => _mapExpanded = !_mapExpanded),
                  child: SizedBox(
                    height: _mapExpanded ? 300 : 150,
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(issue.locationLat, issue.locationLng),
                        zoom: 15,
                      ),
                      markers: {
                        Marker(
                          markerId: const MarkerId('issue'),
                          position: LatLng(issue.locationLat, issue.locationLng),
                        ),
                      },
                      zoomControlsEnabled: _mapExpanded,
                      scrollGesturesEnabled: _mapExpanded,
                      zoomGesturesEnabled: _mapExpanded,
                    ),
                  ),
                ),

                if (issue.addressLabel.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                    child: Text(
                      issue.addressLabel,
                      style: GoogleFonts.sourceCodePro(
                        fontSize: 11,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ),

                const Divider(height: 16, thickness: 1, color: AppColors.cardDivider),

                // Escalation Stepper
                EscalationStepper(
                  currentTier: issue.escalationTier,
                  history: issue.escalationHistory,
                ),

                const Divider(height: 1, thickness: 1, color: AppColors.cardDivider),

                // Engagement Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: _EngagementBtn(
                          icon: Icons.sports_mma,
                          label: '${AppStrings.upvote}  ${issue.upvoteCount}',
                          active: issue.userHasUpvoted == true,
                          onTap: () => _vote('up'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _EngagementBtn(
                          icon: Icons.thumb_down_alt_outlined,
                          label: '${AppStrings.downvote}  ${issue.downvoteCount}',
                          active: issue.userHasDownvoted == true,
                          onTap: () => _vote('down'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _EngagementBtn(
                          icon: Icons.reply,
                          label: AppStrings.share,
                          onTap: () => Share.share(
                              'https://jawabdo.in/issues/${issue.id}'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _EngagementBtn(
                          icon: issue.userHasBookmarked == true
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          label: AppStrings.bookmark,
                          active: issue.userHasBookmarked == true,
                          onTap: _toggleBookmark,
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, thickness: 1, color: AppColors.cardDivider),

                // Authority Responses
                if (_actions.isNotEmpty) ...[
                  AuthorityResponseBlock(actions: _actions),
                  const Divider(height: 1, thickness: 1, color: AppColors.cardDivider),
                ],

                // Comments
                CommentSection(
                  comments: _comments,
                  currentUserId: widget.userId,
                  currentUserAvatar: widget.userAvatar,
                  sort: _commentSort,
                  onAddComment: _addComment,
                  onUpvoteComment: (id) async {
                    await _db.upvoteComment(id);
                  },
                  onSortChanged: (s) async {
                    setState(() => _commentSort = s);
                    final sorted = await _db.fetchComments(
                      widget.issueId,
                      sort: s,
                    );
                    setState(() => _comments = sorted);
                  },
                ),
              ],
            ),
          ),

          // Sticky comment input bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Divider(height: 1, thickness: 1, color: AppColors.cardDivider),
                CommentInputBar(
                  controller: _commentController,
                  focusNode: _commentFocusNode,
                  replyingToName: _replyingToName,
                  avatarUrl: widget.userAvatar,
                  onSubmit: () {
                    _addComment(_commentController.text.trim(), _replyingToId);
                    _commentController.clear();
                    setState(() {
                      _replyingToId = null;
                      _replyingToName = null;
                    });
                  },
                  onCancelReply: () => setState(() {
                    _replyingToId = null;
                    _replyingToName = null;
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Photo Carousel ───────────────────────────────────────────────────────────

class _PhotoCarousel extends StatefulWidget {
  final List<String> urls;
  const _PhotoCarousel({required this.urls});

  @override
  State<_PhotoCarousel> createState() => _PhotoCarouselState();
}

class _PhotoCarouselState extends State<_PhotoCarousel> {
  final _controller = PageController();
  int _current = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        SizedBox(
          height: 250,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.urls.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) => CachedNetworkImage(
              imageUrl: widget.urls[i],
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),
        ),
        if (widget.urls.length > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                widget.urls.length,
                (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _current == i ? 10 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _current == i ? AppColors.accent : Colors.white70,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Engagement Button ────────────────────────────────────────────────────────

class _EngagementBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _EngagementBtn({
    required this.icon,
    required this.label,
    this.active = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.accent.withOpacity(0.1) : AppColors.tagPillBg,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: active ? AppColors.accent : AppColors.secondaryText,
              textDirection: icon == Icons.reply ? TextDirection.rtl : null,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.sourceCodePro(
                fontSize: 10,
                color: active ? AppColors.accent : AppColors.secondaryText,
                fontWeight: FontWeight.w500,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
