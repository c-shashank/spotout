import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/issue.dart';
import '../../models/comment.dart';
import '../../models/authority_action.dart';

class DbService {
  final SupabaseClient _db = Supabase.instance.client;

  // ── Issues ────────────────────────────────────────────────────────────────

  Future<List<Issue>> fetchFeed({
    required String filter, // all|near_me|my_ward|trending|escalated|resolved
    String? wardId,
    double? userLat,
    double? userLng,
    int page = 0,
    int pageSize = 20,
  }) async {
    final from = page * pageSize;
    final to = (page + 1) * pageSize - 1;

    late List response;
    switch (filter) {
      case 'my_ward':
        final q = _db.from('issues_with_creators').select();
        if (wardId != null) {
          response = await q.eq('ward_id', wardId).order('created_at', ascending: false).range(from, to);
        } else {
          response = await q.order('created_at', ascending: false).range(from, to);
        }
        break;
      case 'escalated':
        response = await _db
            .from('issues_with_creators')
            .select()
            .neq('escalation_tier', 'ward')
            .order('created_at', ascending: false)
            .range(from, to);
        break;
      case 'resolved':
        response = await _db
            .from('issues_with_creators')
            .select()
            .eq('is_resolved', true)
            .order('created_at', ascending: false)
            .range(from, to);
        break;
      case 'trending':
        response = await _db
            .from('issues_with_creators')
            .select()
            .order('upvote_count', ascending: false)
            .range(from, to);
        break;
      default:
        response = await _db
            .from('issues_with_creators')
            .select()
            .order('created_at', ascending: false)
            .range(from, to);
    }

    return response.map((e) => Issue.fromMap(e)).toList();
  }

  Future<Issue?> fetchIssue(String issueId) async {
    final response = await _db
        .from('issues_with_creators')
        .select()
        .eq('id', issueId)
        .maybeSingle();
    if (response == null) return null;
    return Issue.fromMap(response);
  }

  Future<String> createIssue({
    required String userId,
    required String title,
    required String description,
    required String category,
    required double lat,
    required double lng,
    required String addressLabel,
    required String wardId,
    required List<String> mediaUrls,
  }) async {
    final now = DateTime.now().toIso8601String();
    final data = {
      'title': title,
      'description': description,
      'category': category,
      'status': 'open',
      'location_lat': lat,
      'location_lng': lng,
      'address_label': addressLabel,
      'ward_id': wardId,
      'media_urls': mediaUrls,
      'created_by': userId,
      'created_at': now,
      'updated_at': now,
      'upvote_count': 0,
      'downvote_count': 0,
      'comment_count': 0,
      'share_count': 0,
      'view_count': 0,
      'escalation_tier': 'ward',
      'escalation_history': <Map>[],
      'is_resolved': false,
      'priority_flag': false,
    };
    final response =
        await _db.from('issues').insert(data).select('id').single();
    // Increment user issues_filed_count
    await _db.rpc('increment_issues_filed', params: {'user_id': userId});
    return response['id'] as String;
  }

  Future<void> incrementViewCount(String issueId) async {
    await _db.rpc('increment_view_count', params: {'issue_id': issueId});
  }

  // ── Votes ─────────────────────────────────────────────────────────────────

  Future<String?> getUserVote(String issueId, String userId) async {
    final response = await _db
        .from('votes')
        .select('vote_type')
        .eq('issue_id', issueId)
        .eq('user_id', userId)
        .maybeSingle();
    return response?['vote_type'] as String?;
  }

  Future<void> upsertVote({
    required String issueId,
    required String userId,
    required String voteType, // 'up' | 'down'
  }) async {
    await _db.from('votes').upsert({
      'issue_id': issueId,
      'user_id': userId,
      'vote_type': voteType,
      'created_at': DateTime.now().toIso8601String(),
    }, onConflict: 'issue_id,user_id');

    // Recompute counts via DB function
    await _db.rpc('recompute_vote_counts', params: {'p_issue_id': issueId});
  }

  Future<void> removeVote({required String issueId, required String userId}) async {
    await _db
        .from('votes')
        .delete()
        .eq('issue_id', issueId)
        .eq('user_id', userId);
    await _db.rpc('recompute_vote_counts', params: {'p_issue_id': issueId});
  }

  // ── Bookmarks ─────────────────────────────────────────────────────────────

  Future<bool> isBookmarked(String issueId, String userId) async {
    final response = await _db
        .from('bookmarks')
        .select('id')
        .eq('issue_id', issueId)
        .eq('user_id', userId)
        .maybeSingle();
    return response != null;
  }

