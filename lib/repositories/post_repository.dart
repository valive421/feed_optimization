import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/post.dart';

class PostRepository {
  PostRepository(this._client);

  final SupabaseClient _client;

  Future<List<Post>> fetchPosts({
    required String userId,
    required int from,
    required int to,
  }) async {
    final response = await _client
        .from('posts')
        .select()
        .order('created_at', ascending: false)
        .range(from, to);

    final data = response as List<dynamic>;
    final postRows = data.whereType<Map<String, dynamic>>().toList();
    if (postRows.isEmpty) {
      return [];
    }

    final postIds = postRows
        .map((row) => row['id']?.toString())
        .whereType<String>()
        .toList();

    final likedIds = <String>{};
    if (postIds.isNotEmpty) {
      final likesResponse = await _client
          .from('user_likes')
          .select('post_id')
          .eq('user_id', userId)
          .inFilter('post_id', postIds);

      final likeRows = likesResponse as List<dynamic>;
      for (final row in likeRows) {
        if (row is Map<String, dynamic>) {
          final postId = row['post_id']?.toString();
          if (postId != null) {
            likedIds.add(postId);
          }
        }
      }
    }

    return postRows
        .map((row) => Post.fromJson(
              row,
              isLiked: likedIds.contains(row['id']?.toString()),
            ))
        .toList();
  }

  Future<void> toggleLike({
    required String postId,
    required String userId,
  }) async {
    await _client.rpc(
      'toggle_like',
      params: {
        'p_post_id': postId,
        'p_user_id': userId,
      },
    );
  }
}
