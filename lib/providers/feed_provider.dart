import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants.dart';
import '../models/post.dart';
import '../repositories/post_repository.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final postRepositoryProvider = Provider<PostRepository>((ref) {
  return PostRepository(ref.read(supabaseClientProvider));
});

final feedProvider = StateNotifierProvider<FeedController, FeedState>((ref) {
  return FeedController(ref.read(postRepositoryProvider));
});

const int _pageSize = 10;

class FeedState {
  const FeedState({
    required this.posts,
    required this.isLoading,
    required this.isRefreshing,
    required this.isLoadingMore,
    required this.hasMore,
    required this.nextOffset,
    this.errorMessage,
  });

  final List<Post> posts;
  final bool isLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool hasMore;
  final int nextOffset;
  final String? errorMessage;

  FeedState copyWith({
    List<Post>? posts,
    bool? isLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? hasMore,
    int? nextOffset,
    String? errorMessage,
  }) {
    return FeedState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      nextOffset: nextOffset ?? this.nextOffset,
      errorMessage: errorMessage,
    );
  }

  factory FeedState.initial() {
    return const FeedState(
      posts: [],
      isLoading: false,
      isRefreshing: false,
      isLoadingMore: false,
      hasMore: true,
      nextOffset: 0,
      errorMessage: null,
    );
  }
}

class FeedController extends StateNotifier<FeedState> {
  FeedController(this._repository) : super(FeedState.initial());

  final PostRepository _repository;

  Future<void> loadInitial() async {
    if (state.isLoading) {
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final posts = await _repository.fetchPosts(
        userId: kUserId,
        from: 0,
        to: _pageSize - 1,
      );
      state = state.copyWith(
        posts: posts,
        isLoading: false,
        hasMore: posts.length == _pageSize,
        nextOffset: posts.length,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load feed. $error',
      );
    }
  }

  Future<void> refresh() async {
    if (state.isRefreshing) {
      return;
    }

    state = state.copyWith(isRefreshing: true, errorMessage: null);

    try {
      final posts = await _repository.fetchPosts(
        userId: kUserId,
        from: 0,
        to: _pageSize - 1,
      );
      state = state.copyWith(
        posts: posts,
        isRefreshing: false,
        hasMore: posts.length == _pageSize,
        nextOffset: posts.length,
      );
    } catch (error) {
      state = state.copyWith(
        isRefreshing: false,
        errorMessage: 'Failed to refresh feed. $error',
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) {
      return;
    }

    state = state.copyWith(isLoadingMore: true, errorMessage: null);

    try {
      final posts = await _repository.fetchPosts(
        userId: kUserId,
        from: state.nextOffset,
        to: state.nextOffset + _pageSize - 1,
      );

      state = state.copyWith(
        posts: [...state.posts, ...posts],
        isLoadingMore: false,
        hasMore: posts.length == _pageSize,
        nextOffset: state.nextOffset + posts.length,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: 'Failed to load more posts. $error',
      );
    }
  }
}
