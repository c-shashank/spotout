import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/db_service.dart';
import '../../../models/issue.dart';

// ── Events ─────────────────────────────────────────────────────────────────

abstract class FeedEvent extends Equatable {
  const FeedEvent();
  @override
  List<Object?> get props => [];
}

class FeedLoad extends FeedEvent {
  final String filter;
  final String? wardId;
  final double? userLat;
  final double? userLng;
  const FeedLoad({
    this.filter = 'all',
    this.wardId,
    this.userLat,
    this.userLng,
  });
  @override
  List<Object?> get props => [filter, wardId];
}

class FeedLoadMore extends FeedEvent {}

class FeedFilterChanged extends FeedEvent {
  final String filter;
  const FeedFilterChanged(this.filter);
  @override
  List<Object?> get props => [filter];
}

class FeedRefresh extends FeedEvent {
  final String filter;
  final String? wardId;
  final double? userLat;
  final double? userLng;
  const FeedRefresh({this.filter = 'all', this.wardId, this.userLat, this.userLng});
}

class FeedIssueVote extends FeedEvent {
  final String issueId;
  final String voteType; // 'up'|'down'|'remove'
  const FeedIssueVote(this.issueId, this.voteType);
  @override
  List<Object?> get props => [issueId, voteType];
}

class FeedIssueBookmark extends FeedEvent {
  final String issueId;
  const FeedIssueBookmark(this.issueId);
  @override
  List<Object?> get props => [issueId];
}

class FeedIssueViewed extends FeedEvent {
  final String issueId;
  const FeedIssueViewed(this.issueId);
}

// ── States ──────────────────────────────────────────────────────────────────

abstract class FeedState extends Equatable {
  const FeedState();
  @override
  List<Object?> get props => [];
}

class FeedInitial extends FeedState {}

class FeedLoading extends FeedState {}

class FeedLoaded extends FeedState {
  final List<Issue> issues;
  final String filter;
  final bool hasMore;
  final int page;

  const FeedLoaded({
    required this.issues,
    required this.filter,
    this.hasMore = true,
    this.page = 0,
  });

  FeedLoaded copyWith({
    List<Issue>? issues,
    String? filter,
    bool? hasMore,
    int? page,
  }) {
    return FeedLoaded(
      issues: issues ?? this.issues,
      filter: filter ?? this.filter,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
    );
  }

  @override
  List<Object?> get props => [issues, filter, hasMore, page];
}

class FeedLoadingMore extends FeedLoaded {
  const FeedLoadingMore({
    required super.issues,
    required super.filter,
    super.hasMore,
    super.page,
  });
}

class FeedError extends FeedState {
  final String message;
  const FeedError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── Bloc ─────────────────────────────────────────────────────────────────────

class FeedBloc extends Bloc<FeedEvent, FeedState> {
  final DbService _db;
  final String? userId;

  static const _pageSize = 20;

  FeedBloc(this._db, {this.userId}) : super(FeedInitial()) {
    on<FeedLoad>(_onLoad);
    on<FeedRefresh>(_onRefresh);
    on<FeedLoadMore>(_onLoadMore);
    on<FeedIssueVote>(_onVote);
    on<FeedIssueBookmark>(_onBookmark);
    on<FeedIssueViewed>(_onViewed);
  }

  Future<void> _onLoad(FeedLoad event, Emitter<FeedState> emit) async {
    emit(FeedLoading());
    try {
      final issues = await _db.fetchFeed(
        filter: event.filter,
        wardId: event.wardId,
        userLat: event.userLat,
        userLng: event.userLng,
        page: 0,
        pageSize: _pageSize,
      );
      emit(FeedLoaded(
        issues: issues,
        filter: event.filter,
        hasMore: issues.length >= _pageSize,
        page: 0,
      ));
    } catch (e) {
      emit(FeedError(e.toString()));
    }
  }

