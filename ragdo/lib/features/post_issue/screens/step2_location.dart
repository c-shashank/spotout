import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/location_service.dart';
import '../bloc/post_issue_bloc.dart';
import 'step3_details.dart';

class Step2LocationScreen extends StatefulWidget {
  const Step2LocationScreen({super.key});

  @override
  State<Step2LocationScreen> createState() => _Step2LocationScreenState();
}

class _Step2LocationScreenState extends State<Step2LocationScreen> {
  final _locationService = LocationService();
  GoogleMapController? _mapController;
  LatLng? _pinPosition;
  String _addressLabel = '';
  bool _loadingLocation = true;
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    setState(() => _loadingLocation = true);
    final denied = await _locationService.isPermissionDeniedForever();
    if (denied) {
      setState(() {
        _permissionDenied = true;
        _loadingLocation = false;
      });
      return;
    }
    final pos = await _locationService.getCurrentPosition();
    if (pos == null) {
      setState(() {
        _permissionDenied = true;
        _loadingLocation = false;
      });
      return;
    }
    final address = await _locationService.getAddressFromCoordinates(
        pos.latitude, pos.longitude);
    setState(() {
      _pinPosition = LatLng(pos.latitude, pos.longitude);
      _addressLabel = address;
      _loadingLocation = false;
    });
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(_pinPosition!, 16),
    );
  }

  Future<void> _onPinDragged(LatLng pos) async {
    setState(() => _pinPosition = pos);
    final address = await _locationService.getAddressFromCoordinates(
        pos.latitude, pos.longitude);
    setState(() => _addressLabel = address);
  }

  void _next() {
    if (_pinPosition == null) return;
    context.read<PostIssueBloc>().add(PostIssueUpdateLocation(
          _pinPosition!.latitude,
          _pinPosition!.longitude,
          _addressLabel,
          null, // ward will be detected in step 4
        ));
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<PostIssueBloc>(),
          child: const Step3DetailsScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${AppStrings.postIssue} — Step 2 of 5',
          style: GoogleFonts.sourceCodePro(fontSize: 14),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _StepProgressBar(current: 2),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                AppStrings.step2Title,
                style: GoogleFonts.sourceCodePro(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (_permissionDenied)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_off, size: 48, color: AppColors.accent),
                      const SizedBox(height: 12),
                      Text(
                        AppStrings.locationPermissionDenied,
                        style: GoogleFonts.sourceCodePro(
                          fontSize: 13,
                          color: AppColors.primaryText,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _locationService.openSettings(),
                        child: const Text(AppStrings.locationPermissionSettings),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: _loadingLocation
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.accent))
                    : GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _pinPosition ?? const LatLng(17.385, 78.4867),
                          zoom: 15,
                        ),
                        onMapCreated: (c) => _mapController = c,
                        markers: _pinPosition != null
                            ? {
                                Marker(
                                  markerId: const MarkerId('pin'),
                                  position: _pinPosition!,
                                  draggable: true,
                                  icon: BitmapDescriptor.defaultMarkerWithHue(
                                      BitmapDescriptor.hueRed),
                                  onDragEnd: _onPinDragged,
                                ),
                              }
                            : {},
                        myLocationButtonEnabled: false,
                        onLongPress: _onPinDragged,
                      ),
              ),
            if (!_permissionDenied && !_loadingLocation) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                  _addressLabel,
                  style: GoogleFonts.sourceCodePro(
                    fontSize: 12,
                    color: AppColors.secondaryText,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.my_location, size: 16),
                      label: const Text(AppStrings.useCurrentLocation),
                      onPressed: _fetchLocation,
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _pinPosition != null ? _next : null,
                      child: const Text(AppStrings.nextStep),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StepProgressBar extends StatelessWidget {
  final int current;
  const _StepProgressBar({required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        final active = i + 1 == current;
        final done = i + 1 < current;
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
