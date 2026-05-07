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

class FeedState {
  const FeedState({
    required this.posts,
    required this.isLoading,
    required this.hasLoaded,
    this.errorMessage,
  });

  final List<Post> posts;
  final bool isLoading;
  final bool hasLoaded;
  final String? errorMessage;

  FeedState copyWith({
    List<Post>? posts,
    bool? isLoading,
    bool? hasLoaded,
    String? errorMessage,
  }) {
    return FeedState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      hasLoaded: hasLoaded ?? this.hasLoaded,
      errorMessage: errorMessage,
    );
  }

  factory FeedState.initial() {
    return const FeedState(
      posts: [],
      isLoading: false,
      hasLoaded: false,
      errorMessage: null,
    );
  }
}

class FeedController extends StateNotifier<FeedState> {
  FeedController(this._repository) : super(FeedState.initial());

  final PostRepository _repository;

  Future<void> load({bool force = false}) async {
    if (state.isLoading) {
      return;
    }
    if (state.hasLoaded && !force) {
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final posts = await _repository.fetchPosts(userId: kUserId);
      state = state.copyWith(
        posts: posts,
        isLoading: false,
        hasLoaded: true,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load feed. $error',
      );
    }
  }
}
