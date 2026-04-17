import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../bloc/post_issue_bloc.dart';
import 'step2_location.dart';

class Step1PhotoScreen extends StatefulWidget {
  const Step1PhotoScreen({super.key});

  @override
  State<Step1PhotoScreen> createState() => _Step1PhotoScreenState();
}

class _Step1PhotoScreenState extends State<Step1PhotoScreen> {
  final List<File> _photos = [];
  final _picker = ImagePicker();

  Future<void> _pickFromCamera() async {
    if (_photos.length >= 3) return;
    final pic = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (pic != null) setState(() => _photos.add(File(pic.path)));
  }

  Future<void> _pickFromGallery() async {
    if (_photos.length >= 3) return;
    final pics = await _picker.pickMultiImage(imageQuality: 80, limit: 3 - _photos.length);
    if (pics.isNotEmpty) {
      setState(() {
        for (final p in pics) {
          if (_photos.length < 3) _photos.add(File(p.path));
        }
      });
    }
  }

  void _next() {
    if (_photos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.photoRequired)),
      );
      return;
    }
    context.read<PostIssueBloc>().add(PostIssueUpdatePhotos(_photos));
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<PostIssueBloc>(),
          child: const Step2LocationScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${AppStrings.postIssue} — Step 1 of 5',
          style: GoogleFonts.sourceCodePro(fontSize: 14),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Step progress
              const _StepProgress(current: 1),
              const SizedBox(height: 20),
              Text(
                AppStrings.step1Title,
                style: GoogleFonts.sourceCodePro(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Take at least 1 photo (max 3) of the issue.',
                style: GoogleFonts.sourceCodePro(
                  fontSize: 12,
                  color: AppColors.secondaryText,
                ),
              ),
              const SizedBox(height: 20),

              // Photo thumbnails
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ..._photos.asMap().entries.map((e) => _PhotoThumb(
                          file: e.value,
                          onDelete: () => setState(() => _photos.removeAt(e.key)),
                        )),
                    if (_photos.length < 3)
                      _AddPhotoButton(
                        onCamera: _pickFromCamera,
                        onGallery: _pickFromGallery,
                      ),
                  ],
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _next,
                child: const Text(AppStrings.nextStep),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  final File file;
  final VoidCallback onDelete;

  const _PhotoThumb({required this.file, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 90,
          height: 90,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            image: DecorationImage(image: FileImage(file), fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: 2,
          right: 10,
          child: GestureDetector(
            onTap: onDelete,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddPhotoButton extends StatelessWidget {
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  const _AddPhotoButton({required this.onCamera, required this.onGallery});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          builder: (_) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: Text('Camera', style: GoogleFonts.sourceCodePro()),
                  onTap: () {
                    Navigator.pop(context);
                    onCamera();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: Text('Gallery', style: GoogleFonts.sourceCodePro()),
                  onTap: () {
                    Navigator.pop(context);
                    onGallery();
                  },
                ),
              ],
            ),
          ),
        );
      },
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.accent, width: 2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo, color: AppColors.accent, size: 28),
            SizedBox(height: 4),
            Text('Add',
                style: TextStyle(fontSize: 11, color: AppColors.accent)),
          ],
        ),
      ),
    );
  }
}

class _StepProgress extends StatelessWidget {
  final int current;
  const _StepProgress({required this.current});

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
