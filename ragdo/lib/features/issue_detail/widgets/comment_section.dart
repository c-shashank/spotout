import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../models/comment.dart';

class CommentSection extends StatefulWidget {
  final List<Comment> comments;
  final String currentUserId;
  final String? currentUserAvatar;
  final Function(String text, String? parentId) onAddComment;
  final Function(String commentId) onUpvoteComment;
  final ValueChanged<String> onSortChanged;
  final String sort;

  const CommentSection({
    super.key,
    required this.comments,
    required this.currentUserId,
    this.currentUserAvatar,
    required this.onAddComment,
    required this.onUpvoteComment,
    required this.onSortChanged,
    this.sort = 'recent',
  });

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  final _commentController = TextEditingController();
  String? _replyingToId;
  String? _replyingToName;
  final _focusNode = FocusNode();
  String? _mentionQuery;

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submitComment() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    widget.onAddComment(text, _replyingToId);
    _commentController.clear();
    setState(() {
      _replyingToId = null;
      _replyingToName = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Text(
                '${AppStrings.comments} (${widget.comments.length})',
                style: GoogleFonts.sourceCodePro(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
              ),
              const Spacer(),
              _SortToggle(
                current: widget.sort,
                onChanged: widget.onSortChanged,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ...widget.comments.map((c) => _CommentItem(
              comment: c,
              onReply: (id, name) {
                setState(() {
                  _replyingToId = id;
                  _replyingToName = name;
                });
                _focusNode.requestFocus();
              },
              onUpvote: () => widget.onUpvoteComment(c.id),
            )),
        const SizedBox(height: 60), // space for sticky input bar
      ],
    );
  }
}

class CommentInputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String? replyingToName;
  final VoidCallback onSubmit;
  final VoidCallback? onCancelReply;
  final String? avatarUrl;

  const CommentInputBar({
    super.key,
    required this.controller,
    required this.focusNode,
    this.replyingToName,
    required this.onSubmit,
    this.onCancelReply,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (replyingToName != null)
            GestureDetector(
              onTap: onCancelReply,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Text(
                      'Replying to @$replyingToName  ✕',
                      style: GoogleFonts.sourceCodePro(
                        fontSize: 11,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.tagPillBg,
                backgroundImage:
                    avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                child: avatarUrl == null
                    ? const Icon(Icons.person, size: 16, color: AppColors.secondaryText)
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  style: GoogleFonts.sourceCodePro(fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: AppStrings.addComment,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  maxLines: 3,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSubmit(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onSubmit,
                icon: const Icon(Icons.send, color: AppColors.accent),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CommentItem extends StatefulWidget {
  final Comment comment;
  final Function(String id, String name) onReply;
  final VoidCallback onUpvote;

  const _CommentItem({
    required this.comment,
    required this.onReply,
    required this.onUpvote,
  });

  @override
  State<_CommentItem> createState() => _CommentItemState();
}

class _CommentItemState extends State<_CommentItem> {
  bool _showReplies = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.comment;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.tagPillBg,
                backgroundImage:
                    c.userAvatar != null ? NetworkImage(c.userAvatar!) : null,
                child: c.userAvatar == null
                    ? const Icon(Icons.person, size: 14, color: AppColors.secondaryText)
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '@${c.userName.replaceAll(' ', '').toLowerCase()}',
                          style: GoogleFonts.sourceCodePro(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.accent,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeago.format(c.createdAt),
                          style: GoogleFonts.sourceCodePro(
                            fontSize: 11,
                            color: AppColors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    _buildCommentText(c.text),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: widget.onUpvote,
                          child: Row(
                            children: [
                              const Icon(Icons.sports_mma,
                                  size: 14, color: AppColors.secondaryText),
                              const SizedBox(width: 3),
                              Text(
                                '${c.upvoteCount}',
                                style: GoogleFonts.sourceCodePro(
                                  fontSize: 11,
                                  color: AppColors.secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        GestureDetector(
                          onTap: () => widget.onReply(
                              c.id, c.userName.replaceAll(' ', '').toLowerCase()),
                          child: Text(
                            AppStrings.reply,
                            style: GoogleFonts.sourceCodePro(
                              fontSize: 11,
                              color: AppColors.secondaryText,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Replies
          if (c.replies.isNotEmpty) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _showReplies = !_showReplies),
                    child: Text(
                      _showReplies
                          ? AppStrings.hideReplies
                          : '${AppStrings.viewReplies} (${c.replies.length})',
                      style: GoogleFonts.sourceCodePro(
                        fontSize: 11,
                        color: AppColors.accent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (_showReplies)
                    ...c.replies.map((reply) => Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: AppColors.tagPillBg,
                                backgroundImage: reply.userAvatar != null
                                    ? NetworkImage(reply.userAvatar!)
                                    : null,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          '@${reply.userName.replaceAll(' ', '').toLowerCase()}',
                                          style: GoogleFonts.sourceCodePro(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.accent,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          timeago.format(reply.createdAt),
                                          style: GoogleFonts.sourceCodePro(
                                            fontSize: 10,
                                            color: AppColors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    _buildCommentText(reply.text),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )),
                ],
              ),
            ),
          ],
          const Divider(height: 16, thickness: 1, color: AppColors.cardDivider),
        ],
      ),
    );
  }

  Widget _buildCommentText(String text) {
    // Highlight @mentions
    final spans = <TextSpan>[];
    final regex = RegExp(r'@\w+');
    int last = 0;
    for (final match in regex.allMatches(text)) {
      if (match.start > last) {
        spans.add(TextSpan(
          text: text.substring(last, match.start),
          style: GoogleFonts.sourceCodePro(
            fontSize: 12,
            color: AppColors.primaryText,
          ),
        ));
      }
      spans.add(TextSpan(
        text: match.group(0),
        style: GoogleFonts.sourceCodePro(
          fontSize: 12,
          color: AppColors.accent,
          fontWeight: FontWeight.w500,
        ),
      ));
      last = match.end;
    }
    if (last < text.length) {
      spans.add(TextSpan(
        text: text.substring(last),
        style: GoogleFonts.sourceCodePro(
          fontSize: 12,
          color: AppColors.primaryText,
        ),
      ));
    }
    return RichText(text: TextSpan(children: spans));
  }
}

class _SortToggle extends StatelessWidget {
  final String current;
  final ValueChanged<String> onChanged;

  const _SortToggle({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _tab('Top', 'top'),
        _tab('Recent', 'recent'),
      ],
    );
  }

  Widget _tab(String label, String value) {
    final active = current == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active ? AppColors.accent : AppColors.tagPillBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.sourceCodePro(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: active ? Colors.white : AppColors.tagPillText,
          ),
        ),
      ),
    );
  }
}
