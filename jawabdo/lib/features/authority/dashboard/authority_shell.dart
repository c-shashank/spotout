import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jawabdo/core/constants/app_colors.dart';
import 'package:jawabdo/core/constants/app_strings.dart';
import 'package:jawabdo/core/constants/ghmc_wards.dart';
import 'package:jawabdo/models/user.dart';
import 'package:jawabdo/features/authority/issue_queue/screens/queue_screen.dart';
import 'package:jawabdo/features/authority/stats/screens/stats_dashboard.dart';

class AuthorityShell extends StatefulWidget {
  final Jawab DoUser user;

  const AuthorityShell({super.key, required this.user});

  @override
  State<AuthorityShell> createState() => _AuthorityShellState();
}

class _AuthorityShellState extends State<AuthorityShell> {
  int _selectedIndex = 0;

  static const _navItems = [
    _NavItem(icon: Icons.inbox_outlined, activeIcon: Icons.inbox, label: AppStrings.issueQueue),
    _NavItem(icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart, label: 'Stats Dashboard'),
    _NavItem(icon: Icons.check_circle_outline, activeIcon: Icons.check_circle, label: AppStrings.resolved),
    _NavItem(icon: Icons.settings_outlined, activeIcon: Icons.settings, label: AppStrings.settings),
  ];

  String get _wardName {
    if (widget.user.wardId == null) return 'All Wards';
    try {
      return ghmcWards.firstWhere((w) => w.code == widget.user.wardId).name;
    } catch (_) {
      return widget.user.wardId ?? 'Unknown Ward';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      drawer: _buildDrawer(context),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          QueueScreen(user: widget.user),
          StatsDashboard(user: widget.user),
          // Resolved Issues tab — reuses QueueScreen pre-filtered to resolved
          QueueScreen(user: widget.user, initialTab: 3),
          _SettingsPlaceholder(user: widget.user),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      centerTitle: false,
      iconTheme: const IconThemeData(color: AppColors.primaryText),
      title: Text(
        'JAWAB DO · AUTHORITY',
        style: GoogleFonts.sourceCodePro(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.accent,
          letterSpacing: 1.2,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                widget.user.name,
                style: GoogleFonts.sourceCodePro(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
              ),
              if (widget.user.department != null)
                Text(
                  widget.user.department!,
                  style: GoogleFonts.sourceCodePro(
                    fontSize: 10,
                    color: AppColors.secondaryText,
                  ),
                ),
            ],
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.cardDivider),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.background,
      child: Column(
        children: [
          // Profile summary header
          Container(
            width: double.infinity,
            color: AppColors.accent,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              bottom: 20,
              left: 20,
              right: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white24,
                  backgroundImage: widget.user.avatarUrl != null
                      ? NetworkImage(widget.user.avatarUrl!)
                      : null,
                  child: widget.user.avatarUrl == null
                      ? Text(
                          widget.user.name.isNotEmpty
                              ? widget.user.name[0].toUpperCase()
                              : '?',
                          style: GoogleFonts.sourceCodePro(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 10),
                Text(
                  widget.user.name,
                  style: GoogleFonts.sourceCodePro(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                if (widget.user.department != null)
                  Text(
                    widget.user.department!,
                    style: GoogleFonts.sourceCodePro(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'GHMC · $_wardName',
                    style: GoogleFonts.sourceCodePro(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Nav items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: List.generate(_navItems.length, (i) {
                final item = _navItems[i];
                final isSelected = _selectedIndex == i;
                return ListTile(
                  leading: Icon(
                    isSelected ? item.activeIcon : item.icon,
                    color: isSelected ? AppColors.accent : AppColors.secondaryText,
                    size: 22,
                  ),
                  title: Text(
                    item.label,
                    style: GoogleFonts.sourceCodePro(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppColors.accent : AppColors.primaryText,
                    ),
                  ),
                  selected: isSelected,
                  selectedTileColor: AppColors.accent.withOpacity(0.07),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  onTap: () {
                    setState(() => _selectedIndex = i);
                    Navigator.of(context).pop();
                  },
                );
              }),
            ),
          ),

          const Divider(height: 1, color: AppColors.cardDivider),

          // Logout
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.accent, size: 22),
            title: Text(
              AppStrings.logout,
              style: GoogleFonts.sourceCodePro(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.accent,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            onTap: () async {
              Navigator.of(context).pop();
              _showLogoutDialog(context);
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          AppStrings.logout,
          style: GoogleFonts.sourceCodePro(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryText,
          ),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: GoogleFonts.sourceCodePro(
            fontSize: 13,
            color: AppColors.secondaryText,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              AppStrings.cancel,
              style: GoogleFonts.sourceCodePro(color: AppColors.secondaryText),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // Caller handles actual sign-out; pop all routes
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: Text(
              AppStrings.logout,
              style: GoogleFonts.sourceCodePro(
                color: AppColors.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}

// ── Settings Placeholder ─────────────────────────────────────────────────────

class _SettingsPlaceholder extends StatelessWidget {
  final Jawab DoUser user;
  const _SettingsPlaceholder({required this.user});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.settings, size: 56, color: AppColors.cardDivider),
            const SizedBox(height: 16),
            Text(
              AppStrings.settings,
              style: GoogleFonts.sourceCodePro(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Settings coming soon.',
              style: GoogleFonts.sourceCodePro(
                fontSize: 12,
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
