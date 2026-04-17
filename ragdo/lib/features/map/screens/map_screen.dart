import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:jawabdo/core/constants/app_colors.dart';
import 'package:jawabdo/core/constants/app_strings.dart';
import 'package:jawabdo/core/constants/ghmc_wards.dart';
import 'package:jawabdo/core/constants/issue_categories.dart';
import 'package:jawabdo/core/services/db_service.dart';
import 'package:jawabdo/features/feed/widgets/tag_pill.dart';
import 'package:jawabdo/features/issue_detail/screens/issue_detail_screen.dart';
import 'package:jawabdo/models/issue.dart';

// Hyderabad city centre as default camera target
const LatLng _kHyderabadCenter = LatLng(17.3850, 78.4867);
const double _kClusterRadiusDeg = 0.008; // ~900m proximity threshold

class MapScreen extends StatefulWidget {
  final String userId;

  const MapScreen({super.key, required this.userId});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _db = DbService();
  GoogleMapController? _mapController;

  List<Issue> _allIssues = [];
  List<Issue> _filteredIssues = [];
  Set<Marker> _markers = {};
  bool _loading = true;

  String? _selectedCategory; // null = all
  double _currentZoom = 12.0;

  @override
  void initState() {
    super.initState();
    _loadIssues();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadIssues() async {
    setState(() => _loading = true);
    try {
      final issues = await _db.fetchFeed(filter: 'all', pageSize: 200);
      setState(() {
        _allIssues = issues;
        _loading = false;
      });
      _applyFilter();
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    final filtered = _selectedCategory == null
        ? _allIssues
        : _allIssues
            .where((i) => i.category == _selectedCategory)
            .toList();
    setState(() {
      _filteredIssues = filtered;
      _markers = _buildMarkers(filtered, _currentZoom);
    });
  }

  // ── Clustering ─────────────────────────────────────────────────────────────

  Set<Marker> _buildMarkers(List<Issue> issues, double zoom) {
    if (zoom >= 14) {
      // Fully zoomed in — show individual pins
      return issues.map((issue) => _singleMarker(issue)).toSet();
    }

    // Group nearby issues into clusters
    final Set<Marker> markers = {};
    final used = List<bool>.filled(issues.length, false);

    for (int i = 0; i < issues.length; i++) {
      if (used[i]) continue;
      final a = issues[i];
      final cluster = <Issue>[a];
      used[i] = true;

      for (int j = i + 1; j < issues.length; j++) {
        if (used[j]) continue;
        final b = issues[j];
        if (_distance(a.locationLat, a.locationLng, b.locationLat,
                b.locationLng) <
            _clusterThreshold(zoom)) {
          cluster.add(b);
          used[j] = true;
        }
      }

      if (cluster.length == 1) {
        markers.add(_singleMarker(cluster.first));
      } else {
        // Cluster marker — centroid position
        final lat =
            cluster.map((e) => e.locationLat).reduce((a, b) => a + b) /
                cluster.length;
        final lng =
            cluster.map((e) => e.locationLng).reduce((a, b) => a + b) /
                cluster.length;
        markers.add(_clusterMarker(cluster, LatLng(lat, lng)));
      }
    }
    return markers;
  }

  double _clusterThreshold(double zoom) {
    // Tighter clustering as user zooms in
    if (zoom < 10) return _kClusterRadiusDeg * 4;
    if (zoom < 12) return _kClusterRadiusDeg * 2;
    if (zoom < 14) return _kClusterRadiusDeg;
    return 0;
  }

  double _distance(double lat1, double lng1, double lat2, double lng2) {
    return math.sqrt(
        math.pow(lat1 - lat2, 2) + math.pow(lng1 - lng2, 2));
  }

  Marker _singleMarker(Issue issue) {
    final cat = categoryFromValue(issue.category);
    return Marker(
      markerId: MarkerId(issue.id),
      position: LatLng(issue.locationLat, issue.locationLng),
      icon: BitmapDescriptor.defaultMarkerWithHue(
          _hueForCategory(issue.category)),
      infoWindow: InfoWindow.noText,
      onTap: () => _showIssueBottomSheet(issue),
    );
  }

  Marker _clusterMarker(List<Issue> cluster, LatLng position) {
    // Use the majority category colour for the cluster
    final categoryCount = <String, int>{};
    for (final i in cluster) {
      categoryCount[i.category] = (categoryCount[i.category] ?? 0) + 1;
    }
    final dominantCategory = categoryCount.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;

    return Marker(
      markerId: MarkerId('cluster_${position.latitude}_${position.longitude}'),
      position: position,
      icon: BitmapDescriptor.defaultMarkerWithHue(
          _hueForCategory(dominantCategory)),
      infoWindow: InfoWindow(title: '${cluster.length} issues'),
      onTap: () {
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(position, _currentZoom + 2),
        );
      },
    );
  }

  double _hueForCategory(String category) {
    switch (category) {
      case 'roads':
        return BitmapDescriptor.hueOrange;
      case 'water':
        return BitmapDescriptor.hueAzure;
      case 'garbage':
        return BitmapDescriptor.hueGreen;
      case 'electricity':
        return BitmapDescriptor.hueYellow;
      case 'encroachment':
        return BitmapDescriptor.hueRed;
      case 'traffic':
        return BitmapDescriptor.hueViolet;
      default:
        return BitmapDescriptor.hueRed;
    }
  }

  // ── Location FAB ───────────────────────────────────────────────────────────

  Future<void> _goToCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.locationPermissionDenied,
              style: GoogleFonts.sourceCodePro(fontSize: 12),
            ),
            action: SnackBarAction(
              label: AppStrings.locationPermissionSettings,
              onPressed: () => Geolocator.openAppSettings(),
            ),
          ),
        );
      }
      return;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(pos.latitude, pos.longitude),
          15,
        ),
      );
    } catch (_) {}
  }

  // ── Issue Bottom Sheet ─────────────────────────────────────────────────────

  void _showIssueBottomSheet(Issue issue) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _IssuePreviewSheet(
        issue: issue,
        onViewDetail: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => IssueDetailScreen(
                issueId: issue.id,
                userId: widget.userId,
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Camera Move Listener ───────────────────────────────────────────────────

  void _onCameraMove(CameraPosition position) {
    // Rebuild markers at new zoom level if threshold crossed
    final newZoom = position.zoom;
    final prevBucket = _currentZoom >= 14 ? 2 : (_currentZoom >= 12 ? 1 : 0);
    final newBucket = newZoom >= 14 ? 2 : (newZoom >= 12 ? 1 : 0);
    _currentZoom = newZoom;
    if (prevBucket != newBucket) {
      setState(() {
        _markers = _buildMarkers(_filteredIssues, _currentZoom);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Full-screen Map ──────────────────────────────────────────────
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: _kHyderabadCenter,
              zoom: 12,
            ),
            markers: _markers,
            myLocationButtonEnabled: false,
            myLocationEnabled: true,
            zoomControlsEnabled: false,
            onMapCreated: (controller) {
              _mapController = controller;
            },
            onCameraMove: _onCameraMove,
          ),

          // ── Category filter chips overlay ────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 0,
            right: 0,
            child: _CategoryFilterRow(
              selectedCategory: _selectedCategory,
              onCategorySelected: (cat) {
                setState(() {
                  _selectedCategory = cat;
                });
                _applyFilter();
              },
            ),
          ),

          // ── Loading indicator ────────────────────────────────────────────
          if (_loading)
            const Positioned(
              top: 80,
              left: 0,
              right: 0,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              ),
            ),

          // ── Current Location FAB ─────────────────────────────────────────
          Positioned(
            bottom: 24,
            right: 16,
            child: FloatingActionButton(
              backgroundColor: AppColors.background,
              onPressed: _goToCurrentLocation,
              elevation: 4,
              child: const Icon(Icons.my_location, color: AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Category Filter Row ───────────────────────────────────────────────────────

class _CategoryFilterRow extends StatelessWidget {
  final String? selectedCategory;
  final ValueChanged<String?> onCategorySelected;

  const _CategoryFilterRow({
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          // "All" chip
          _FilterChip(
            label: 'All',
            color: AppColors.primaryText,
            selected: selectedCategory == null,
            onTap: () => onCategorySelected(null),
          ),
          const SizedBox(width: 8),
          // Category chips
          ...issueCategories.map((cat) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _FilterChip(
                label: _shortLabel(cat.label),
                color: cat.color,
                selected: selectedCategory == cat.value,
                onTap: () => onCategorySelected(
                  selectedCategory == cat.value ? null : cat.value,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _shortLabel(String label) {
    // Keep it concise for the overlay chips
    if (label.contains('&')) {
      return label.split('&').first.trim();
    }
    if (label.length > 12) return '${label.substring(0, 11)}…';
    return label;
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : AppColors.cardDivider,
            width: selected ? 0 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!selected)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 5),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            Text(
              label,
              style: GoogleFonts.sourceCodePro(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.primaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Issue Preview Bottom Sheet ────────────────────────────────────────────────

class _IssuePreviewSheet extends StatelessWidget {
  final Issue issue;
  final VoidCallback onViewDetail;

  const _IssuePreviewSheet({
    required this.issue,
    required this.onViewDetail,
  });

  @override
  Widget build(BuildContext context) {
    final cat = categoryFromValue(issue.category);
    final ward = ghmcWards.firstWhere(
      (w) => w.code == issue.wardId,
      orElse: () =>
          GhmcWard(code: issue.wardId, name: issue.wardId, circle: ''),
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.cardDivider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Category pill + ward pill
            Row(
              children: [
                TagPill(
                  label: cat.label.length > 20
                      ? '${cat.label.substring(0, 18)}…'
                      : cat.label,
                  dotColor: cat.color,
                ),
                const SizedBox(width: 6),
                TagPill(label: ward.name),
              ],
            ),
            const SizedBox(height: 10),

            // Title
            Text(
              issue.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.sourceCodePro(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 6),

            // Upvotes + status row
            Row(
              children: [
                const Icon(Icons.sports_mma,
                    size: 14, color: AppColors.secondaryText),
                const SizedBox(width: 4),
                Text(
                  '${issue.upvoteCount}',
                  style: GoogleFonts.sourceCodePro(
                    fontSize: 12,
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(width: 12),
                _StatusBadge(status: issue.status),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 14),

            // View detail button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onViewDetail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'View Issue →',
                  style: GoogleFonts.sourceCodePro(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final IssueStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case IssueStatus.open:
        color = AppColors.statusOpen;
        label = AppStrings.statusOpen;
        break;
      case IssueStatus.inProgress:
        color = AppColors.statusInProgress;
        label = AppStrings.statusInProgress;
        break;
      case IssueStatus.resolved:
        color = AppColors.statusResolved;
        label = AppStrings.statusResolved;
        break;
      case IssueStatus.rejected:
        color = AppColors.statusRejected;
        label = AppStrings.statusRejected;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: GoogleFonts.sourceCodePro(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
