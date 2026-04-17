import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jawabdo/core/constants/app_colors.dart';
import 'package:jawabdo/core/constants/app_strings.dart';
import 'package:jawabdo/core/constants/ghmc_wards.dart';
import 'package:jawabdo/core/services/db_service.dart';
import 'package:jawabdo/models/issue.dart';
import 'package:jawabdo/models/user.dart';
import 'package:jawabdo/widgets/empty_state.dart';
import 'package:jawabdo/widgets/skeleton_card.dart';
import 'package:jawabdo/features/authority/issue_queue/widgets/queue_card.dart';

class QueueScreen extends StatefulWidget {
  final Jawab DoUser user;
  /// Pass 3 to default to the "Resolved" tab (index 3).
  final int initialTab;

  const QueueScreen({
    super.key,
    required this.user,
    this.initialTab = 0,
  });

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen>
    with SingleTickerProviderStateMixin {
  static const _tabs = [
    'my_queue',
    'all_ward',
    'escalated_to_me',
    'resolved',
  ];

  late TabController _tabController;
  final _db = DbService();

  // Per-tab data
  final Map<int, List<Issue>> _issues = {};
  final Map<int, bool> _loading = {};
  final Map<int, bool> _hasLoaded = {};

  String get _wardId => widget.user.wardId ?? '';

  String get _wardName {
    if (widget.user.wardId == null) return 'All Wards';
    try {
      return ghmcWards.firstWhere((w) => w.code == widget.user.wardId).name;
    } catch (_) {
      return widget.user.wardId ?? 'Unknown';
    }
  }

  int get _openCount {
    final myQueueIssues = _issues[0] ?? [];
    return myQueueIssues
        .where((i) => !i.isResolved && i.status != IssueStatus.rejected)
        .length;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _loadTab(_tabController.index);
      }
    });
    _loadTab(widget.initialTab);
    // Pre-load my_queue for the open count badge even if starting on resolved
    if (widget.initialTab != 0) {
      _loadTab(0);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTab(int tabIndex, {bool forceRefresh = false}) async {
    if ((_hasLoaded[tabIndex] == true) && !forceRefresh) return;
    if (_loading[tabIndex] == true) return;

    setState(() => _loading[tabIndex] = true);

    try {
      final issues = await _db.fetchAuthorityQueue(
        authorityId: widget.user.id,
        wardId: _wardId,
        tab: _tabs[tabIndex],
      );
      setState(() {
        _issues[tabIndex] = issues;
        _loading[tabIndex] = false;
        _hasLoaded[tabIndex] = true;
      });
    } catch (_) {
      setState(() => _loading[tabIndex] = false);
    }
  }

  Future<void> _refresh() async {
    await _loadTab(_tabController.index, forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        _buildTabBar(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: List.generate(_tabs.length, (i) => _buildTab(i)),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final department = widget.user.department ?? 'GHMC Ward Engineer';
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.cardDivider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$department · $_wardName',
              style: GoogleFonts.sourceCodePro(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          _OpenCountBadge(count: _openCount),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final myQueueCount = _issues[0]?.length ?? 0;
    final tabLabels = [
      'My Queue${myQueueCount > 0 ? ' ($myQueueCount)' : ''}',
      AppStrings.allWardIssues,
      AppStrings.escalatedToMe,
      AppStrings.resolved,
    ];

    return Container(
      color: AppColors.background,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorColor: AppColors.accent,
        indicatorWeight: 2,
        labelColor: AppColors.accent,
        unselectedLabelColor: AppColors.secondaryText,
        labelStyle: GoogleFonts.sourceCodePro(
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.sourceCodePro(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        tabs: tabLabels.map((label) => Tab(text: label)).toList(),
      ),
    );
  }

  Widget _buildTab(int tabIndex) {
    final isLoading = _loading[tabIndex] ?? false;
    final issues = _issues[tabIndex] ?? [];
    final hasLoaded = _hasLoaded[tabIndex] ?? false;

    if (isLoading && !hasLoaded) {
      return ListView.builder(
        itemCount: 5,
        itemBuilder: (_, __) => const SkeletonCard(),
      );
    }

    if (hasLoaded && issues.isEmpty) {
      return EmptyState(
        icon: Icons.inbox_outlined,
        title: 'No issues here',
        subtitle: tabIndex == 3
            ? 'Resolved issues will appear here.'
            : 'Your queue is clear.',
        actionLabel: 'Refresh',
        onAction: _refresh,
      );
    }

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: _refresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: issues.length,
        itemBuilder: (context, index) {
          final issue = issues[index];
          return QueueCard(
            issue: issue,
            onActionSubmitted: () => _loadTab(tabIndex, forceRefresh: true),
            authorityId: widget.user.id,
          );
        },
      ),
    );
  }
}

// ── Open Count Badge ─────────────────────────────────────────────────────────

class _OpenCountBadge extends StatelessWidget {
  final int count;
  const _OpenCountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: count > 0
            ? AppColors.statusOpen.withOpacity(0.1)
            : AppColors.statusResolved.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: count > 0 ? AppColors.statusOpen : AppColors.statusResolved,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count Open',
            style: GoogleFonts.sourceCodePro(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: count > 0 ? AppColors.statusOpen : AppColors.statusResolved,
            ),
          ),
          const SizedBox(width: 5),
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: count > 0 ? AppColors.statusOpen : AppColors.statusResolved,
            ),
          ),
        ],
      ),
    );
  }
}
