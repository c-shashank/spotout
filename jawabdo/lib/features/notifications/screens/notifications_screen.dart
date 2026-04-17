import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:jawabdo/core/constants/app_colors.dart';
import 'package:jawabdo/core/constants/app_strings.dart';
import 'package:jawabdo/core/services/db_service.dart';
import 'package:jawabdo/features/issue_detail/screens/issue_detail_screen.dart';
import 'package:jawabdo/widgets/empty_state.dart';

class NotificationsScreen extends StatefulWidget {
  final String userId;

  const NotificationsScreen({super.key, required this.userId});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _db = DbService();
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _db.fetchNotifications(widget.userId);
      setState(() {
        _notifications = data;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _markAllRead() async {
    try {
      await _db.markAllNotificationsRead(widget.userId);
      setState(() {
        _notifications = _notifications
            .map((n) => {...n, 'is_read': true})
            .toList();
      });
    } catch (_) {}
  }

  void _onTapNotification(Map<String, dynamic> notification) {
    // Mark this notification as read locally
    final idx = _notifications.indexWhere((n) => n['id'] == notification['id']);
    if (idx != -1) {
      setState(() =>
          _notifications[idx] = {..._notifications[idx], 'is_read': true});
    }

    final issueId = notification['issue_id'] as String?;
    if (issueId != null && issueId.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => IssueDetailScreen(
            issueId: issueId,
            userId: widget.userId,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount =
        _notifications.where((n) => n['is_read'] != true).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppStrings.notifications,
              style: GoogleFonts.sourceCodePro(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryText,
              ),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$unreadCount',
                  style: GoogleFonts.sourceCodePro(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: Text(
                AppStrings.markAllRead,
                style: GoogleFonts.sourceCodePro(
                  fontSize: 12,
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent))
          : RefreshIndicator(
              color: AppColors.accent,
              onRefresh: _load,
              child: _notifications.isEmpty
                  ? LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: constraints.maxHeight,
                            child: const EmptyState(
                              icon: Icons.notifications_none,
                              title: 'No notifications yet.',
                              subtitle:
                                  'You\'ll be notified about activity on your issues.',
                            ),
                          ),
                        );
                      },
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _notifications.length,
                      separatorBuilder: (_, __) => const Divider(
                        height: 1,
                        thickness: 1,
                        color: AppColors.cardDivider,
                      ),
                      itemBuilder: (_, i) {
                        final n = _notifications[i];
                        final isRead = n['is_read'] == true;
                        return _NotificationTile(
                          notification: n,
                          isRead: isRead,
                          onTap: () => _onTapNotification(n),
                        );
                      },
                    ),
            ),
    );
  }
}

// ── Notification Tile ─────────────────────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  final Map<String, dynamic> notification;
  final bool isRead;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.isRead,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final type = notification['type'] as String? ?? 'general';
    final message = notification['message'] as String? ?? '';
    final createdAt = notification['created_at'] as String?;
    final avatarUrl = notification['actor_avatar'] as String?;

    DateTime? parsedAt;
    try {
      if (createdAt != null) parsedAt = DateTime.parse(createdAt);
    } catch (_) {}

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: isRead ? AppColors.background : AppColors.unreadBg,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar / icon
            _NotificationAvatar(type: type, avatarUrl: avatarUrl),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: GoogleFonts.sourceCodePro(
                      fontSize: 13,
                      color: AppColors.primaryText,
                      fontWeight:
                          isRead ? FontWeight.w400 : FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (parsedAt != null)
                    Text(
                      timeago.format(parsedAt.toLocal()),
                      style: GoogleFonts.sourceCodePro(
                        fontSize: 11,
                        color: AppColors.secondaryText,
                      ),
                    ),
                ],
              ),
            ),

            // Unread dot
            if (!isRead)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 8),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Notification Avatar/Icon ──────────────────────────────────────────────────

class _NotificationAvatar extends StatelessWidget {
  final String type;
  final String? avatarUrl;

  const _NotificationAvatar({required this.type, this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 20,
        backgroundColor: AppColors.tagPillBg,
        backgroundImage: NetworkImage(avatarUrl!),
      );
    }

    final iconData = _iconForType(type);
    final bgColor = _bgColorForType(type);
    final iconColor = _iconColorForType(type);

    return CircleAvatar(
      radius: 20,
      backgroundColor: bgColor,
      child: Icon(iconData, size: 18, color: iconColor),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'upvote':
        return Icons.sports_mma;
      case 'comment':
        return Icons.comment_outlined;
      case 'escalation':
        return Icons.trending_up;
      case 'authority_response':
        return Icons.account_balance_outlined;
      case 'new_issue_in_ward':
        return Icons.location_on_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _bgColorForType(String type) {
    switch (type) {
      case 'upvote':
        return AppColors.accent.withOpacity(0.12);
      case 'comment':
        return AppColors.catWater.withOpacity(0.12);
      case 'escalation':
        return AppColors.catElectricity.withOpacity(0.18);
      case 'authority_response':
        return AppColors.catGarbage.withOpacity(0.12);
      case 'new_issue_in_ward':
        return AppColors.catRoads.withOpacity(0.12);
      default:
        return AppColors.tagPillBg;
    }
  }

  Color _iconColorForType(String type) {
    switch (type) {
      case 'upvote':
        return AppColors.accent;
      case 'comment':
        return AppColors.catWater;
      case 'escalation':
        return AppColors.catElectricity;
      case 'authority_response':
        return AppColors.catGarbage;
      case 'new_issue_in_ward':
        return AppColors.catRoads;
      default:
        return AppColors.secondaryText;
    }
  }
}
