import 'package:flutter/foundation.dart';

import '../data/models/post_model.dart';
import '../data/repositories/post_repository.dart';

class PostProvider with ChangeNotifier {
  final PostRepository _repository;

  PostProvider(this._repository);

  List<PostModel> _posts = [];
  bool _isLoading = false;
  String _error = '';

  List<PostModel> get posts => _posts;
  bool get isLoading => _isLoading;
  String get error => _error;

  Future<void> fetchPosts() async {
    _isLoading = true;
    _error = '';
    notifyListeners();
    try {
      _posts = await _repository.getPosts();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
