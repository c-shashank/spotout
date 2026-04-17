import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jawabdo/core/constants/app_colors.dart';
import 'package:jawabdo/core/constants/app_strings.dart';
import 'package:jawabdo/core/services/db_service.dart';
import 'package:jawabdo/core/services/storage_service.dart';

class TakeActionPanel extends StatefulWidget {
  final String issueId;
  final String authorityId;
  final VoidCallback onSubmitted;
  final VoidCallback onCancel;

  const TakeActionPanel({
    super.key,
    required this.issueId,
    required this.authorityId,
    required this.onSubmitted,
    required this.onCancel,
  });

  @override
  State<TakeActionPanel> createState() => _TakeActionPanelState();
}

class _TakeActionPanelState extends State<TakeActionPanel> {
  static const _actionOptions = [
    _ActionOption(label: 'Acknowledge', value: 'acknowledged'),
    _ActionOption(label: 'Mark In Progress', value: 'in_progress'),
    _ActionOption(label: 'Mark Resolved', value: 'resolved'),
    _ActionOption(label: 'Reject', value: 'rejected'),
  ];

  String _selectedAction = 'acknowledged';
  final _noteController = TextEditingController();
  XFile? _proofPhoto;
  bool _submitting = false;
  String? _error;

  final _db = DbService();
  final _storage = StorageService();
  final _picker = ImagePicker();

  bool get _noteRequired =>
      _selectedAction == 'resolved' || _selectedAction == 'rejected';

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 1080,
      );
      if (file != null) {
        setState(() => _proofPhoto = file);
      }
    } catch (_) {
      // user cancelled or permission denied — silently ignore
    }
  }

  Future<void> _submit() async {
    final note = _noteController.text.trim();

    if (_noteRequired && note.isEmpty) {
      setState(() =>
          _error = 'A note is required when marking as ${_selectedAction == 'resolved' ? 'Resolved' : 'Rejected'}.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      String? uploadedUrl;
      if (_proofPhoto != null) {
        uploadedUrl = await _storage.uploadAuthorityProof(
          File(_proofPhoto!.path),
          widget.authorityId,
        );
      }

      await _db.addAuthorityAction(
        issueId: widget.issueId,
        authorityId: widget.authorityId,
        actionType: _selectedAction,
        note: note.isEmpty ? null : note,
        mediaUrl: uploadedUrl,
      );

      widget.onSubmitted();
    } catch (e) {
      setState(() {
        _error = AppStrings.networkError;
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Action dropdown
          Text(
            AppStrings.updateStatus,
            style: GoogleFonts.sourceCodePro(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryText,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.cardDivider),
              borderRadius: BorderRadius.circular(6),
              color: AppColors.background,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedAction,
                isExpanded: true,
                style: GoogleFonts.sourceCodePro(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
                iconEnabledColor: AppColors.secondaryText,
                items: _actionOptions.map((opt) {
                  return DropdownMenuItem<String>(
                    value: opt.value,
                    child: Text(
                      opt.label,
                      style: GoogleFonts.sourceCodePro(
                        fontSize: 13,
                        color: _actionColor(opt.value),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: _submitting
                    ? null
                    : (val) {
                        if (val != null) {
                          setState(() {
                            _selectedAction = val;
                            _error = null;
                          });
                        }
                      },
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Note field
          Text(
            _noteRequired
                ? '${AppStrings.actionNote} *'
                : AppStrings.actionNote,
            style: GoogleFonts.sourceCodePro(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryText,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _noteController,
            enabled: !_submitting,
            maxLines: 3,
            minLines: 2,
            style: GoogleFonts.sourceCodePro(
              fontSize: 13,
              color: AppColors.primaryText,
            ),
            decoration: InputDecoration(
              hintText: AppStrings.actionNoteHint,
              hintStyle: GoogleFonts.sourceCodePro(
                fontSize: 12,
                color: AppColors.grey,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: AppColors.cardDivider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: AppColors.cardDivider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide:
                    const BorderSide(color: AppColors.accent, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Proof photo
          GestureDetector(
            onTap: _submitting ? null : _pickPhoto,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _proofPhoto != null
                      ? AppColors.statusResolved
                      : AppColors.cardDivider,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(6),
                color: _proofPhoto != null
                    ? AppColors.statusResolved.withOpacity(0.06)
                    : AppColors.tagPillBg,
              ),
              child: Row(
                children: [
                  Icon(
                    _proofPhoto != null
                        ? Icons.check_circle_outline
                        : Icons.add_a_photo_outlined,
                    size: 18,
                    color: _proofPhoto != null
                        ? AppColors.statusResolved
                        : AppColors.secondaryText,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _proofPhoto != null
                          ? 'Photo attached: ${_proofPhoto!.name}'
                          : AppStrings.attachProof,
                      style: GoogleFonts.sourceCodePro(
                        fontSize: 12,
                        color: _proofPhoto != null
                            ? AppColors.statusResolved
                            : AppColors.secondaryText,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_proofPhoto != null)
                    GestureDetector(
                      onTap: () => setState(() => _proofPhoto = null),
                      child: const Icon(Icons.close,
                          size: 16, color: AppColors.secondaryText),
                    ),
                ],
              ),
            ),
          ),

          // Error
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: GoogleFonts.sourceCodePro(
                fontSize: 11,
                color: AppColors.statusOpen,
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _submitting ? null : widget.onCancel,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.cardDivider),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6)),
                  ),
                  child: Text(
                    AppStrings.cancel,
                    style: GoogleFonts.sourceCodePro(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6)),
                    elevation: 0,
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          AppStrings.submitUpdate,
                          style: GoogleFonts.sourceCodePro(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _actionColor(String value) {
    switch (value) {
      case 'resolved':
        return AppColors.statusResolved;
      case 'rejected':
        return AppColors.statusRejected;
      case 'in_progress':
        return AppColors.statusInProgress;
      default:
        return AppColors.tierMunicipal;
    }
  }
}

class _ActionOption {
  final String label;
  final String value;
  const _ActionOption({required this.label, required this.value});
}
