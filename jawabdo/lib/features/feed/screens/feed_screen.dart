import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/issue_categories.dart';
import '../../../models/user.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/skeleton_card.dart';
import '../../issue_detail/screens/issue_detail_screen.dart';
import '../bloc/feed_bloc.dart';
import '../widgets/filter_chips_row.dart';
import '../widgets/issue_card.dart';
import 'package:google_fonts/google_fonts.dart';

class FeedScreen extends StatefulWidget {
  final Jawab DoUser user;

  const FeedScreen({super.key, required this.user});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final _scrollController = ScrollController();
  String _activeFilter = 'all';
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _loadFeed();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadFeed({String filter = 'all', bool refresh = false}) {
    if (filter == 'near_me') {
      _fetchLocationThenLoad(filter);
    } else {
      if (refresh) {
        context.read<FeedBloc>().add(FeedRefresh(
          filter: filter,
          wardId: widget.user.wardId,
        ));
      } else {
        context.read<FeedBloc>().add(FeedLoad(
          filter: filter,
          wardId: widget.user.wardId,
        ));
      }
    }
  }

  Future<void> _fetchLocationThenLoad(String filter) async {
    try {
      final pos = await Geolocator.getCurrentPosition();
      setState(() => _currentPosition = pos);
      if (mounted) {
        context.read<FeedBloc>().add(FeedLoad(
          filter: filter,
          userLat: pos.latitude,
          userLng: pos.longitude,
        ));
      }
    } catch (_) {
      context.read<FeedBloc>().add(const FeedLoad(filter: 'all'));
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<FeedBloc>().add(FeedLoadMore());
    }
  }

  void _onFilterChanged(String filter) {
    setState(() => _activeFilter = filter);
    _loadFeed(filter: filter);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: () async => _loadFeed(filter: _activeFilter, refresh: true),
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 8),
                FilterChipsRow(
                  selected: _activeFilter,
                  onSelect: _onFilterChanged,
                ),
                const SizedBox(height: 8),
                const Divider(height: 1, thickness: 1, color: AppColors.cardDivider),
              ],
            ),
          ),
          BlocBuilder<FeedBloc, FeedState>(
            builder: (context, state) {
              if (state is FeedLoading) {
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, __) => const SkeletonCard(),
                    childCount: 6,
                  ),
                );
              }
              if (state is FeedError) {
                return SliverFillRemaining(
                  child: EmptyState(
                    icon: Icons.error_outline,
                    title: 'Could not load feed',
                    subtitle: state.message,
                    actionLabel: 'Retry',
                    onAction: () => _loadFeed(filter: _activeFilter),
                  ),
                );
              }
              if (state is FeedLoaded) {
                if (state.issues.isEmpty) {
                  return const SliverFillRemaining(
                    child: EmptyState(
                      icon: Icons.inbox_outlined,
                      title: 'No issues found',
                      subtitle: 'Be the first to report an issue in your area!',
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == state.issues.length) {
                        return state is FeedLoadingMore
                            ? const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.accent,
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : !state.hasMore
                                ? Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Center(
                                      child: Text(
                                        '— end of feed —',
                                        style: GoogleFonts.sourceCodePro(
                                          fontSize: 11,
                                          color: AppColors.grey,
                                        ),
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink();
                      }
                      final issue = state.issues[index];
                      return IssueCard(
                        issue: issue,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => IssueDetailScreen(
                                issueId: issue.id,
                                userId: widget.user.id,
                              ),
                            ),
                          );
                        },
                        onUpvote: () => context
                            .read<FeedBloc>()
                            .add(FeedIssueVote(issue.id, 'up')),
                        onDownvote: () => context
                            .read<FeedBloc>()
                            .add(FeedIssueVote(issue.id, 'down')),
                        onBookmark: () => context
                            .read<FeedBloc>()
                            .add(FeedIssueBookmark(issue.id)),
                        onVisible: () => context
                            .read<FeedBloc>()
                            .add(FeedIssueViewed(issue.id)),
                      );
                    },
                    childCount: state.issues.length + 1,
                  ),
                );
              }
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            },
          ),
        ],
      ),
    );
  }
}

// ── End Drawer (Filter/Sort) ─────────────────────────────────────────────────

class FeedFilterDrawer extends StatelessWidget {
  const FeedFilterDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter Issues',
                style: GoogleFonts.sourceCodePro(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'By Category',
                style: GoogleFonts.sourceCodePro(
                  fontSize: 12,
                  color: AppColors.secondaryText,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: issueCategories
                    .map((cat) => ActionChip(
                          avatar: Icon(cat.icon, size: 14, color: cat.color),
                          label: Text(cat.label.split(' ').first),
                          labelStyle: GoogleFonts.sourceCodePro(fontSize: 11),
                          onPressed: () => Navigator.pop(context),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
              Text(
                'Sort',
                style: GoogleFonts.sourceCodePro(
                  fontSize: 12,
                  color: AppColors.secondaryText,
                ),
              ),
              ...['Newest First', 'Most Upvoted', 'Most Commented', 'Oldest First']
                  .map((s) => ListTile(
                        dense: true,
                        title: Text(s, style: GoogleFonts.sourceCodePro(fontSize: 13)),
                        onTap: () => Navigator.pop(context),
                      )),
            ],
          ),
        ),
      ),
    );
  }
}
