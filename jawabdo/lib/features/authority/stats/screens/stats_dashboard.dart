import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jawabdo/core/constants/app_colors.dart';
import 'package:jawabdo/core/constants/app_strings.dart';
import 'package:jawabdo/core/constants/ghmc_wards.dart';
import 'package:jawabdo/core/constants/issue_categories.dart';
import 'package:jawabdo/core/services/db_service.dart';
import 'package:jawabdo/models/user.dart';
import 'package:jawabdo/widgets/skeleton_card.dart';

class StatsDashboard extends StatefulWidget {
  final Jawab DoUser user;

  const StatsDashboard({super.key, required this.user});

  @override
  State<StatsDashboard> createState() => _StatsDashboardState();
}

class _StatsDashboardState extends State<StatsDashboard> {
  final _db = DbService();
  Map<String, dynamic>? _stats;
  bool _loading = true;
  String? _error;

  String get _wardName {
    if (widget.user.wardId == null) return 'All Wards';
    try {
      return ghmcWards.firstWhere((w) => w.code == widget.user.wardId).name;
    } catch (_) {
      return widget.user.wardId ?? 'Unknown';
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final stats = await _db.fetchAuthorityStats(widget.user.wardId ?? '');
      setState(() {
        _stats = stats;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = AppStrings.networkError;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          SkeletonCard(),
          SizedBox(height: 12),
          SkeletonCard(),
          SizedBox(height: 12),
          SkeletonCard(),
        ],
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 48, color: AppColors.grey),
            const SizedBox(height: 12),
            Text(
              _error!,
              style: GoogleFonts.sourceCodePro(
                fontSize: 13,
                color: AppColors.secondaryText,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final stats = _stats ?? {};
    final open = (stats['open_count'] as num?)?.toInt() ?? 0;
    final inProgress = (stats['in_progress_count'] as num?)?.toInt() ?? 0;
    final resolved = (stats['resolved_count'] as num?)?.toInt() ?? 0;
    final rejected = (stats['rejected_count'] as num?)?.toInt() ?? 0;
    final avgDays = (stats['avg_resolution_days'] as num?)?.toDouble() ?? 0.0;
    final escalationRate = (stats['escalation_rate'] as num?)?.toDouble() ?? 0.0;
    final Map<String, dynamic> catBreakdown =
        (stats['category_breakdown'] as Map<String, dynamic>?) ?? {};
    final Map<String, dynamic>? oldestIssue =
        stats['oldest_unresolved'] as Map<String, dynamic>?;

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Your Dashboard · $_wardName',
              style: GoogleFonts.sourceCodePro(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'GHMC Ward Stats',
              style: GoogleFonts.sourceCodePro(
                fontSize: 11,
                color: AppColors.secondaryText,
              ),
            ),
            const SizedBox(height: 20),

            // KPI Cards
            Row(
              children: [
                _KpiCard(label: 'Open', count: open, color: AppColors.statusOpen),
                const SizedBox(width: 10),
                _KpiCard(
                    label: 'In Progress',
                    count: inProgress,
                    color: AppColors.statusInProgress),
                const SizedBox(width: 10),
                _KpiCard(
                    label: 'Resolved',
                    count: resolved,
                    color: AppColors.statusResolved),
                const SizedBox(width: 10),
                _KpiCard(
                    label: 'Rejected',
                    count: rejected,
                    color: AppColors.statusRejected),
              ],
            ),
            const SizedBox(height: 20),

            // Avg Resolution Time
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Avg Resolution Time',
                    style: GoogleFonts.sourceCodePro(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        avgDays.toStringAsFixed(1),
                        style: GoogleFonts.sourceCodePro(
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: _avgResolutionColor(avgDays),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        AppStrings.avgResolutionTime,
                        style: GoogleFonts.sourceCodePro(
                          fontSize: 13,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _ResolutionTargetBar(avgDays: avgDays),
                  const SizedBox(height: 6),
                  Text(
                    AppStrings.ghmcTarget,
                    style: GoogleFonts.sourceCodePro(
                      fontSize: 10,
                      color: AppColors.secondaryText,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Category Bar Chart
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Issues by Category',
                    style: GoogleFonts.sourceCodePro(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _CategoryBarChart(breakdown: catBreakdown),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Escalation Rate Circular Progress
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Escalation Rate',
                    style: GoogleFonts.sourceCodePro(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            PieChart(
                              PieChartData(
                                startDegreeOffset: -90,
                                sections: [
                                  PieChartSectionData(
                                    value: escalationRate.clamp(0, 100),
                                    color: escalationRate > 30
                                        ? AppColors.tierMediaNgo
                                        : escalationRate > 15
                                            ? AppColors.tierState
                                            : AppColors.tierMunicipal,
                                    radius: 16,
                                    showTitle: false,
                                  ),
                                  PieChartSectionData(
                                    value:
                                        (100 - escalationRate).clamp(0, 100),
                                    color: AppColors.cardDivider,
                                    radius: 16,
                                    showTitle: false,
                                  ),
                                ],
                                sectionsSpace: 0,
                                centerSpaceRadius: 34,
                              ),
                            ),
                            Text(
                              '${escalationRate.toStringAsFixed(0)}%',
                              style: GoogleFonts.sourceCodePro(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          AppStrings.escalationRate,
                          style: GoogleFonts.sourceCodePro(
                            fontSize: 12,
                            color: AppColors.secondaryText,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Oldest Unresolved Issue
            if (oldestIssue != null) _OldestIssueCard(data: oldestIssue),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Color _avgResolutionColor(double days) {
    if (days <= 7) return AppColors.statusResolved;
    if (days <= 14) return AppColors.statusInProgress;
    return AppColors.statusOpen;
  }
}

// ── KPI Card ─────────────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _KpiCard({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.25), width: 1),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: GoogleFonts.sourceCodePro(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.sourceCodePro(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: color,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section Card ─────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.cardDivider),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }
}

// ── Resolution Target Bar ─────────────────────────────────────────────────────

class _ResolutionTargetBar extends StatelessWidget {
  final double avgDays;
  const _ResolutionTargetBar({required this.avgDays});

  @override
  Widget build(BuildContext context) {
    final fraction = (avgDays / 21).clamp(0.0, 1.0);
    final color = avgDays <= 7
        ? AppColors.statusResolved
        : avgDays <= 14
            ? AppColors.statusInProgress
            : AppColors.statusOpen;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 8,
            backgroundColor: AppColors.cardDivider,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '0 days',
              style: GoogleFonts.sourceCodePro(
                  fontSize: 9, color: AppColors.grey),
            ),
            Text(
              '7 (target)',
              style: GoogleFonts.sourceCodePro(
                  fontSize: 9, color: AppColors.grey),
            ),
            Text(
              '21 days',
              style: GoogleFonts.sourceCodePro(
                  fontSize: 9, color: AppColors.grey),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Category Bar Chart ────────────────────────────────────────────────────────

class _CategoryBarChart extends StatelessWidget {
  final Map<String, dynamic> breakdown;
  const _CategoryBarChart({required this.breakdown});

  @override
  Widget build(BuildContext context) {
    // Build bars from issueCategories order
    final barGroups = <BarChartGroupData>[];
    double maxY = 10;

    for (int i = 0; i < issueCategories.length; i++) {
      final cat = issueCategories[i];
      final count =
          (breakdown[cat.value] as num?)?.toDouble() ?? 0;
      if (count > maxY) maxY = count;
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: count,
              color: cat.color,
              width: 16,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4)),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY * 1.25,
          barGroups: barGroups,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => const FlLine(
              color: AppColors.cardDivider,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const SizedBox.shrink();
                  return Text(
                    value.toInt().toString(),
                    style: GoogleFonts.sourceCodePro(
                      fontSize: 9,
                      color: AppColors.secondaryText,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= issueCategories.length) {
                    return const SizedBox.shrink();
                  }
                  final cat = issueCategories[idx];
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Icon(cat.icon, size: 14, color: cat.color),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: AppColors.primaryText,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final cat = issueCategories[group.x];
                return BarTooltipItem(
                  '${cat.label}\n${rod.toY.toInt()}',
                  GoogleFonts.sourceCodePro(
                    fontSize: 10,
                    color: Colors.white,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ── Oldest Unresolved Issue Card ─────────────────────────────────────────────

class _OldestIssueCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _OldestIssueCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final title = data['title'] as String? ?? 'Unknown issue';
    final createdAt = data['created_at'] != null
        ? DateTime.tryParse(data['created_at'] as String)
        : null;
    final daysOld = createdAt != null
        ? DateTime.now().difference(createdAt).inDays
        : null;
    final isOverdue = daysOld != null && daysOld > 7;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOverdue
            ? AppColors.statusOpen.withOpacity(0.05)
            : AppColors.background,
        border: Border.all(
          color: isOverdue ? AppColors.statusOpen : AppColors.cardDivider,
          width: isOverdue ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isOverdue)
                const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child:
                      Icon(Icons.warning_amber_rounded,
                          size: 16, color: AppColors.statusOpen),
                ),
              Text(
                AppStrings.oldestUnresolved,
                style: GoogleFonts.sourceCodePro(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isOverdue ? AppColors.statusOpen : AppColors.secondaryText,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.sourceCodePro(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (daysOld != null) ...[
            const SizedBox(height: 6),
            Text(
              '$daysOld days old${isOverdue ? ' — OVERDUE' : ''}',
              style: GoogleFonts.sourceCodePro(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isOverdue ? AppColors.statusOpen : AppColors.secondaryText,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