  Future<void> toggleBookmark(String issueId, String userId) async {
    final exists = await isBookmarked(issueId, userId);
    if (exists) {
      await _db
          .from('bookmarks')
          .delete()
          .eq('issue_id', issueId)
          .eq('user_id', userId);
    } else {
      await _db.from('bookmarks').insert({
        'issue_id': issueId,
        'user_id': userId,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<List<Issue>> fetchBookmarkedIssues(String userId) async {
    final response = await _db
        .from('bookmarks')
        .select('issue_id, issues_with_creators(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (response as List)
        .map((e) => Issue.fromMap(e['issues_with_creators'] as Map<String, dynamic>))
        .toList();
  }

  // ── Comments ──────────────────────────────────────────────────────────────

  Future<List<Comment>> fetchComments(String issueId, {String sort = 'recent'}) async {
    final query = _db
        .from('comments_with_users')
        .select()
        .eq('issue_id', issueId)
        .isFilter('parent_comment_id', null);

    final List raw = sort == 'top'
        ? await query.order('upvote_count', ascending: false)
        : await query.order('created_at', ascending: false);

    final topLevel = raw.map((e) => Comment.fromMap(e)).toList();

    // Fetch replies for each top-level comment
    final List<Comment> withReplies = [];
    for (final comment in topLevel) {
      final repliesRaw = await _db
          .from('comments_with_users')
          .select()
          .eq('issue_id', issueId)
          .eq('parent_comment_id', comment.id)
          .order('created_at', ascending: true);
      final replies =
          (repliesRaw as List).map((e) => Comment.fromMap(e)).toList();
      withReplies.add(comment.copyWith(replies: replies));
    }
    return withReplies;
  }

  Future<Comment> addComment({
    required String issueId,
    required String userId,
    required String text,
    String? parentCommentId,
    String? mediaUrl,
  }) async {
    final now = DateTime.now().toIso8601String();
    final data = {
      'issue_id': issueId,
      'user_id': userId,
      'text': text,
      'parent_comment_id': parentCommentId,
      'media_url': mediaUrl,
      'created_at': now,
      'upvote_count': 0,
    };
    final response =
        await _db.from('comments').insert(data).select('*, users(name, avatar_url)').single();

    // Increment comment_count on issue
    await _db.rpc('increment_comment_count', params: {'issue_id': issueId});
    return Comment.fromMap({
      ...response,
      'user_name': response['users']?['name'] ?? 'Unknown',
      'user_avatar': response['users']?['avatar_url'],
    });
  }

  Future<void> upvoteComment(String commentId) async {
    await _db.rpc('increment_comment_upvote', params: {'comment_id': commentId});
  }

  // ── Authority Actions ─────────────────────────────────────────────────────

  Future<List<AuthorityAction>> fetchAuthorityActions(String issueId, {bool includeInternal = false}) async {
    final base = _db
        .from('authority_actions_with_users')
        .select()
        .eq('issue_id', issueId);

    final response = includeInternal
        ? await base.order('created_at', ascending: true)
        : await base.eq('is_internal', false).order('created_at', ascending: true);

    return (response as List).map((e) => AuthorityAction.fromMap(e)).toList();
  }

  Future<void> addAuthorityAction({
    required String issueId,
    required String authorityId,
    required String actionType,
    String? note,
    String? mediaUrl,
    bool isInternal = false,
  }) async {
    final now = DateTime.now().toIso8601String();
    await _db.from('authority_actions').insert({
      'issue_id': issueId,
      'authority_id': authorityId,
      'action_type': actionType,
      'note': note,
      'media_url': mediaUrl,
      'is_internal': isInternal,
      'created_at': now,
    });

    // Update issue status
    if (!isInternal && actionType != 'comment' && actionType != 'escalated') {
      final statusMap = {
        'acknowledged': 'open',
        'in_progress': 'in_progress',
        'resolved': 'resolved',
        'rejected': 'rejected',
      };
      final newStatus = statusMap[actionType];
      if (newStatus != null) {
        await _db.from('issues').update({
          'status': newStatus,
          'updated_at': now,
          if (newStatus == 'resolved') 'is_resolved': true,
          if (newStatus == 'resolved') 'resolved_at': now,
          if (newStatus == 'resolved') 'resolution_note': note,
        }).eq('id', issueId);
      }
    }
  }

  // ── Authority Issue Queue ─────────────────────────────────────────────────

  Future<List<Issue>> fetchAuthorityQueue({
    required String authorityId,
    required String wardId,
    String tab = 'my_queue',
    int page = 0,
    int pageSize = 20,
  }) async {
    switch (tab) {
      case 'my_queue':
        final response = await _db
            .from('issues_with_creators')
            .select()
            .eq('ward_id', wardId)
            .eq('is_resolved', false)
            .neq('status', 'rejected')
            .order('created_at', ascending: true)
            .range(page * pageSize, (page + 1) * pageSize - 1);
        return (response as List).map((e) => Issue.fromMap(e)).toList();

      case 'escalated_to_me':
        final response = await _db
            .from('issues_with_creators')
            .select()
            .eq('ward_id', wardId)
            .neq('escalation_tier', 'ward')
            .eq('is_resolved', false)
            .order('created_at', ascending: true)
            .range(page * pageSize, (page + 1) * pageSize - 1);
        return (response as List).map((e) => Issue.fromMap(e)).toList();

      case 'resolved':
        final response = await _db
            .from('issues_with_creators')
            .select()
            .eq('ward_id', wardId)
            .eq('is_resolved', true)
            .order('resolved_at', ascending: false)
            .range(page * pageSize, (page + 1) * pageSize - 1);
        return (response as List).map((e) => Issue.fromMap(e)).toList();

      default:
        final response = await _db
            .from('issues_with_creators')
            .select()
            .eq('ward_id', wardId)
            .order('created_at', ascending: false)
            .range(page * pageSize, (page + 1) * pageSize - 1);
        return (response as List).map((e) => Issue.fromMap(e)).toList();
    }
  }

  // ── Stats ─────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> fetchAuthorityStats(String wardId) async {
    final response = await _db
        .rpc('get_ward_stats', params: {'p_ward_id': wardId});
    return response as Map<String, dynamic>;
  }

  // ── User Profile Issues ───────────────────────────────────────────────────

  Future<List<Issue>> fetchUserIssues(String userId) async {
    final response = await _db
        .from('issues_with_creators')
        .select()
        .eq('created_by', userId)
        .order('created_at', ascending: false);
    return (response as List).map((e) => Issue.fromMap(e)).toList();
  }

  // ── Notifications ─────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchNotifications(String userId) async {
    final response = await _db
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> markAllNotificationsRead(String userId) async {
    await _db
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId);
  }

  // ── Mentions autocomplete ─────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    final response = await _db
        .from('users')
        .select('id, name, avatar_url')
        .ilike('name', '%$query%')
        .limit(10);
    return List<Map<String, dynamic>>.from(response);
  }
}
