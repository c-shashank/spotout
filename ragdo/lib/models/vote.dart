class Vote {
  final String id;
  final String issueId;
  final String userId;
  final String voteType; // 'up' | 'down'
  final DateTime createdAt;

  const Vote({
    required this.id,
    required this.issueId,
    required this.userId,
    required this.voteType,
    required this.createdAt,
  });

  factory Vote.fromMap(Map<String, dynamic> map) {
    return Vote(
      id: map['id'] as String,
      issueId: map['issue_id'] as String,
      userId: map['user_id'] as String,
      voteType: map['vote_type'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'issue_id': issueId,
        'user_id': userId,
        'vote_type': voteType,
        'created_at': createdAt.toIso8601String(),
      };
}
