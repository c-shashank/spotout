import 'package:flutter/material.dart';
import 'app_colors.dart';

enum IssueCategory {
  roads,
  water,
  garbage,
  electricity,
  encroachment,
  traffic,
}

class IssueCategoryInfo {
  final IssueCategory category;
  final String label;
  final IconData icon;
  final Color color;
  final String value;

  const IssueCategoryInfo({
    required this.category,
    required this.label,
    required this.icon,
    required this.color,
    required this.value,
  });
}

const List<IssueCategoryInfo> issueCategories = [
  IssueCategoryInfo(
    category: IssueCategory.roads,
    label: 'Roads & Potholes',
    icon: Icons.construction,
    color: AppColors.catRoads,
    value: 'roads',
  ),
  IssueCategoryInfo(
    category: IssueCategory.water,
    label: 'Water & Drainage',
    icon: Icons.water_drop,
    color: AppColors.catWater,
    value: 'water',
  ),
  IssueCategoryInfo(
    category: IssueCategory.garbage,
    label: 'Garbage & Sanitation',
    icon: Icons.delete_outline,
    color: AppColors.catGarbage,
    value: 'garbage',
  ),
  IssueCategoryInfo(
    category: IssueCategory.electricity,
    label: 'Electricity & Streetlights',
    icon: Icons.bolt,
    color: AppColors.catElectricity,
    value: 'electricity',
  ),
  IssueCategoryInfo(
    category: IssueCategory.encroachment,
    label: 'Encroachments & Illegal Construction',
    icon: Icons.gavel,
    color: AppColors.catEncroachment,
    value: 'encroachment',
  ),
  IssueCategoryInfo(
    category: IssueCategory.traffic,
    label: 'Traffic & Signals',
    icon: Icons.traffic,
    color: AppColors.catTraffic,
    value: 'traffic',
  ),
];

IssueCategoryInfo categoryFromValue(String value) {
  return issueCategories.firstWhere(
    (c) => c.value == value,
    orElse: () => issueCategories.first,
  );
}
