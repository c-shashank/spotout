import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/ghmc_wards.dart';
import '../../../core/services/storage_service.dart';
import '../bloc/auth_bloc.dart';

class ProfileSetupScreen extends StatefulWidget {
  final String uid;
  final String phone;

  const ProfileSetupScreen({super.key, required this.uid, required this.phone});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _nameController = TextEditingController();
  final _wardSearchController = TextEditingController();
  GhmcWard? _selectedWard;
  File? _avatarFile;
  bool _uploading = false;
  String? _lastSetupErrorShown;
  List<GhmcWard> _filteredWards = ghmcWards;

  @override
  void dispose() {
    _nameController.dispose();
    _wardSearchController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() => _avatarFile = File(picked.path));
    }
  }

  void _filterWards(String query) {
    setState(() {
      _filteredWards = ghmcWards
          .where((w) => w.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return;
    }
    if (_selectedWard == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your ward')),
      );
      return;
    }

    String? avatarUrl;
    if (_avatarFile != null) {
      setState(() => _uploading = true);
      try {
        avatarUrl = await StorageService().uploadAvatar(_avatarFile!, widget.uid);
      } catch (_) {}
      setState(() => _uploading = false);
    }

    if (mounted) {
      context.read<AuthBloc>().add(AuthProfileSetup(
            name: _nameController.text.trim(),
            wardId: _selectedWard!.code,
            avatarUrl: avatarUrl,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthNeedsProfileSetup &&
            state.errorMessage != null &&
            state.errorMessage != _lastSetupErrorShown) {
          _lastSetupErrorShown = state.errorMessage;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.appName),
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  AppStrings.setupProfile,
                  style: GoogleFonts.sourceCodePro(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 24),

                // Avatar
                Center(
                  child: GestureDetector(
                    onTap: _pickAvatar,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: AppColors.tagPillBg,
                          backgroundImage: _avatarFile != null
                              ? FileImage(_avatarFile!)
                              : null,
                          child: _avatarFile == null
                              ? const Icon(Icons.person, size: 44, color: AppColors.secondaryText)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Name
                Text(
                  AppStrings.fullName,
                  style: GoogleFonts.sourceCodePro(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  style: GoogleFonts.sourceCodePro(fontSize: 14),
                  decoration: const InputDecoration(hintText: 'Your full name'),
                ),
                const SizedBox(height: 20),

                // Ward search
                Text(
                  AppStrings.selectWard,
                  style: GoogleFonts.sourceCodePro(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _wardSearchController,
                  style: GoogleFonts.sourceCodePro(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search ward...',
                    suffixIcon: _selectedWard != null
                        ? const Icon(Icons.check_circle, color: AppColors.accent)
                        : const Icon(Icons.search, color: AppColors.secondaryText),
                  ),
                  onChanged: _filterWards,
                ),
                if (_selectedWard != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.tagPillBg,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.accent),
                    ),
                    child: Text(
                      '${_selectedWard!.name} · ${_selectedWard!.circle}',
                      style: GoogleFonts.sourceCodePro(
                        fontSize: 13,
                        color: AppColors.tagPillText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                SizedBox(
                  height: 220,
                  child: ListView.builder(
                    itemCount: _filteredWards.length,
                    itemBuilder: (context, index) {
                      final ward = _filteredWards[index];
                      final selected = _selectedWard?.code == ward.code;
                      return ListTile(
                        dense: true,
                        title: Text(
                          ward.name,
                          style: GoogleFonts.sourceCodePro(
                            fontSize: 13,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                            color: selected ? AppColors.accent : AppColors.primaryText,
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
                            _wardSearchController.text = ward.name;
                            _filteredWards = ghmcWards;
                          });
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    return ElevatedButton(
                      onPressed: (state is AuthLoading || _uploading) ? null : _submit,
                      child: (state is AuthLoading || _uploading)
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(AppStrings.completeSetup),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
