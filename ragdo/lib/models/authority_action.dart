import 'package:equatable/equatable.dart';

enum AuthorityActionType {
  acknowledged,
  inProgress,
  resolved,
  rejected,
  escalated,
  comment,
}

AuthorityActionType actionTypeFromString(String value) {
  switch (value) {
    case 'in_progress':
      return AuthorityActionType.inProgress;
    case 'resolved':
      return AuthorityActionType.resolved;
    case 'rejected':
      return AuthorityActionType.rejected;
    case 'escalated':
      return AuthorityActionType.escalated;
    case 'comment':
      return AuthorityActionType.comment;
    default:
      return AuthorityActionType.acknowledged;
  }
}

String actionTypeToString(AuthorityActionType type) {
  switch (type) {
    case AuthorityActionType.inProgress:
      return 'in_progress';
    case AuthorityActionType.resolved:
      return 'resolved';
    case AuthorityActionType.rejected:
      return 'rejected';
    case AuthorityActionType.escalated:
      return 'escalated';
    case AuthorityActionType.comment:
      return 'comment';
    case AuthorityActionType.acknowledged:
      return 'acknowledged';
  }
}

class AuthorityAction extends Equatable {
  final String id;
  final String issueId;
  final String authorityId;
  final String? authorityName;
  final String? authorityDepartment;
  final String? authorityWard;
  final AuthorityActionType actionType;
  final String? note;
  final String? mediaUrl;
  final bool isInternal;
  final DateTime createdAt;

  const AuthorityAction({
    required this.id,
    required this.issueId,
    required this.authorityId,
    this.authorityName,
    this.authorityDepartment,
    this.authorityWard,
    required this.actionType,
    this.note,
    this.mediaUrl,
    this.isInternal = false,
    required this.createdAt,
  });

  factory AuthorityAction.fromMap(Map<String, dynamic> map) {
    return AuthorityAction(
      id: map['id'] as String,
      issueId: map['issue_id'] as String,
      authorityId: map['authority_id'] as String,
      authorityName: map['authority_name'] as String?,
      authorityDepartment: map['authority_department'] as String?,
      authorityWard: map['authority_ward'] as String?,
      actionType: actionTypeFromString(map['action_type'] as String),
      note: map['note'] as String?,
      mediaUrl: map['media_url'] as String?,
      isInternal: map['is_internal'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'issue_id': issueId,
        'authority_id': authorityId,
        'action_type': actionTypeToString(actionType),
        'note': note,
        'media_url': mediaUrl,
        'is_internal': isInternal,
        'created_at': createdAt.toIso8601String(),
      };

  String get actionLabel {
    switch (actionType) {
      case AuthorityActionType.acknowledged:
        return 'Acknowledged';
      case AuthorityActionType.inProgress:
        return 'Marked In Progress';
      case AuthorityActionType.resolved:
        return 'Resolved';
      case AuthorityActionType.rejected:
        return 'Rejected';
      case AuthorityActionType.escalated:
        return 'Escalated';
      case AuthorityActionType.comment:
        return 'Comment';
    }
  }

  @override
  List<Object?> get props => [id, actionType];
}
