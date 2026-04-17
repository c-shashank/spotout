import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Base
  static const Color background = Color(0xFFFFFFFF);
  static const Color primaryText = Color(0xFF1A1A1A);
  static const Color secondaryText = Color(0xFF757575);
  static const Color accent = Color(0xFFCC3300);

  // Tags & Badges
  static const Color tagPillBg = Color(0xFFF5ECD7);
  static const Color tagPillText = Color(0xFF3E2A00);
  static const Color cardDivider = Color(0xFFE0E0E0);
  static const Color priorityBadgeBg = Color(0xFFCC0000);
  static const Color priorityBadgeText = Color(0xFFFFFFFF);

  // Escalation Tiers
  static const Color tierWard = Color(0xFF9E9E9E);
  static const Color tierMunicipal = Color(0xFF0077CC);
  static const Color tierState = Color(0xFFFF6F00);
  static const Color tierMediaNgo = Color(0xFFCC0000);

  // Issue Categories
  static const Color catRoads = Color(0xFFFF6B00);
  static const Color catWater = Color(0xFF0077CC);
  static const Color catGarbage = Color(0xFF2E7D32);
  static const Color catElectricity = Color(0xFFF9A825);
  static const Color catEncroachment = Color(0xFFC62828);
  static const Color catTraffic = Color(0xFF6A1B9A);

  // Status
  static const Color statusOpen = Color(0xFFCC0000);
  static const Color statusInProgress = Color(0xFFFF6F00);
  static const Color statusResolved = Color(0xFF2E7D32);
  static const Color statusRejected = Color(0xFF9E9E9E);

  // Authority response
  static const Color authorityResponseBg = Color(0xFFFFF8E1);
  static const Color authorityResponseBorder = Color(0xFFFF6F00);

  // Unread notification
  static const Color unreadBg = Color(0xFFFFF8E1);

  // Misc
  static const Color grey = Color(0xFF9E9E9E);
}
