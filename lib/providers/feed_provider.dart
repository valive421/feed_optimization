import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants.dart';
import '../models/post.dart';
import '../repositories/post_repository.dart';
import 'connectivity_provider.dart';
import '../services/offline_queue.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final postRepositoryProvider = Provider<PostRepository>((ref) {
  return PostRepository(ref.read(supabaseClientProvider));
});

final offlineQueueProvider = FutureProvider.autoDispose((ref) async {
  // Lazy-load shared preferences-backed offline queue
  return await OfflineQueue.load();
});

final feedProvider = StateNotifierProvider<FeedController, FeedState>((ref) {
  final controller = FeedController(ref, ref.read(postRepositoryProvider));

  // When connectivity comes back online, trigger queue sync.
  ref.listen<bool>(connectivityProvider, (previous, next) {
    if (next == true) {
      controller.processOfflineQueue();
    }
  });

  return controller;
});

const int _pageSize = 10;
const Duration _likeThrottle = Duration(milliseconds: 350);

class FeedState {
  const FeedState({
    required this.posts,
    required this.isLoading,
    required this.isRefreshing,
    required this.isLoadingMore,
    required this.hasMore,
    required this.nextOffset,
    required this.pendingLikeIds,
    this.errorMessage,
  });

  final List<Post> posts;
  final bool isLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool hasMore;
  final int nextOffset;
  final Set<String> pendingLikeIds;
  final String? errorMessage;

  FeedState copyWith({
    List<Post>? posts,
    bool? isLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? hasMore,
    int? nextOffset,
    Set<String>? pendingLikeIds,
    String? errorMessage,
  }) {
    return FeedState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      nextOffset: nextOffset ?? this.nextOffset,
      pendingLikeIds: pendingLikeIds ?? this.pendingLikeIds,
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
      pendingLikeIds: <String>{},
      errorMessage: null,
    );
  }
}

class FeedController extends StateNotifier<FeedState> {
  FeedController(this._ref, this._repository) : super(FeedState.initial());

  final Ref _ref;
  final PostRepository _repository;
  final Map<String, Post> _likeRollbackCache = {};
  final Map<String, DateTime> _lastLikeTapAt = {};
  final Map<String, bool> _queuedLikeState = {};

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

  Future<void> toggleLike(String postId) async {
    final index = state.posts.indexWhere((post) => post.id == postId);
    if (index == -1) {
      return;
    }

    final current = state.posts[index];
    final desired = !current.isLiked;

    final now = DateTime.now();
    final lastTap = _lastLikeTapAt[postId];
    _lastLikeTapAt[postId] = now;
    if (lastTap != null && now.difference(lastTap) < _likeThrottle) {
      _queuedLikeState[postId] = desired;
      return;
    }

    if (state.pendingLikeIds.contains(postId)) {
      _queuedLikeState[postId] = desired;
      return;
    }

    final online = _ref.read(connectivityProvider);
    if (!online) {
      // Enqueue offline action and optimistically update UI
      final action = OfflineAction(
        type: 'toggle_like',
        postId: postId,
        userId: kUserId,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
      try {
        final queue = await _ref.read(offlineQueueProvider.future);
        await queue.enqueue(action);
      } catch (_) {
        // ignore persistence errors for now
      }

      // Apply optimistic change locally and mark pending
      await _startLikeTransition(postId, desired, shouldCallRpc: false);
      return;
    }

    await _startLikeTransition(postId, desired);
  }

  Future<void> _startLikeTransition(String postId, bool desired, {bool shouldCallRpc = true}) async {
    final index = state.posts.indexWhere((post) => post.id == postId);
    if (index == -1) {
      return;
    }

    final current = state.posts[index];
    if (current.isLiked == desired) {
      return;
    }

    final delta = desired ? 1 : -1;
    final nextCount = (current.likeCount + delta).clamp(0, 1 << 30);
    final optimistic = current.copyWith(
      isLiked: desired,
      likeCount: nextCount,
    );

    _likeRollbackCache[postId] = current;
    final updatedPosts = [...state.posts];
    updatedPosts[index] = optimistic;

    state = state.copyWith(
      posts: updatedPosts,
      pendingLikeIds: {...state.pendingLikeIds, postId},
    );

    try {
      if (shouldCallRpc) {
        await _repository.toggleLike(postId: postId, userId: kUserId);
        _likeRollbackCache.remove(postId);
      }
      state = state.copyWith(
        pendingLikeIds: {...state.pendingLikeIds}..remove(postId),
      );
    } catch (error) {
      final previous = _likeRollbackCache.remove(postId);
      final rollbackPosts = [...state.posts];
      final rollbackIndex = rollbackPosts.indexWhere((post) => post.id == postId);
      if (previous != null && rollbackIndex != -1) {
        rollbackPosts[rollbackIndex] = previous;
      }
      state = state.copyWith(
        posts: rollbackPosts,
        pendingLikeIds: {...state.pendingLikeIds}..remove(postId),
      );
    }

    final queued = _queuedLikeState.remove(postId);
    if (queued != null) {
      await _startLikeTransition(postId, queued);
    }
  }

  Future<void> processOfflineQueue() async {
    try {
      final queue = await _ref.read(offlineQueueProvider.future);
      final actions = await queue.drain();
      for (final action in actions) {
        if (action.type == 'toggle_like') {
          // Attempt to apply server-side; if it fails, ignore to avoid blocking other actions
          try {
            await _repository.toggleLike(postId: action.postId, userId: action.userId);
            // Ensure local UI reflects server state by refreshing that post
            final idx = state.posts.indexWhere((p) => p.id == action.postId);
            if (idx != -1) {
              // naive refresh: re-fetch that post list window later; for now, remove pending flag
              state = state.copyWith(pendingLikeIds: {...state.pendingLikeIds}..remove(action.postId));
            }
          } catch (_) {
            // If RPC fails, we could re-enqueue; skip for simplicity.
          }
        }
      }
    } catch (_) {
      // ignore queue processing errors
    }
  }
}
