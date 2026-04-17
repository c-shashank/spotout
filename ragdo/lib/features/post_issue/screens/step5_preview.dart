import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/ghmc_wards.dart';
import '../../../core/constants/issue_categories.dart';
import '../bloc/post_issue_bloc.dart';
import '../../feed/widgets/tag_pill.dart';

class Step5PreviewScreen extends StatelessWidget {
  const Step5PreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PostIssueBloc, PostIssueState>(
      listener: (context, state) {
        if (state is PostIssueSuccess) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => SuccessScreen(issueId: state.issueId),
            ),
          );
        }
        if (state is PostIssueError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        if (state is! PostIssueEditing) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            ),
          );
        }
        final data = state.data;
        final category = data.category != null
            ? categoryFromValue(data.category!)
            : issueCategories.first;
        final ward = data.wardId != null
            ? ghmcWards.firstWhere(
                (w) => w.code == data.wardId,
                orElse: () =>
                    GhmcWard(code: data.wardId!, name: data.wardId!, circle: ''),
              )
            : null;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              '${AppStrings.postIssue} — Step 5 of 5',
              style: GoogleFonts.sourceCodePro(fontSize: 14),
            ),
          ),
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: _StepBar(current: 5),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(
                    AppStrings.step5Title,
                    style: GoogleFonts.sourceCodePro(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Photo preview
                        if (data.photos.isNotEmpty)
                          SizedBox(
                            height: 200,
                            child: PageView(
                              children: data.photos
                                  .map((f) => Image.file(f, fit: BoxFit.cover, width: double.infinity))
                                  .toList(),
                            ),
                          ),

                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  TagPill(label: category.label, dotColor: category.color),
                                  const SizedBox(width: 6),
                                  if (ward != null) TagPill(label: ward.name),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                data.title,
                                style: GoogleFonts.sourceCodePro(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryText,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                data.description,
                                style: GoogleFonts.sourceCodePro(
                                  fontSize: 13,
                                  color: AppColors.secondaryText,
                                ),
                              ),
                              if (data.addressLabel != null) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on,
                                        size: 14, color: AppColors.secondaryText),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        data.addressLabel!,
                                        style: GoogleFonts.sourceCodePro(
                                          fontSize: 11,
                                          color: AppColors.secondaryText,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(
                                  'Edit',
                                  style: GoogleFonts.sourceCodePro(
                                    color: AppColors.secondaryText,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: BlocBuilder<PostIssueBloc, PostIssueState>(
                    builder: (context, state) {
                      final submitting = state is PostIssueSubmitting;
                      return ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: submitting
                            ? null
                            : () => context.read<PostIssueBloc>().add(const PostIssueSubmit()),
                        child: submitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                AppStrings.jawabdoIt,
                                style: GoogleFonts.sourceCodePro(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Holder for passing userId down through navigation without BLoC
class _UserHolder extends InheritedWidget {
  final String userId;
  const _UserHolder({required this.userId, required super.child});

  @override
  bool updateShouldNotify(_UserHolder old) => userId != old.userId;
}

class SuccessScreen extends StatelessWidget {
  final String issueId;
  const SuccessScreen({super.key, required this.issueId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: AppColors.accent, size: 72),
              const SizedBox(height: 20),
              Text(
                AppStrings.issueJawab Dod,
                style: GoogleFonts.sourceCodePro(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Your issue has been posted and assigned to the ward authority.',
                style: GoogleFonts.sourceCodePro(
                  fontSize: 13,
                  color: AppColors.secondaryText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  // Pop all the way back to citizen home
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('Go to Feed'),
              ),
            ],
          ),
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
