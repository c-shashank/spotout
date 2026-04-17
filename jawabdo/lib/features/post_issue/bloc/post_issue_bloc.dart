import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/db_service.dart';
import '../../../core/services/storage_service.dart';

// ── State (simple data holder) ────────────────────────────────────────────────

class PostIssueData extends Equatable {
  final List<File> photos;
  final double? lat;
  final double? lng;
  final String? addressLabel;
  final String? wardId;
  final String? category;
  final String title;
  final String description;
  final int step; // 1-5

  const PostIssueData({
    this.photos = const [],
    this.lat,
    this.lng,
    this.addressLabel,
    this.wardId,
    this.category,
    this.title = '',
    this.description = '',
    this.step = 1,
  });

  PostIssueData copyWith({
    List<File>? photos,
    double? lat,
    double? lng,
    String? addressLabel,
    String? wardId,
    String? category,
    String? title,
    String? description,
    int? step,
  }) {
    return PostIssueData(
      photos: photos ?? this.photos,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      addressLabel: addressLabel ?? this.addressLabel,
      wardId: wardId ?? this.wardId,
      category: category ?? this.category,
      title: title ?? this.title,
      description: description ?? this.description,
      step: step ?? this.step,
    );
  }

  @override
  List<Object?> get props => [photos.length, lat, lng, wardId, category, title, step];
}

// ── Events ─────────────────────────────────────────────────────────────────

abstract class PostIssueEvent extends Equatable {
  const PostIssueEvent();
  @override
  List<Object?> get props => [];
}

class PostIssueUpdatePhotos extends PostIssueEvent {
  final List<File> photos;
  const PostIssueUpdatePhotos(this.photos);
}

class PostIssueUpdateLocation extends PostIssueEvent {
  final double lat;
  final double lng;
  final String addressLabel;
  final String? wardId;
  const PostIssueUpdateLocation(this.lat, this.lng, this.addressLabel, this.wardId);
}

class PostIssueUpdateDetails extends PostIssueEvent {
  final String category;
  final String title;
  final String description;
  const PostIssueUpdateDetails(this.category, this.title, this.description);
}

class PostIssueUpdateWard extends PostIssueEvent {
  final String wardId;
  const PostIssueUpdateWard(this.wardId);
}

class PostIssueGoToStep extends PostIssueEvent {
  final int step;
  const PostIssueGoToStep(this.step);
}

class PostIssueSubmit extends PostIssueEvent {
  const PostIssueSubmit();
}

// ── States ─────────────────────────────────────────────────────────────────

abstract class PostIssueState extends Equatable {
  const PostIssueState();
  @override
  List<Object?> get props => [];
}

class PostIssueEditing extends PostIssueState {
  final PostIssueData data;
  const PostIssueEditing(this.data);
  @override
  List<Object?> get props => [data];
}

class PostIssueSubmitting extends PostIssueState {}

class PostIssueSuccess extends PostIssueState {
  final String issueId;
  const PostIssueSuccess(this.issueId);
  @override
  List<Object?> get props => [issueId];
}

class PostIssueError extends PostIssueState {
  final String message;
  const PostIssueError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── Bloc ─────────────────────────────────────────────────────────────────────

class PostIssueBloc extends Bloc<PostIssueEvent, PostIssueState> {
  final DbService _db;
  final StorageService _storage;
  final String userId;

  PostIssueBloc(this._db, this._storage, {required this.userId})
      : super(const PostIssueEditing(PostIssueData())) {
    on<PostIssueUpdatePhotos>(_onUpdatePhotos);
    on<PostIssueUpdateLocation>(_onUpdateLocation);
    on<PostIssueUpdateDetails>(_onUpdateDetails);
    on<PostIssueUpdateWard>(_onUpdateWard);
    on<PostIssueGoToStep>(_onGoToStep);
    on<PostIssueSubmit>(_onSubmit);
  }

  void _onUpdatePhotos(PostIssueUpdatePhotos event, Emitter<PostIssueState> emit) {
    final data = _currentData;
    emit(PostIssueEditing(data.copyWith(photos: event.photos, step: 2)));
  }

  void _onUpdateLocation(PostIssueUpdateLocation event, Emitter<PostIssueState> emit) {
    final data = _currentData;
    emit(PostIssueEditing(data.copyWith(
      lat: event.lat,
      lng: event.lng,
      addressLabel: event.addressLabel,
      wardId: event.wardId,
      step: 3,
    )));
  }

  void _onUpdateDetails(PostIssueUpdateDetails event, Emitter<PostIssueState> emit) {
    final data = _currentData;
    emit(PostIssueEditing(data.copyWith(
      category: event.category,
      title: event.title,
      description: event.description,
      step: 4,
    )));
  }

  void _onUpdateWard(PostIssueUpdateWard event, Emitter<PostIssueState> emit) {
    final data = _currentData;
    emit(PostIssueEditing(data.copyWith(wardId: event.wardId, step: 5)));
  }

  void _onGoToStep(PostIssueGoToStep event, Emitter<PostIssueState> emit) {
    final data = _currentData;
    emit(PostIssueEditing(data.copyWith(step: event.step)));
  }

  Future<void> _onSubmit(PostIssueSubmit event, Emitter<PostIssueState> emit) async {
    final data = _currentData;
    emit(PostIssueSubmitting());
    try {
      // Upload media
      final mediaUrls = <String>[];
      for (final file in data.photos) {
        final url = await _storage.uploadIssueMedia(file, userId);
        mediaUrls.add(url);
      }
      // Create issue
      final issueId = await _db.createIssue(
        userId: userId,
        title: data.title,
        description: data.description,
        category: data.category!,
        lat: data.lat!,
        lng: data.lng!,
        addressLabel: data.addressLabel ?? '',
        wardId: data.wardId!,
        mediaUrls: mediaUrls,
      );
      emit(PostIssueSuccess(issueId));
    } catch (e) {
      emit(PostIssueError(e.toString()));
    }
  }

  PostIssueData get _currentData {
    final s = state;
    return s is PostIssueEditing ? s.data : const PostIssueData();
  }
}
