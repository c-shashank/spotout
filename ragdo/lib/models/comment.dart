import 'package:equatable/equatable.dart';

class Comment extends Equatable {
  final String id;
  final String issueId;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String text;
  final String? mediaUrl;
  final String? parentCommentId;
  final DateTime createdAt;
  final int upvoteCount;
  final List<Comment> replies;
  final bool userHasUpvoted;

  const Comment({
    required this.id,
    required this.issueId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.text,
    this.mediaUrl,
    this.parentCommentId,
    required this.createdAt,
    this.upvoteCount = 0,
    this.replies = const [],
    this.userHasUpvoted = false,
  });

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      id: map['id'] as String,
      issueId: map['issue_id'] as String,
      userId: map['user_id'] as String,
      userName: map['user_name'] as String? ?? 'Unknown',
      userAvatar: map['user_avatar'] as String?,
      text: map['text'] as String,
      mediaUrl: map['media_url'] as String?,
      parentCommentId: map['parent_comment_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      upvoteCount: map['upvote_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'issue_id': issueId,
        'user_id': userId,
        'text': text,
        'media_url': mediaUrl,
        'parent_comment_id': parentCommentId,
        'created_at': createdAt.toIso8601String(),
        'upvote_count': upvoteCount,
      };

  Comment copyWith({int? upvoteCount, bool? userHasUpvoted, List<Comment>? replies}) {
    return Comment(
      id: id,
      issueId: issueId,
      userId: userId,
      userName: userName,
      userAvatar: userAvatar,
      text: text,
      mediaUrl: mediaUrl,
      parentCommentId: parentCommentId,
      createdAt: createdAt,
      upvoteCount: upvoteCount ?? this.upvoteCount,
      replies: replies ?? this.replies,
      userHasUpvoted: userHasUpvoted ?? this.userHasUpvoted,
    );
  }

  @override
  List<Object?> get props => [id, upvoteCount, replies.length];
}
