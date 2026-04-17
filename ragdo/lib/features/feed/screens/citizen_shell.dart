import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/db_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../models/user.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../post_issue/bloc/post_issue_bloc.dart';
import '../../post_issue/screens/step1_photo.dart';
import '../../profile/screens/profile_screen.dart';
import '../../saved/screens/saved_screen.dart';
import '../bloc/feed_bloc.dart';
import 'feed_screen.dart';
import '../../../widgets/jawabdo_app_bar.dart';

class CitizenShell extends StatefulWidget {
  final Jawab DoUser user;

  const CitizenShell({super.key, required this.user});

  @override
  State<CitizenShell> createState() => _CitizenShellState();
}

class _CitizenShellState extends State<CitizenShell> {
  int _currentIndex = 0;
  final int _unreadCount = 0;

  final List<String> _labels = ['Home', 'Messages', '', 'Saved', 'Profile'];

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      BlocProvider(
        create: (_) => FeedBloc(DbService(), userId: widget.user.id)
          ..add(FeedLoad(wardId: widget.user.wardId)),
        child: FeedScreen(user: widget.user),
      ),
      NotificationsScreen(userId: widget.user.id),
      const SizedBox.shrink(), // FAB placeholder
      SavedScreen(userId: widget.user.id),
      ProfileScreen(
        user: widget.user,
        onLogout: () => context.read<AuthBloc>().add(AuthSignOut()),
      ),
    ];
  }

  void _openPostIssue() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => PostIssueBloc(DbService(), StorageService(), userId: widget.user.id),
          child: const Step1PhotoScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _currentIndex == 0
          ? JawabDoAppBar(
              unreadCount: _unreadCount,
              onMenuTap: () => Scaffold.of(context).openEndDrawer(),
              onNotificationTap: () => setState(() => _currentIndex = 1),
            )
          : AppBar(
              title: Text(
                _currentIndex == 1
                    ? AppStrings.notifications
                    : _currentIndex == 3
                        ? AppStrings.saved
                        : AppStrings.profile,
                style: GoogleFonts.sourceCodePro(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  letterSpacing: 2,
                ),
              ),
              centerTitle: true,
              backgroundColor: AppColors.background,
              elevation: 0,
            ),
      endDrawer: _currentIndex == 0 ? const _FeedFilterDrawerWidget() : null,
      body: IndexedStack(
        index: _currentIndex == 2 ? 0 : _currentIndex,
        children: [
          _screens[0],
          _screens[1],
          _screens[3],
          _screens[4],
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex > 2 ? _currentIndex - 1 : _currentIndex,
        onTap: (i) {
          if (i == 2) return; // FAB
          setState(() => _currentIndex = i > 1 ? i + 1 : i);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_none),
            activeIcon: Icon(Icons.notifications),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: SizedBox.shrink(),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_border),
            activeIcon: Icon(Icons.bookmark),
            label: 'Saved',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openPostIssue,
        backgroundColor: AppColors.accent,
        shape: const CircleBorder(),
        child: const Icon(Icons.edit, color: Colors.white, size: 24),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

class _FeedFilterDrawerWidget extends StatelessWidget {
  const _FeedFilterDrawerWidget();

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
                'Filter & Sort',
                style: GoogleFonts.sourceCodePro(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Sort by',
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
