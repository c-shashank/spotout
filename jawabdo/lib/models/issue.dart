import 'package:equatable/equatable.dart';

enum IssueStatus { open, inProgress, resolved, rejected }

enum EscalationTier { ward, municipal, state, mediaNgo }

IssueStatus issueStatusFromString(String value) {
  switch (value) {
    case 'in_progress':
      return IssueStatus.inProgress;
    case 'resolved':
      return IssueStatus.resolved;
    case 'rejected':
      return IssueStatus.rejected;
    default:
      return IssueStatus.open;
  }
}

String issueStatusToString(IssueStatus status) {
  switch (status) {
    case IssueStatus.inProgress:
      return 'in_progress';
    case IssueStatus.resolved:
      return 'resolved';
    case IssueStatus.rejected:
      return 'rejected';
    case IssueStatus.open:
      return 'open';
  }
}

EscalationTier escalationTierFromString(String value) {
  switch (value) {
    case 'municipal':
      return EscalationTier.municipal;
    case 'state':
      return EscalationTier.state;
    case 'media_ngo':
      return EscalationTier.mediaNgo;
    default:
      return EscalationTier.ward;
  }
}

String escalationTierToString(EscalationTier tier) {
  switch (tier) {
    case EscalationTier.municipal:
      return 'municipal';
    case EscalationTier.state:
      return 'state';
    case EscalationTier.mediaNgo:
      return 'media_ngo';
    case EscalationTier.ward:
      return 'ward';
  }
}

class EscalationHistoryEntry {
  final String tier;
  final String triggeredBy;
  final DateTime triggeredAt;
  final String reason;

  const EscalationHistoryEntry({
    required this.tier,
    required this.triggeredBy,
    required this.triggeredAt,
    required this.reason,
  });

  factory EscalationHistoryEntry.fromMap(Map<String, dynamic> map) {
    return EscalationHistoryEntry(
      tier: map['tier'] as String,
      triggeredBy: map['triggered_by'] as String,
      triggeredAt: DateTime.parse(map['triggered_at'] as String),
      reason: map['reason'] as String,
    );
  }

  Map<String, dynamic> toMap() => {
        'tier': tier,
        'triggered_by': triggeredBy,
        'triggered_at': triggeredAt.toIso8601String(),
        'reason': reason,
      };
}

class Issue extends Equatable {
  final String id;
  final String title;
  final String description;
  final String category;
  final IssueStatus status;
  final double locationLat;
  final double locationLng;
  final String addressLabel;
  final String wardId;
  final List<String> mediaUrls;
  final String createdBy;
  final String? createdByName;
  final String? createdByAvatar;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int upvoteCount;
  final int downvoteCount;
  final int commentCount;
  final int shareCount;
  final int viewCount;
  final EscalationTier escalationTier;
  final List<EscalationHistoryEntry> escalationHistory;
  final bool isResolved;
  final DateTime? resolvedAt;
  final String? resolutionNote;
  final String? assignedTo;
  final bool priorityFlag;

  // Local state (not persisted)
  final bool? userHasUpvoted;
  final bool? userHasDownvoted;
  final bool? userHasBookmarked;

  const Issue({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.locationLat,
    required this.locationLng,
    required this.addressLabel,
    required this.wardId,
    this.mediaUrls = const [],
    required this.createdBy,
    this.createdByName,
    this.createdByAvatar,
    required this.createdAt,
    required this.updatedAt,
    this.upvoteCount = 0,
    this.downvoteCount = 0,
    this.commentCount = 0,
    this.shareCount = 0,
    this.viewCount = 0,
    this.escalationTier = EscalationTier.ward,
    this.escalationHistory = const [],
    this.isResolved = false,
    this.resolvedAt,
    this.resolutionNote,
    this.assignedTo,
    this.priorityFlag = false,
    this.userHasUpvoted,
    this.userHasDownvoted,
    this.userHasBookmarked,
  });

