import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jawabdo/core/constants/app_colors.dart';
import 'package:jawabdo/core/constants/app_strings.dart';
import 'package:jawabdo/core/constants/ghmc_wards.dart';
import 'package:jawabdo/core/services/db_service.dart';
import 'package:jawabdo/core/utils/karma_calculator.dart';
import 'package:jawabdo/features/feed/widgets/issue_card.dart';
import 'package:jawabdo/features/issue_detail/screens/issue_detail_screen.dart';
import 'package:jawabdo/models/issue.dart';
import 'package:jawabdo/models/user.dart';
import 'package:jawabdo/widgets/empty_state.dart';
import 'package:jawabdo/widgets/skeleton_card.dart';

class ProfileScreen extends StatefulWidget {
  final Jawab DoUser user;
  final VoidCallback onLogout;

  const ProfileScreen({
    super.key,
    required this.user,
    required this.onLogout,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _db = DbService();

  List<Issue> _userIssues = [];
  bool _loadingIssues = true;

  // Approximate upvotes given — derived from karma when not stored directly
  int get _upvotesGiven => 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadIssues();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadIssues() async {
    setState(() => _loadingIssues = true);
    try {
      final issues = await _db.fetchUserIssues(widget.user.id);
      setState(() {
        _userIssues = issues;
        _loadingIssues = false;
      });
    } catch (_) {
      setState(() => _loadingIssues = false);
    }
  }

  String get _wardName {
    if (widget.user.wardId == null) return 'No ward set';
    final ward = ghmcWards.firstWhere(
      (w) => w.code == widget.user.wardId,
      orElse: () =>
          GhmcWard(code: widget.user.wardId!, name: widget.user.wardId!, circle: ''),
    );
    return ward.name;
  }

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _SettingsSheet(
        user: widget.user,
        onLogout: widget.onLogout,
      ),
    );
  }

