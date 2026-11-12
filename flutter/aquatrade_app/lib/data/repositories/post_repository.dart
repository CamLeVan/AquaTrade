import '../models/post_model.dart';
import '../services/remote/api_service.dart';
import '../services/local/local_service.dart';

class PostRepository {
  final ApiService _api;
  final LocalService _local;

  PostRepository(this._api, this._local);

  Future<List<PostModel>> getPosts({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await _local.getCachedPosts();
      if (cached.isNotEmpty) {
        return cached.map(PostModel.fromJson).toList();
      }
    }

    final response = await _api.get('/posts');
    final data = _api.parseData<dynamic>(response);

    if (data is! List) return [];
    final posts = data
        .whereType<Map<String, dynamic>>()
        .map(PostModel.fromJson)
        .toList();

    await _local.savePosts(posts.map((p) => {
      'id': p.id,
      'title': p.title,
      'content': p.content,
      'category': p.category,
      'status': p.status,
      'featuredImageUrl': p.featuredImageUrl,
      'author': p.author,
      'viewCount': p.viewCount,
    }).toList());

    return posts;
  }
}
