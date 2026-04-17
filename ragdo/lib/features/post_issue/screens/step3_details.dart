import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/issue_categories.dart';
import '../bloc/post_issue_bloc.dart';
import 'step4_ward.dart';

class Step3DetailsScreen extends StatefulWidget {
  const Step3DetailsScreen({super.key});

  @override
  State<Step3DetailsScreen> createState() => _Step3DetailsScreenState();
}

class _Step3DetailsScreenState extends State<Step3DetailsScreen> {
  String? _selectedCategory;
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _next() {
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }
    if (_descController.text.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a description (min 10 chars)')),
      );
      return;
    }
    context.read<PostIssueBloc>().add(PostIssueUpdateDetails(
          _selectedCategory!,
          _titleController.text.trim(),
          _descController.text.trim(),
        ));
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<PostIssueBloc>(),
          child: const Step4WardScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${AppStrings.postIssue} — Step 3 of 5',
          style: GoogleFonts.sourceCodePro(fontSize: 14),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _StepBar(current: 3),
              const SizedBox(height: 20),
              Text(
                AppStrings.step3Title,
                style: GoogleFonts.sourceCodePro(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              // Category grid
              Text(
                AppStrings.selectCategory,
                style: GoogleFonts.sourceCodePro(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.5,
                ),
                itemCount: issueCategories.length,
                itemBuilder: (_, i) {
                  final cat = issueCategories[i];
                  final selected = _selectedCategory == cat.value;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat.value),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: selected ? cat.color : AppColors.cardDivider,
                          width: selected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(4),
                        color: selected ? cat.color.withOpacity(0.1) : null,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        children: [
                          Icon(cat.icon, color: cat.color, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              cat.label.split(' ').first,
                              style: GoogleFonts.sourceCodePro(
                                fontSize: 12,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: selected ? cat.color : AppColors.primaryText,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                AppStrings.issueTitle,
                style: GoogleFonts.sourceCodePro(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              ValueListenableBuilder(
                valueListenable: _titleController,
                builder: (_, __, ___) => TextField(
                  controller: _titleController,
                  maxLength: 80,
                  style: GoogleFonts.sourceCodePro(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: AppStrings.issueTitleHint,
                    counterText: '${_titleController.text.length}/80',
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                AppStrings.issueDescription,
                style: GoogleFonts.sourceCodePro(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              ValueListenableBuilder(
                valueListenable: _descController,
                builder: (_, __, ___) => TextField(
                  controller: _descController,
                  maxLength: 500,
                  maxLines: 5,
                  minLines: 3,
                  style: GoogleFonts.sourceCodePro(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: AppStrings.issueDescriptionHint,
                    counterText: '${_descController.text.length}/500',
                    alignLabelWithHint: true,
                  ),
                ),
              ),
              const SizedBox(height: 20),

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