  Future<void> _onRefresh(FeedRefresh event, Emitter<FeedState> emit) async {
    final current = state;
    try {
      final issues = await _db.fetchFeed(
        filter: event.filter,
        wardId: event.wardId,
        userLat: event.userLat,
        userLng: event.userLng,
        page: 0,
        pageSize: _pageSize,
      );
      emit(FeedLoaded(
        issues: issues,
        filter: event.filter,
        hasMore: issues.length >= _pageSize,
        page: 0,
      ));
    } catch (e) {
      if (current is FeedLoaded) {
        emit(current);
      } else {
        emit(FeedError(e.toString()));
      }
    }
  }

  Future<void> _onLoadMore(FeedLoadMore event, Emitter<FeedState> emit) async {
    final current = state;
    if (current is! FeedLoaded || !current.hasMore) return;

    emit(FeedLoadingMore(
      issues: current.issues,
      filter: current.filter,
      hasMore: current.hasMore,
      page: current.page,
    ));
    try {
      final nextPage = current.page + 1;
      final more = await _db.fetchFeed(
        filter: current.filter,
        page: nextPage,
        pageSize: _pageSize,
      );
      emit(current.copyWith(
        issues: [...current.issues, ...more],
        hasMore: more.length >= _pageSize,
        page: nextPage,
      ));
    } catch (_) {
      emit(current);
    }
  }

  Future<void> _onVote(FeedIssueVote event, Emitter<FeedState> emit) async {
    final current = state;
    if (current is! FeedLoaded) return;

    final idx = current.issues.indexWhere((i) => i.id == event.issueId);
    if (idx == -1) return;

    final issue = current.issues[idx];
    // Optimistic update
    Issue updated;
    if (event.voteType == 'up') {
      updated = issue.copyWith(
        upvoteCount: issue.userHasUpvoted == true
            ? issue.upvoteCount - 1
            : issue.upvoteCount + 1,
        downvoteCount: issue.userHasDownvoted == true
            ? issue.downvoteCount - 1
            : issue.downvoteCount,
        userHasUpvoted: issue.userHasUpvoted != true,
        userHasDownvoted: false,
      );
    } else {
      updated = issue.copyWith(
        downvoteCount: issue.userHasDownvoted == true
            ? issue.downvoteCount - 1
            : issue.downvoteCount + 1,
        upvoteCount: issue.userHasUpvoted == true
            ? issue.upvoteCount - 1
            : issue.upvoteCount,
        userHasDownvoted: issue.userHasDownvoted != true,
        userHasUpvoted: false,
      );
    }
    final newList = [...current.issues];
    newList[idx] = updated;
    emit(current.copyWith(issues: newList));

    try {
      if (event.voteType == 'up') {
        if (issue.userHasUpvoted == true) {
          await _db.removeVote(issueId: event.issueId, userId: userId!);
        } else {
          await _db.upsertVote(issueId: event.issueId, userId: userId!, voteType: 'up');
        }
      } else {
        if (issue.userHasDownvoted == true) {
          await _db.removeVote(issueId: event.issueId, userId: userId!);
        } else {
          await _db.upsertVote(issueId: event.issueId, userId: userId!, voteType: 'down');
        }
      }
    } catch (_) {
      // Revert on error
      final revert = [...current.issues];
      revert[idx] = issue;
      emit(current.copyWith(issues: revert));
    }
  }

  Future<void> _onBookmark(FeedIssueBookmark event, Emitter<FeedState> emit) async {
    final current = state;
    if (current is! FeedLoaded || userId == null) return;

    final idx = current.issues.indexWhere((i) => i.id == event.issueId);
    if (idx == -1) return;

    final issue = current.issues[idx];
    final updated = issue.copyWith(userHasBookmarked: !(issue.userHasBookmarked ?? false));
    final newList = [...current.issues];
    newList[idx] = updated;
    emit(current.copyWith(issues: newList));

    try {
      await _db.toggleBookmark(event.issueId, userId!);
    } catch (_) {
      final revert = [...current.issues];
      revert[idx] = issue;
      emit(current.copyWith(issues: revert));
    }
  }

  Future<void> _onViewed(FeedIssueViewed event, Emitter<FeedState> emit) async {
    try {
      await _db.incrementViewCount(event.issueId);
    } catch (_) {}
  }
}
