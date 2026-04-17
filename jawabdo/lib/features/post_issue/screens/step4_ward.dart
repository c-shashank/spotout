import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/ghmc_wards.dart';
import '../bloc/post_issue_bloc.dart';
import 'step5_preview.dart';

class Step4WardScreen extends StatefulWidget {
  const Step4WardScreen({super.key});

  @override
  State<Step4WardScreen> createState() => _Step4WardScreenState();
}

class _Step4WardScreenState extends State<Step4WardScreen> {
  GhmcWard? _selectedWard;
  final _searchController = TextEditingController();
  List<GhmcWard> _filtered = ghmcWards;

  @override
  void initState() {
    super.initState();
    // Try to pre-select the ward from location data
    final bloc = context.read<PostIssueBloc>();
    if (bloc.state is PostIssueEditing) {
      final data = (bloc.state as PostIssueEditing).data;
      if (data.wardId != null) {
        try {
          _selectedWard = ghmcWards.firstWhere((w) => w.code == data.wardId);
          _searchController.text = _selectedWard!.name;
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filter(String q) {
    setState(() {
      _filtered = ghmcWards
          .where((w) => w.name.toLowerCase().contains(q.toLowerCase()))
          .toList();
    });
  }

  void _next() {
    if (_selectedWard == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your ward')),
      );
      return;
    }
    context.read<PostIssueBloc>().add(PostIssueUpdateWard(_selectedWard!.code));
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<PostIssueBloc>(),
          child: const Step5PreviewScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<PostIssueBloc>();
    double? lat, lng;
    if (bloc.state is PostIssueEditing) {
      final data = (bloc.state as PostIssueEditing).data;
      lat = data.lat;
      lng = data.lng;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${AppStrings.postIssue} — Step 4 of 5',
          style: GoogleFonts.sourceCodePro(fontSize: 14),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _StepBar(current: 4),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                AppStrings.step4Title,
                style: GoogleFonts.sourceCodePro(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // Mini map thumbnail
            if (lat != null && lng != null)
              SizedBox(
                height: 120,
                child: GoogleMap(
                  initialCameraPosition:
                      CameraPosition(target: LatLng(lat, lng), zoom: 14),
                  markers: {
                    Marker(
                      markerId: const MarkerId('pin'),
                      position: LatLng(lat, lng),
                    ),
                  },
                  scrollGesturesEnabled: false,
                  zoomControlsEnabled: false,
                  zoomGesturesEnabled: false,
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_selectedWard != null)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.tagPillBg,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.accent),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on,
                              color: AppColors.accent, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            '${_selectedWard!.name} · ${_selectedWard!.circle}',
                            style: GoogleFonts.sourceCodePro(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.tagPillText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _searchController,
                    style: GoogleFonts.sourceCodePro(fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Search or change ward...',
                      prefixIcon: Icon(Icons.search, size: 18),
                    ),
                    onChanged: _filter,
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView.builder(
                itemCount: _filtered.length,
                itemBuilder: (_, i) {
                  final ward = _filtered[i];
                  final selected = _selectedWard?.code == ward.code;
                  return ListTile(
                    dense: true,
                    title: Text(
                      ward.name,
                      style: GoogleFonts.sourceCodePro(
                        fontSize: 13,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400,
                        color: selected
                            ? AppColors.accent
                            : AppColors.primaryText,
                      ),
                    ),
                    subtitle: Text(
                      ward.circle,
                      style: GoogleFonts.sourceCodePro(
                        fontSize: 11,
                        color: AppColors.secondaryText,
                      ),
                    ),
                    trailing: selected
                        ? const Icon(Icons.check, color: AppColors.accent)
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedWard = ward;
                        _searchController.text = ward.name;
                        _filtered = ghmcWards;
                      });
                    },
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: _selectedWard != null ? _next : null,
                child: const Text(AppStrings.preview),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepBar extends StatelessWidget {
  final int current;
  const _StepBar({required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        final done = i + 1 < current;
        final active = i + 1 == current;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            height: 4,
            decoration: BoxDecoration(
              color: done
                  ? AppColors.accent
                  : active
                      ? AppColors.accent.withOpacity(0.6)
                      : AppColors.cardDivider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}