  void _navigateToDetail(Issue issue) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IssueDetailScreen(
          issueId: issue.id,
          userId: widget.user.id,
          userAvatar: widget.user.avatarUrl,
        ),
      ),
    );
  }

  Future<void> _handleVote(Issue issue, String type) async {
    final idx = _userIssues.indexWhere((i) => i.id == issue.id);
    if (idx == -1) return;
    final current = _userIssues[idx];
    final wasUp = current.userHasUpvoted == true;
    final wasDown = current.userHasDownvoted == true;

    Issue updated;
    if (type == 'up') {
      updated = current.copyWith(
        upvoteCount: wasUp ? current.upvoteCount - 1 : current.upvoteCount + 1,
        userHasUpvoted: !wasUp,
        userHasDownvoted: false,
        downvoteCount: wasDown ? current.downvoteCount - 1 : current.downvoteCount,
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
    setState(() => _userIssues[idx] = updated);

    try {
      if (type == 'up') {
        if (wasUp) {
          await _db.removeVote(issueId: issue.id, userId: widget.user.id);
        } else {
          await _db.upsertVote(
              issueId: issue.id, userId: widget.user.id, voteType: 'up');
        }
      } else {
        if (wasDown) {
          await _db.removeVote(issueId: issue.id, userId: widget.user.id);
        } else {
          await _db.upsertVote(
              issueId: issue.id, userId: widget.user.id, voteType: 'down');
        }
      }
    } catch (_) {
      setState(() => _userIssues[idx] = current);
    }
  }

  Future<void> _handleBookmark(Issue issue) async {
    final idx = _userIssues.indexWhere((i) => i.id == issue.id);
    if (idx == -1) return;
    final current = _userIssues[idx];
    final was = current.userHasBookmarked ?? false;
    setState(() => _userIssues[idx] = current.copyWith(userHasBookmarked: !was));
    try {
      await _db.toggleBookmark(issue.id, widget.user.id);
    } catch (_) {
      setState(() => _userIssues[idx] = current);
    }
  }

  @override
  Widget build(BuildContext context) {
    final karma = widget.user.karmaScore;
    final tier = KarmaCalculator.tierLabel(karma);
    final progress = KarmaCalculator.tierProgress(karma);
    final nextThreshold = KarmaCalculator.nextTierThreshold(karma);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: Text(
          AppStrings.profile,
          style: GoogleFonts.sourceCodePro(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryText,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.primaryText),
            onPressed: _showSettingsSheet,
            tooltip: AppStrings.settings,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: _loadIssues,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Profile Header ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Avatar
                    GestureDetector(
                      onTap: () {
                        // TODO: implement avatar picker
                      },
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 44,
                            backgroundColor: AppColors.tagPillBg,
                            backgroundImage: widget.user.avatarUrl != null
                                ? CachedNetworkImageProvider(widget.user.avatarUrl!)
                                : null,
                            child: widget.user.avatarUrl == null
                                ? Text(
                                    widget.user.name.isNotEmpty
                                        ? widget.user.name[0].toUpperCase()
                                        : '?',
                                    style: GoogleFonts.sourceCodePro(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.tagPillText,
                                    ),
                                  )
                                : null,
                          ),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppColors.background, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt,
                                size: 12, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Name
                    Text(
                      widget.user.name,
                      style: GoogleFonts.sourceCodePro(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Ward
                    Text(
                      _wardName,
                      style: GoogleFonts.sourceCodePro(
                        fontSize: 12,
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Karma Score
                    Text(
                      '$karma',
                      style: GoogleFonts.sourceCodePro(
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        color: AppColors.accent,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppStrings.karmaScore,
                      style: GoogleFonts.sourceCodePro(
                        fontSize: 11,
                        color: AppColors.secondaryText,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Tier label
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.tagPillBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        tier,
                        style: GoogleFonts.sourceCodePro(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.tagPillText,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Progress bar
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            backgroundColor: AppColors.cardDivider,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.accent),
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (karma < 500)
                          Text(
                            '${nextThreshold - karma} karma to next tier',
                            style: GoogleFonts.sourceCodePro(
                              fontSize: 10,
                              color: AppColors.secondaryText,
                            ),
                            textAlign: TextAlign.end,
                          ),
                        if (karma >= 500)
                          Text(
                            'Max tier reached',
                            style: GoogleFonts.sourceCodePro(
                              fontSize: 10,
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.end,
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Stats row
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.cardDivider),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          _StatCell(
                            value: '${widget.user.issuesFiledCount}',
                            label: AppStrings.issuesFiled,
                          ),
                          _VerticalDivider(),
                          _StatCell(
                            value: '${widget.user.issuesResolvedCount}',
                            label: AppStrings.issuesResolved,
                          ),
                          _VerticalDivider(),
                          _StatCell(
                            value: '$_upvotesGiven',
                            label: AppStrings.upvotesGiven,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // ── TabBar ──────────────────────────────────────────────────────
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyTabBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: AppColors.accent,
                  unselectedLabelColor: AppColors.secondaryText,
                  indicatorColor: AppColors.accent,
                  indicatorWeight: 2,
                  labelStyle: GoogleFonts.sourceCodePro(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: GoogleFonts.sourceCodePro(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: const [
                    Tab(text: AppStrings.myIssues),
                    Tab(text: AppStrings.allActivity),
                  ],
                ),
              ),
            ),

            // ── Tab Body ─────────────────────────────────────────────────────
            SliverFillRemaining(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // My Issues tab
                  _loadingIssues
                      ? ListView.builder(
                          itemCount: 4,
                          itemBuilder: (_, __) => const SkeletonCard(),
                        )
                      : _userIssues.isEmpty
                          ? const EmptyState(
                              icon: Icons.report_problem_outlined,
                              title: 'No issues filed yet.',
                              subtitle: 'Start reporting civic issues in your ward.',
                            )
                          : ListView.builder(
                              itemCount: _userIssues.length,
                              itemBuilder: (_, i) {
                                final issue = _userIssues[i];
                                return IssueCard(
                                  issue: issue,
                                  onTap: () => _navigateToDetail(issue),
                                  onUpvote: () => _handleVote(issue, 'up'),
                                  onDownvote: () => _handleVote(issue, 'down'),
                                  onBookmark: () => _handleBookmark(issue),
                                );
                              },
                            ),

                  // All Activity tab
                  _loadingIssues
                      ? ListView.builder(
                          itemCount: 4,
                          itemBuilder: (_, __) => const SkeletonCard(),
                        )
                      : _userIssues.isEmpty
                          ? const EmptyState(
                              icon: Icons.timeline,
                              title: 'No activity yet.',
                              subtitle: 'Your civic activity will appear here.',
                            )
                          : ListView.builder(
                              itemCount: _userIssues.length,
                              itemBuilder: (_, i) {
                                final issue = _userIssues[i];
                                return IssueCard(
                                  issue: issue,
                                  onTap: () => _navigateToDetail(issue),
                                  onUpvote: () => _handleVote(issue, 'up'),
                                  onDownvote: () => _handleVote(issue, 'down'),
                                  onBookmark: () => _handleBookmark(issue),
                                );
                              },
                            ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stat Cell ─────────────────────────────────────────────────────────────────

class _StatCell extends StatelessWidget {
  final String value;
  final String label;

  const _StatCell({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: GoogleFonts.sourceCodePro(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.sourceCodePro(
              fontSize: 10,
              color: AppColors.secondaryText,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      width: 1,
      color: AppColors.cardDivider,
    );
  }
}

// ── Sticky TabBar Delegate ────────────────────────────────────────────────────

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  const _StickyTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height + 1;

  @override
  double get maxExtent => tabBar.preferredSize.height + 1;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          tabBar,
          const Divider(height: 1, thickness: 1, color: AppColors.cardDivider),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) => false;
}

// ── Settings Bottom Sheet ─────────────────────────────────────────────────────

class _SettingsSheet extends StatelessWidget {
  final Jawab DoUser user;
  final VoidCallback onLogout;

  const _SettingsSheet({required this.user, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.cardDivider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Text(
                AppStrings.settings,
                style: GoogleFonts.sourceCodePro(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryText,
                ),
              ),
            ),
            const Divider(height: 1, color: AppColors.cardDivider),
            _SettingsTile(
              icon: Icons.edit_outlined,
              label: AppStrings.editProfile,
              onTap: () {
                Navigator.pop(context);
                // TODO: navigate to edit profile
              },
            ),
            _SettingsTile(
              icon: Icons.location_city_outlined,
              label: AppStrings.changeWard,
              onTap: () {
                Navigator.pop(context);
                // TODO: navigate to ward picker
              },
            ),
            _SettingsTile(
              icon: Icons.notifications_outlined,
              label: AppStrings.notificationPreferences,
              onTap: () {
                Navigator.pop(context);
                // TODO: navigate to notification prefs
              },
            ),
            _SettingsTile(
              icon: Icons.info_outline,
              label: AppStrings.aboutJawab Do,
              onTap: () {
                Navigator.pop(context);
                showAboutDialog(
                  context: context,
                  applicationName: AppStrings.appName,
                  applicationVersion: '1.0.0',
                  applicationLegalese: '© 2025 Jawab Do',
                );
              },
            ),
            const Divider(height: 1, color: AppColors.cardDivider),
            _SettingsTile(
              icon: Icons.logout,
              label: AppStrings.logout,
              labelColor: AppColors.accent,
              onTap: () {
                Navigator.pop(context);
                onLogout();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? labelColor;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.labelColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = labelColor ?? AppColors.primaryText;
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(
        label,
        style: GoogleFonts.sourceCodePro(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
      onTap: onTap,
      dense: true,
    );
  }
}
