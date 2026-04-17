import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:jawabdo/core/constants/app_colors.dart';
import 'package:jawabdo/core/constants/app_strings.dart';
import 'package:jawabdo/core/constants/ghmc_wards.dart';
import 'package:jawabdo/core/constants/issue_categories.dart';
import 'package:jawabdo/core/services/db_service.dart';
import 'package:jawabdo/models/authority_action.dart';
import 'package:jawabdo/models/comment.dart';
import 'package:jawabdo/models/issue.dart';
import 'package:jawabdo/models/user.dart';
import 'package:jawabdo/features/feed/widgets/priority_badge.dart';
import 'package:jawabdo/features/feed/widgets/tag_pill.dart';
import 'package:jawabdo/features/issue_detail/widgets/authority_response_block.dart';
import 'package:jawabdo/features/issue_detail/widgets/comment_section.dart';
import 'package:jawabdo/features/issue_detail/widgets/escalation_stepper.dart';

class AuthorityIssueDetail extends StatefulWidget {
  final String issueId;
  final Jawab DoUser authority;

  const AuthorityIssueDetail({
    super.key,
    required this.issueId,
    required this.authority,
  });

  @override
  State<AuthorityIssueDetail> createState() => _AuthorityIssueDetailState();
}

class _AuthorityIssueDetailState extends State<AuthorityIssueDetail> {
  final _db = DbService();

  Issue? _issue;
  List<Comment> _comments = [];
  List<AuthorityAction> _actions = []; // public + internal
  bool _loading = true;
  String _commentSort = 'recent';
  bool _mapExpanded = false;

  // Authority controls
  String? _assignedDept;
  final _internalNoteController = TextEditingController();
  bool _submittingNote = false;
  String? _noteError;

  String? _escalateReason;
  bool _escalating = false;
  String? _escalateError;

  static const _departments = [
    'GHMC',
    'HMWSSB',
    'TSSPDCL',
    'TSRTC',
    'Revenue Dept',
  ];

