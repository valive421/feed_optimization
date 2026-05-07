import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/post.dart';

class PostRepository {
  PostRepository(this._client);

  final SupabaseClient _client;

  Future<List<Post>> fetchPosts({
    required String userId,
    int limit = 20,
  }) async {
    final response = await _client
        .from('posts')
        .select()
        .order('created_at', ascending: false)
        .limit(limit);

    final data = response as List<dynamic>;
    return data
        .whereType<Map<String, dynamic>>()
        .map(Post.fromJson)
        .toList();
  }
}
