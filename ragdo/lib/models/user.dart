import 'package:equatable/equatable.dart';

enum UserRole {
  citizen,
  wardAuthority,
  municipalAuthority,
  stateAuthority,
  mediaNgo,
  admin,
}

UserRole userRoleFromString(String value) {
  switch (value) {
    case 'ward_authority':
      return UserRole.wardAuthority;
    case 'municipal_authority':
      return UserRole.municipalAuthority;
    case 'state_authority':
      return UserRole.stateAuthority;
    case 'media_ngo':
      return UserRole.mediaNgo;
    case 'admin':
      return UserRole.admin;
    default:
      return UserRole.citizen;
  }
}

String userRoleToString(UserRole role) {
  switch (role) {
    case UserRole.wardAuthority:
      return 'ward_authority';
    case UserRole.municipalAuthority:
      return 'municipal_authority';
    case UserRole.stateAuthority:
      return 'state_authority';
    case UserRole.mediaNgo:
      return 'media_ngo';
    case UserRole.admin:
      return 'admin';
    case UserRole.citizen:
      return 'citizen';
  }
}

class Jawab DoUser extends Equatable {
  final String id;
  final String? phone;
  final String? email;
  final String name;
  final String? wardId;
  final String? avatarUrl;
  final UserRole role;
  final String? department;
  final List<String> jurisdictionWards;
  final DateTime createdAt;
  final int karmaScore;
  final int issuesFiledCount;
  final int issuesResolvedCount;

  const Jawab DoUser({
    required this.id,
    this.phone,
    this.email,
    required this.name,
    this.wardId,
    this.avatarUrl,
    required this.role,
    this.department,
    this.jurisdictionWards = const [],
    required this.createdAt,
    this.karmaScore = 0,
    this.issuesFiledCount = 0,
    this.issuesResolvedCount = 0,
  });

  bool get isAuthority => role != UserRole.citizen;
  bool get isCitizen => role == UserRole.citizen;

  factory Jawab DoUser.fromMap(Map<String, dynamic> map) {
    return Jawab DoUser(
      id: map['id'] as String,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      name: map['name'] as String,
      wardId: map['ward_id'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      role: userRoleFromString(map['role'] as String? ?? 'citizen'),
      department: map['department'] as String?,
      jurisdictionWards: List<String>.from(map['jurisdiction_wards'] ?? []),
      createdAt: DateTime.parse(map['created_at'] as String),
      karmaScore: map['karma_score'] as int? ?? 0,
      issuesFiledCount: map['issues_filed_count'] as int? ?? 0,
      issuesResolvedCount: map['issues_resolved_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'phone': phone,
      'email': email,
      'name': name,
      'ward_id': wardId,
      'avatar_url': avatarUrl,
      'role': userRoleToString(role),
      'department': department,
      'jurisdiction_wards': jurisdictionWards,
      'created_at': createdAt.toIso8601String(),
      'karma_score': karmaScore,
      'issues_filed_count': issuesFiledCount,
      'issues_resolved_count': issuesResolvedCount,
    };
  }

  Jawab DoUser copyWith({
    String? name,
    String? wardId,
    String? avatarUrl,
    int? karmaScore,
    int? issuesFiledCount,
    int? issuesResolvedCount,
  }) {
    return Jawab DoUser(
      id: id,
      phone: phone,
      email: email,
      name: name ?? this.name,
      wardId: wardId ?? this.wardId,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role,
      department: department,
      jurisdictionWards: jurisdictionWards,
      createdAt: createdAt,
      karmaScore: karmaScore ?? this.karmaScore,
      issuesFiledCount: issuesFiledCount ?? this.issuesFiledCount,
      issuesResolvedCount: issuesResolvedCount ?? this.issuesResolvedCount,
    );
  }

  @override
  List<Object?> get props => [id, name, role, karmaScore];
}