  static const _escalateReasons = [
    'No action taken for > 14 days',
    'Issue affects public safety',
    'Requires higher authority approval',
    'Repeated non-compliance',
    'Media/NGO attention needed',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _internalNoteController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final issue = await _db.fetchIssue(widget.issueId);
      if (issue == null) {
        setState(() => _loading = false);
        return;
      }
      final comments =
          await _db.fetchComments(widget.issueId, sort: _commentSort);
      // Include internal actions for authority view
      final actions = await _db.fetchAuthorityActions(
        widget.issueId,
        includeInternal: true,
      );
      await _db.incrementViewCount(widget.issueId);
      setState(() {
        _issue = issue;
        _comments = comments;
        _actions = actions;
        _assignedDept = issue.assignedTo;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _submitInternalNote() async {
    final text = _internalNoteController.text.trim();
    if (text.isEmpty) {
      setState(() => _noteError = 'Note cannot be empty.');
      return;
    }
    setState(() {
      _submittingNote = true;
      _noteError = null;
    });
    try {
      await _db.addAuthorityAction(
        issueId: widget.issueId,
        authorityId: widget.authority.id,
        actionType: 'comment',
        note: text,
        isInternal: true,
      );
      _internalNoteController.clear();
      await _load();
    } catch (_) {
      setState(() {
        _noteError = AppStrings.networkError;
        _submittingNote = false;
      });
    }
  }

  Future<void> _assignDepartment(String dept) async {
    setState(() => _assignedDept = dept);
    try {
      // Store assignment as an internal authority action comment
      await _db.addAuthorityAction(
        issueId: widget.issueId,
        authorityId: widget.authority.id,
        actionType: 'comment',
        note: 'Assigned to department: $dept',
        isInternal: true,
      );
    } catch (_) {}
  }

  Future<void> _escalateToNextTier() async {
    if (_escalateReason == null) {
      setState(() => _escalateError = 'Please select a reason.');
      return;
    }
    if (_issue == null) return;

    final currentTier = _issue!.escalationTier;
    const tiers = EscalationTier.values;
    final currentIdx = tiers.indexOf(currentTier);
    if (currentIdx >= tiers.length - 1) {
      setState(
          () => _escalateError = 'Already at the highest escalation tier.');
      return;
    }

    setState(() {
      _escalating = true;
      _escalateError = null;
    });

    try {
      await _db.addAuthorityAction(
        issueId: widget.issueId,
        authorityId: widget.authority.id,
        actionType: 'escalated',
        note: _escalateReason,
      );
      await _load();
      setState(() {
        _escalating = false;
        _escalateReason = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Issue escalated successfully.',
              style: GoogleFonts.sourceCodePro(fontSize: 12),
            ),
            backgroundColor: AppColors.statusResolved,
          ),
        );
      }
    } catch (_) {
      setState(() {
        _escalateError = AppStrings.networkError;
        _escalating = false;
      });
    }
  }

  Future<void> _addComment(String text, String? parentId) async {
    try {
      final comment = await _db.addComment(
        issueId: widget.issueId,
        userId: widget.authority.id,
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
            _comments[idx] =
                parent.copyWith(replies: [...parent.replies, comment]);
          }
        }
        _issue = _issue?.copyWith(
            commentCount: (_issue?.commentCount ?? 0) + 1);
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            AppStrings.appName,
            style: GoogleFonts.sourceCodePro(
              fontWeight: FontWeight.w700,
              color: AppColors.accent,
            ),
          ),
          backgroundColor: AppColors.background,
          iconTheme: const IconThemeData(color: AppColors.primaryText),
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: AppColors.cardDivider),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      );
    }

    if (_issue == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.appName,
              style: GoogleFonts.sourceCodePro(color: AppColors.accent)),
          backgroundColor: AppColors.background,
          elevation: 0,
        ),
        body: const Center(child: Text('Issue not found')),
      );
    }

    final issue = _issue!;
    final category = categoryFromValue(issue.category);
    final ward = ghmcWards.firstWhere(
      (w) => w.code == issue.wardId,
      orElse: () =>
          GhmcWard(code: issue.wardId, name: issue.wardId, circle: ''),
    );
    final publicActions =
        _actions.where((a) => !a.isInternal).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primaryText),
        title: Text(
          AppStrings.appName,
          style: GoogleFonts.sourceCodePro(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.accent,
            letterSpacing: 1.0,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.secondaryText),
            onPressed: _load,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.reply, textDirection: TextDirection.rtl),
            color: AppColors.secondaryText,
            onPressed: () => Share.share(
              'JAWAB DO issue: ${issue.title}\nhttps://jawabdo.in/issues/${issue.id}',
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.cardDivider),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Photo Carousel ──────────────────────────────────────────────
            if (issue.mediaUrls.isNotEmpty)
              _PhotoCarousel(urls: issue.mediaUrls),

            // ── Issue Header ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      TagPill(label: category.label, dotColor: category.color),
                      TagPill(label: ward.name),
                      if (issue.priorityFlag) const PriorityBadge(),
                      _StatusChip(status: issue.status),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    issue.title,
                    style: GoogleFonts.sourceCodePro(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryText,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    issue.description,
                    style: GoogleFonts.sourceCodePro(
                      fontSize: 13,
                      color: AppColors.secondaryText,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
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
                        timeago.format(issue.createdAt),
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

            // ── Map ─────────────────────────────────────────────────────────
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

            const Divider(
                height: 16, thickness: 1, color: AppColors.cardDivider),

            // ── Escalation Stepper ──────────────────────────────────────────
            EscalationStepper(
              currentTier: issue.escalationTier,
              history: issue.escalationHistory,
            ),
            const Divider(height: 1, thickness: 1, color: AppColors.cardDivider),

            // ── Engagement counts ───────────────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  _EngagementStat(
                      icon: Icons.sports_mma,
                      value: '${issue.upvoteCount}',
                      label: 'Upvotes'),
                  const SizedBox(width: 20),
                  _EngagementStat(
                      icon: Icons.comment_outlined,
                      value: '${issue.commentCount}',
                      label: 'Comments'),
                  const SizedBox(width: 20),
                  _EngagementStat(
                      icon: Icons.remove_red_eye_outlined,
                      value: '${issue.viewCount}',
                      label: 'Views'),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: AppColors.cardDivider),

            // ── Public authority responses ──────────────────────────────────
            if (publicActions.isNotEmpty) ...[
              AuthorityResponseBlock(actions: publicActions),
              const Divider(
                  height: 1, thickness: 1, color: AppColors.cardDivider),
            ],

            // ── Citizen Comments ────────────────────────────────────────────
            CommentSection(
              comments: _comments,
              currentUserId: widget.authority.id,
              currentUserAvatar: widget.authority.avatarUrl,
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

            const Divider(
                height: 16, thickness: 4, color: AppColors.cardDivider),

            // ══════════════════════════════════════════════════════════════
            //  AUTHORITY VIEW SECTION
            // ══════════════════════════════════════════════════════════════
            const _AuthoritySectionHeader(label: AppStrings.authorityView),

            // ── Full Action History Log ─────────────────────────────────────
            if (_actions.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Text(
                  'Action History',
                  style: GoogleFonts.sourceCodePro(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryText,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _ActionHistoryTimeline(actions: _actions),
            ],

            // ── Assign to Department ────────────────────────────────────────
            _AuthorityBlock(
              title: AppStrings.assignToDepartment,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.cardDivider),
                  borderRadius: BorderRadius.circular(6),
                  color: AppColors.background,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _departments.contains(_assignedDept)
                        ? _assignedDept
                        : null,
                    hint: Text(
                      'Select department...',
                      style: GoogleFonts.sourceCodePro(
                        fontSize: 13,
                        color: AppColors.grey,
                      ),
                    ),
                    isExpanded: true,
                    style: GoogleFonts.sourceCodePro(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryText,
                    ),
                    items: _departments
                        .map((d) => DropdownMenuItem(
                              value: d,
                              child: Text(d,
                                  style: GoogleFonts.sourceCodePro(
                                      fontSize: 13)),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) _assignDepartment(val);
                    },
                  ),
                ),
              ),
            ),

            // ── Add Internal Note ───────────────────────────────────────────
            _AuthorityBlock(
              title: AppStrings.addInternalNote,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _internalNoteController,
                    enabled: !_submittingNote,
                    maxLines: 3,
                    minLines: 2,
                    style: GoogleFonts.sourceCodePro(
                      fontSize: 13,
                      color: AppColors.primaryText,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Internal note (not visible to citizens)...',
                      hintStyle: GoogleFonts.sourceCodePro(
                        fontSize: 12,
                        color: AppColors.grey,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide:
                            const BorderSide(color: AppColors.cardDivider),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide:
                            const BorderSide(color: AppColors.cardDivider),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(
                            color: AppColors.accent, width: 1.5),
                      ),
                    ),
                  ),
                  if (_noteError != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _noteError!,
                      style: GoogleFonts.sourceCodePro(
                        fontSize: 11,
                        color: AppColors.statusOpen,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submittingNote ? null : _submitInternalNote,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        elevation: 0,
                      ),
                      child: _submittingNote
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Submit Note',
                              style: GoogleFonts.sourceCodePro(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Escalate to Next Tier ───────────────────────────────────────
            if (!issue.isResolved &&
                issue.escalationTier != EscalationTier.mediaNgo)
              _AuthorityBlock(
                title: AppStrings.escalateToNextTier,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.cardDivider),
                        borderRadius: BorderRadius.circular(6),
                        color: AppColors.background,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _escalateReason,
                          hint: Text(
                            'Select reason...',
                            style: GoogleFonts.sourceCodePro(
                              fontSize: 13,
                              color: AppColors.grey,
                            ),
                          ),
                          isExpanded: true,
                          style: GoogleFonts.sourceCodePro(
                            fontSize: 13,
                            color: AppColors.primaryText,
                          ),
                          items: _escalateReasons
                              .map((r) => DropdownMenuItem(
                                    value: r,
                                    child: Text(r,
                                        style: GoogleFonts.sourceCodePro(
                                            fontSize: 12)),
                                  ))
                              .toList(),
                          onChanged: _escalating
                              ? null
                              : (val) => setState(() {
                                    _escalateReason = val;
                                    _escalateError = null;
                                  }),
                        ),
                      ),
                    ),
                    if (_escalateError != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        _escalateError!,
                        style: GoogleFonts.sourceCodePro(
                          fontSize: 11,
                          color: AppColors.statusOpen,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed:
                            _escalating ? null : _escalateToNextTier,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              AppColors.tierState.withOpacity(0.9),
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          elevation: 0,
                        ),
                        icon: _escalating
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.arrow_upward, size: 16),
                        label: Text(
                          AppStrings.escalateToNextTier,
                          style: GoogleFonts.sourceCodePro(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── Photo Carousel ────────────────────────────────────────────────────────────

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
                    color:
                        _current == i ? AppColors.accent : Colors.white70,
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

// ── Status Chip ───────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final IssueStatus status;
  const _StatusChip({required this.status});

  Color get _color {
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

  String get _label {
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _color.withOpacity(0.35)),
      ),
      child: Text(
        _label,
        style: GoogleFonts.sourceCodePro(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: _color,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

// ── Engagement Stat ───────────────────────────────────────────────────────────

class _EngagementStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _EngagementStat(
      {required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.secondaryText),
        const SizedBox(width: 4),
        Text(
          value,
          style: GoogleFonts.sourceCodePro(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryText,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: GoogleFonts.sourceCodePro(
            fontSize: 11,
            color: AppColors.secondaryText,
          ),
        ),
      ],
    );
  }
}

// ── Authority Section Header ──────────────────────────────────────────────────

class _AuthoritySectionHeader extends StatelessWidget {
  final String label;
  const _AuthoritySectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.accent.withOpacity(0.06),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.admin_panel_settings,
              size: 16, color: AppColors.accent),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.sourceCodePro(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.accent,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Authority Block ───────────────────────────────────────────────────────────

class _AuthorityBlock extends StatelessWidget {
  final String title;
  final Widget child;
  const _AuthorityBlock({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.sourceCodePro(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.secondaryText,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          child,
          const SizedBox(height: 8),
          const Divider(height: 1, color: AppColors.cardDivider),
        ],
      ),
    );
  }
}

// ── Action History Timeline ───────────────────────────────────────────────────

class _ActionHistoryTimeline extends StatelessWidget {
  final List<AuthorityAction> actions;
  const _ActionHistoryTimeline({required this.actions});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        children: List.generate(actions.length, (i) {
          final action = actions[i];
          final isLast = i == actions.length - 1;
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timeline column
                SizedBox(
                  width: 32,
                  child: Column(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _actionColor(action.actionType)
                              .withOpacity(0.15),
                          border: Border.all(
                            color: _actionColor(action.actionType),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          _actionIcon(action.actionType),
                          size: 11,
                          color: _actionColor(action.actionType),
                        ),
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 1.5,
                            color: AppColors.cardDivider,
                            margin:
                                const EdgeInsets.symmetric(vertical: 3),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color:
                                    _actionColor(action.actionType)
                                        .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                action.actionLabel.toUpperCase() +
                                    (action.isInternal
                                        ? ' [INTERNAL]'
                                        : ''),
                                style: GoogleFonts.sourceCodePro(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      _actionColor(action.actionType),
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (action.authorityName != null ||
                            action.authorityDepartment != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            [
                              action.authorityName,
                              action.authorityDepartment
                            ]
                                .where((s) =>
                                    s != null && s.isNotEmpty)
                                .join(' · '),
                            style: GoogleFonts.sourceCodePro(
                              fontSize: 11,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ],
                        if (action.note != null &&
                            action.note!.isNotEmpty) ...[
                          const SizedBox(height: 4),
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
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: CachedNetworkImage(
                              imageUrl: action.mediaUrl!,
                              height: 100,
                              width: 160,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          timeago.format(action.createdAt),
                          style: GoogleFonts.sourceCodePro(
                            fontSize: 10,
                            color: AppColors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Color _actionColor(AuthorityActionType type) {
    switch (type) {
      case AuthorityActionType.resolved:
        return AppColors.statusResolved;
      case AuthorityActionType.rejected:
        return AppColors.statusRejected;
      case AuthorityActionType.inProgress:
        return AppColors.statusInProgress;
      case AuthorityActionType.escalated:
        return AppColors.tierState;
      case AuthorityActionType.acknowledged:
        return AppColors.tierMunicipal;
      case AuthorityActionType.comment:
        return AppColors.secondaryText;
    }
  }

  IconData _actionIcon(AuthorityActionType type) {
    switch (type) {
      case AuthorityActionType.resolved:
        return Icons.check;
      case AuthorityActionType.rejected:
        return Icons.close;
      case AuthorityActionType.inProgress:
        return Icons.loop;
      case AuthorityActionType.escalated:
        return Icons.arrow_upward;
      case AuthorityActionType.acknowledged:
        return Icons.visibility;
      case AuthorityActionType.comment:
        return Icons.comment;
    }
  }
}
