import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';

class JawabDoAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int unreadCount;
  final VoidCallback? onMenuTap;
  final VoidCallback? onNotificationTap;

  const JawabDoAppBar({
    super.key,
    this.unreadCount = 0,
    this.onMenuTap,
    this.onNotificationTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: AppColors.primaryText),
        onPressed: onMenuTap ?? () => Scaffold.of(context).openEndDrawer(),
      ),
      title: Text(
        AppStrings.appName,
        style: GoogleFonts.sourceCodePro(
          fontWeight: FontWeight.w800,
          fontSize: 22,
          color: AppColors.primaryText,
          letterSpacing: 22 * 0.1,
        ),
      ),
      centerTitle: true,
      actions: [
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none, color: AppColors.primaryText),
              onPressed: onNotificationTap,
            ),
            if (unreadCount > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: GoogleFonts.sourceCodePro(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