  factory Issue.fromMap(Map<String, dynamic> map) {
    final historyRaw = map['escalation_history'];
    List<EscalationHistoryEntry> history = [];
    if (historyRaw != null) {
      history = (historyRaw as List)
          .map((e) => EscalationHistoryEntry.fromMap(e as Map<String, dynamic>))
          .toList();
    }

    return Issue(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      category: map['category'] as String,
      status: issueStatusFromString(map['status'] as String? ?? 'open'),
      locationLat: (map['location_lat'] as num).toDouble(),
      locationLng: (map['location_lng'] as num).toDouble(),
      addressLabel: map['address_label'] as String? ?? '',
      wardId: map['ward_id'] as String? ?? '',
      mediaUrls: List<String>.from(map['media_urls'] ?? []),
      createdBy: map['created_by'] as String,
      createdByName: map['created_by_name'] as String?,
      createdByAvatar: map['created_by_avatar'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      upvoteCount: map['upvote_count'] as int? ?? 0,
      downvoteCount: map['downvote_count'] as int? ?? 0,
      commentCount: map['comment_count'] as int? ?? 0,
      shareCount: map['share_count'] as int? ?? 0,
      viewCount: map['view_count'] as int? ?? 0,
      escalationTier:
          escalationTierFromString(map['escalation_tier'] as String? ?? 'ward'),
      escalationHistory: history,
      isResolved: map['is_resolved'] as bool? ?? false,
      resolvedAt: map['resolved_at'] != null
          ? DateTime.parse(map['resolved_at'] as String)
          : null,
      resolutionNote: map['resolution_note'] as String?,
      assignedTo: map['assigned_to'] as String?,
      priorityFlag: map['priority_flag'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'status': issueStatusToString(status),
      'location_lat': locationLat,
      'location_lng': locationLng,
      'address_label': addressLabel,
      'ward_id': wardId,
      'media_urls': mediaUrls,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'upvote_count': upvoteCount,
      'downvote_count': downvoteCount,
      'comment_count': commentCount,
      'share_count': shareCount,
      'view_count': viewCount,
      'escalation_tier': escalationTierToString(escalationTier),
      'escalation_history': escalationHistory.map((e) => e.toMap()).toList(),
      'is_resolved': isResolved,
      'resolved_at': resolvedAt?.toIso8601String(),
      'resolution_note': resolutionNote,
      'assigned_to': assignedTo,
      'priority_flag': priorityFlag,
    };
  }

  Issue copyWith({
    IssueStatus? status,
    int? upvoteCount,
    int? downvoteCount,
    int? commentCount,
    int? viewCount,
    EscalationTier? escalationTier,
    bool? priorityFlag,
    bool? isResolved,
    bool? userHasUpvoted,
    bool? userHasDownvoted,
    bool? userHasBookmarked,
  }) {
    return Issue(
      id: id,
      title: title,
      description: description,
      category: category,
      status: status ?? this.status,
      locationLat: locationLat,
      locationLng: locationLng,
      addressLabel: addressLabel,
      wardId: wardId,
      mediaUrls: mediaUrls,
      createdBy: createdBy,
      createdByName: createdByName,
      createdByAvatar: createdByAvatar,
      createdAt: createdAt,
      updatedAt: updatedAt,
      upvoteCount: upvoteCount ?? this.upvoteCount,
      downvoteCount: downvoteCount ?? this.downvoteCount,
      commentCount: commentCount ?? this.commentCount,
      shareCount: shareCount,
      viewCount: viewCount ?? this.viewCount,
      escalationTier: escalationTier ?? this.escalationTier,
      escalationHistory: escalationHistory,
      isResolved: isResolved ?? this.isResolved,
      resolvedAt: resolvedAt,
      resolutionNote: resolutionNote,
      assignedTo: assignedTo,
      priorityFlag: priorityFlag ?? this.priorityFlag,
      userHasUpvoted: userHasUpvoted ?? this.userHasUpvoted,
      userHasDownvoted: userHasDownvoted ?? this.userHasDownvoted,
      userHasBookmarked: userHasBookmarked ?? this.userHasBookmarked,
    );
  }

  @override
  List<Object?> get props => [id, status, upvoteCount, downvoteCount, commentCount, escalationTier];
}
