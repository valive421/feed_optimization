import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/feed_provider.dart';
import '../widgets/post_card.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(feedProvider.notifier).loadInitial();
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (currentScroll >= maxScroll - 200) {
      ref.read(feedProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final postsLength = ref.watch(feedProvider.select((s) => s.posts.length));
    final isLoading = ref.watch(feedProvider.select((s) => s.isLoading));
    final isLoadingMore = ref.watch(feedProvider.select((s) => s.isLoadingMore));
    final errorMessage = ref.watch(feedProvider.select((s) => s.errorMessage));

    if (isLoading && postsLength == 0) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null && postsLength == 0) {
      return Scaffold(
        appBar: AppBar(title: const Text('High Performance Feed')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  errorMessage,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () =>
                      ref.read(feedProvider.notifier).loadInitial(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('High Performance Feed')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(feedProvider.notifier).refresh(),
        child: ListView.builder(
          controller: _scrollController,
          cacheExtent: 600,
          addAutomaticKeepAlives: false,
          itemCount: postsLength + (isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= postsLength) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            // Watch only the specific post and pending flag to avoid rebuilding the whole list.
            final post = ref.watch(feedProvider.select((s) => s.posts[index]));
            final isPending = ref.watch(feedProvider.select((s) => s.pendingLikeIds.contains(post.id)));

            return PostCard(
              post: post,
              onLike: () => ref.read(feedProvider.notifier).toggleLike(post.id),
              isLikePending: isPending,
            );
          },
        ),
      ),
    );
  }
}
